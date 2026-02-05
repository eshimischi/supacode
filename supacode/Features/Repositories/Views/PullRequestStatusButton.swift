import SwiftUI

struct PullRequestStatusModel: Equatable {
  let number: Int
  let state: String?
  let url: URL?
  let title: String
  let statusChecks: [GithubPullRequestStatusCheck]
  let detailText: String?
  let popoverStatusText: String?

  init?(pullRequest: GithubPullRequest?) {
    guard
      let pullRequest,
      Self.shouldDisplay(state: pullRequest.state, number: pullRequest.number)
    else {
      return nil
    }
    self.number = pullRequest.number
    let state = pullRequest.state.uppercased()
    self.state = state
    self.url = URL(string: pullRequest.url)
    self.title = pullRequest.title
    if state == "MERGED" {
      self.detailText = nil
      self.statusChecks = []
      self.popoverStatusText = nil
      return
    }
    let isDraft = pullRequest.isDraft
    let prefix = isDraft ? "(Drafted) " : ""
    let mergeable = pullRequest.mergeable
    let mergeStateStatus = pullRequest.mergeStateStatus
    let hasConflicts = Self.hasConflicts(mergeable: mergeable, mergeStateStatus: mergeStateStatus)
    self.popoverStatusText = Self.popoverStatusText(
      reviewDecision: pullRequest.reviewDecision,
      mergeable: mergeable,
      mergeStateStatus: mergeStateStatus
    )
    let checks = pullRequest.statusCheckRollup?.checks ?? []
    self.statusChecks = checks
    let checksDetail: String?
    if checks.isEmpty {
      checksDetail = nil
    } else {
      let breakdown = PullRequestCheckBreakdown(checks: checks)
      let checksLabel = breakdown.total == 1 ? "check" : "checks"
      checksDetail = breakdown.summaryText + " \(checksLabel)"
    }
    if hasConflicts {
      if let checksDetail {
        self.detailText = prefix + "Merge conflicts - " + checksDetail
      } else {
        self.detailText = prefix + "Merge conflicts"
      }
    } else if let checksDetail {
      self.detailText = prefix + checksDetail
    } else {
      self.detailText = isDraft ? "(Drafted)" : nil
    }
  }

  var badgeText: String {
    PullRequestBadgeStyle.style(state: state, number: number)?.text ?? "#\(number)"
  }

  var badgeColor: Color {
    PullRequestBadgeStyle.style(state: state, number: number)?.color ?? .secondary
  }

  static func shouldDisplay(state: String?, number: Int?) -> Bool {
    guard number != nil else {
      return false
    }
    return state?.uppercased() != "CLOSED"
  }

  static func hasConflicts(mergeable: String?, mergeStateStatus: String?) -> Bool {
    let mergeable = mergeable?.uppercased()
    let mergeStateStatus = mergeStateStatus?.uppercased()
    return mergeable == "CONFLICTING" || mergeStateStatus == "DIRTY"
  }

  static func popoverStatusText(
    reviewDecision: String?,
    mergeable: String?,
    mergeStateStatus: String?
  ) -> String? {
    var statusParts: [String] = []
    if let reviewDecision = reviewDecision?.uppercased() {
      switch reviewDecision {
      case "APPROVED":
        statusParts.append("Review approved")
      case "REVIEW_REQUIRED":
        statusParts.append("Review required")
      case "CHANGES_REQUESTED":
        statusParts.append("Changes requested")
      default:
        break
      }
    }
    let mergeableUpper = mergeable?.uppercased()
    let mergeStateUpper = mergeStateStatus?.uppercased()
    if hasConflicts(mergeable: mergeable, mergeStateStatus: mergeStateStatus) {
      statusParts.append("Merge conflicts")
    } else if mergeableUpper == "MERGEABLE" || mergeStateUpper == "CLEAN" {
      statusParts.append("No conflicts")
    }
    return statusParts.isEmpty ? nil : statusParts.joined(separator: " • ")
  }
}
