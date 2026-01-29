import SwiftUI

struct PullRequestChecksPopoverButton<Label: View>: View {
  let checks: [GithubPullRequestStatusCheck]
  let pullRequestURL: URL?
  @ViewBuilder let label: () -> Label
  @State private var isPresented = false

  var body: some View {
    Button {
      isPresented.toggle()
    } label: {
      label()
    }
    .buttonStyle(.plain)
    .contentShape(.rect)
    .help("Show pull request checks")
    .accessibilityLabel("Show pull request checks")
    .popover(isPresented: $isPresented) {
      PullRequestChecksPopoverView(checks: checks, pullRequestURL: pullRequestURL)
    }
  }
}
