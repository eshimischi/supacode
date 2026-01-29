import SwiftUI

struct PullRequestStatusButton: View {
  let model: PullRequestStatusModel
  @Environment(\.openURL) private var openURL

  var body: some View {
    HStack(spacing: 6) {
      if !model.statusChecks.isEmpty {
        PullRequestChecksPopoverButton(checks: model.statusChecks)
      }
      Button {
        if let url = model.url {
          openURL(url)
        }
      } label: {
        HStack(spacing: 6) {
          PullRequestBadgeView(
            text: model.badgeText,
            color: model.badgeColor
          )
          if let detailText = model.detailText {
            Text(detailText)
          }
        }
      }
      .buttonStyle(.plain)
      .help(model.helpText)
    }
    .font(.caption)
    .monospaced()
  }

}

struct PullRequestStatusModel: Equatable {
  let number: Int
  let state: String?
  let url: URL?
  let statusChecks: [GithubPullRequestStatusCheck]
  let detailText: String?

  init?(snapshot: WorktreeInfoSnapshot?) {
    guard
      let snapshot,
      let number = snapshot.pullRequestNumber,
      Self.shouldDisplay(state: snapshot.pullRequestState, number: number)
    else {
      return nil
    }
    self.number = number
    let state = snapshot.pullRequestState?.uppercased()
    self.state = state
    self.url = snapshot.pullRequestURL.flatMap(URL.init(string:))
    if state == "MERGED" {
      self.detailText = "Merged"
      self.statusChecks = []
      return
    }
    let isDraft = snapshot.pullRequestIsDraft
    let prefix = "\(isDraft ? "(Drafted) " : "")↗ - "
    let checks = snapshot.pullRequestStatusChecks
    self.statusChecks = checks
    if checks.isEmpty {
      self.detailText = prefix + "Checks unavailable"
      return
    }
    let breakdown = PullRequestCheckBreakdown(checks: checks)
    let checksLabel = breakdown.total == 1 ? "check" : "checks"
    self.detailText = prefix + breakdown.summaryText + " \(checksLabel)"
  }

  var badgeText: String {
    PullRequestBadgeStyle.style(state: state, number: number)?.text ?? "#\(number)"
  }

  var badgeColor: Color {
    PullRequestBadgeStyle.style(state: state, number: number)?.color ?? .secondary
  }

  var helpText: String {
    "Open pull request on GitHub"
  }

  static func shouldDisplay(state: String?, number: Int?) -> Bool {
    guard number != nil else {
      return false
    }
    return state?.uppercased() != "CLOSED"
  }
}
