import SwiftUI

struct TerminalTabsOverflowShadow: View {
  var width: CGFloat
  var startPoint: UnitPoint
  var endPoint: UnitPoint

  @Environment(\.controlActiveState)
  private var activeState

  var body: some View {
    Rectangle()
      .frame(maxHeight: .infinity)
      .frame(width: width)
      .foregroundStyle(.clear)
      .background(
        LinearGradient(
          gradient: Gradient(colors: gradientColors),
          startPoint: startPoint,
          endPoint: endPoint
        )
        .opacity(activeState == .inactive ? 0.95 : 1)
      )
      .allowsHitTesting(false)
  }

  private var gradientColors: [Color] {
    [
      TerminalTabBarColors.barBackground,
      TerminalTabBarColors.barBackground.opacity(0),
    ]
  }
}
