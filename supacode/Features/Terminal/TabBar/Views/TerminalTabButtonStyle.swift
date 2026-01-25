import SwiftUI

struct TerminalTabButtonStyle: ButtonStyle {
  @Binding private var isPressing: Bool

  init(isPressing: Binding<Bool>) {
    self._isPressing = isPressing
  }

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .onChange(of: configuration.isPressed) { _, isPressed in
        isPressing = isPressed
      }
  }
}
