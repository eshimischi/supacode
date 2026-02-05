import SwiftUI

struct PullRequestChecksPopoverButton<Label: View>: View {
  let checks: [GithubPullRequestStatusCheck]
  let pullRequestURL: URL?
  let pullRequestTitle: String?
  @ViewBuilder let label: () -> Label
  @State private var isPresented = false
  @State private var isHoveringButton = false
  @State private var isHoveringPopover = false
  @State private var closeTask: Task<Void, Never>?
  @Environment(\.openURL) private var openURL

  var body: some View {
    Button {
      if let pullRequestURL {
        openURL(pullRequestURL)
      }
    } label: {
      label()
    }
    .buttonStyle(.plain)
    .contentShape(.rect)
    .help("Open pull request on GitHub (\(AppShortcuts.openPullRequest.display)). Hover to show checks.")
    .accessibilityLabel("Open pull request on GitHub")
    .onHover { hovering in
      isHoveringButton = hovering
      updatePresentation()
    }
    .popover(isPresented: $isPresented) {
      PullRequestChecksPopoverView(
        checks: checks,
        pullRequestURL: pullRequestURL,
        pullRequestTitle: pullRequestTitle
      )
      .onHover { hovering in
        isHoveringPopover = hovering
        updatePresentation()
      }
      .onDisappear {
        isHoveringPopover = false
        updatePresentation()
      }
    }
    .onDisappear {
      closeTask?.cancel()
    }
  }

  private func updatePresentation() {
    if isHoveringButton || isHoveringPopover {
      closeTask?.cancel()
      isPresented = true
      return
    }
    closeTask?.cancel()
    closeTask = Task { @MainActor in
      try? await Task.sleep(for: .milliseconds(150))
      if !Task.isCancelled {
        isPresented = false
      }
    }
  }
}
