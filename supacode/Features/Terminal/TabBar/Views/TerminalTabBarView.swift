import SwiftUI

struct TerminalTabBarView: View {
  @Bindable var manager: TerminalTabManager
  let createTab: () -> Void
  let closeTab: (TerminalTabID) -> Void
  let closeOthers: (TerminalTabID) -> Void
  let closeToRight: (TerminalTabID) -> Void
  let closeAll: () -> Void
  @Environment(\.controlActiveState)
  private var activeState

  var body: some View {
    HStack(spacing: 0) {
      TerminalTabsView(
        manager: manager,
        closeTab: closeTab,
        closeOthers: closeOthers,
        closeToRight: closeToRight,
        closeAll: closeAll
      )
      Spacer(minLength: 0)
      TerminalTabBarTrailingAccessories(createTab: createTab)
    }
    .frame(height: TerminalTabBarMetrics.barHeight)
    .background(TerminalTabBarBackground())
    .saturation(activeState == .inactive ? 0 : 1)
    .clipped()
  }
}
