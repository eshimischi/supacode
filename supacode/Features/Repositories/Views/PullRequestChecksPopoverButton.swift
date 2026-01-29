import SwiftUI

struct PullRequestChecksPopoverButton: View {
  let checks: [GithubPullRequestStatusCheck]
  @State private var isPresented = false

  var body: some View {
    if checks.isEmpty {
      EmptyView()
    } else {
      let breakdown = PullRequestCheckBreakdown(checks: checks)
      Button {
        isPresented.toggle()
      } label: {
        PullRequestChecksRingView(breakdown: breakdown)
          .padding(4)
      }
      .buttonStyle(.plain)
      .contentShape(.rect)
      .help("Show pull request checks")
      .accessibilityLabel("Show pull request checks")
      .popover(isPresented: $isPresented) {
        PullRequestChecksPopoverView(checks: checks)
      }
    }
  }
}
