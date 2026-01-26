import SwiftUI

struct TerminalTabBarTrailingAccessories: View {
  let createTab: () -> Void

  @Environment(GhosttyShortcutManager.self)
  private var ghosttyShortcuts

  var body: some View {
    Button("New Terminal", systemImage: "plus") {
      createTab()
    }
    .labelStyle(.iconOnly)
    .buttonStyle(.borderless)
    .help(helpText("New Terminal", shortcut: ghosttyShortcuts.display(for: "new_tab")))
    .frame(height: TerminalTabBarMetrics.barHeight)
    .padding(.trailing, 8)
  }

  private func helpText(_ title: String, shortcut: String?) -> String {
    guard let shortcut else { return title }
    return "\(title) (\(shortcut))"
  }
}
