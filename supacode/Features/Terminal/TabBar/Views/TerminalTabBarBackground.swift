import SwiftUI

struct TerminalTabBarBackground: View {
  @Environment(\.controlActiveState)
  private var activeState

  var body: some View {
    Rectangle()
      .fill(
        activeState == .inactive
          ? TerminalTabBarColors.barBackground.opacity(0.95)
          : TerminalTabBarColors.barBackground
      )
  }
}
