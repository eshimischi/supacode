import CustomDump
import Testing

@testable import supacode

@MainActor
struct AppShortcutsTests {
  @Test func displaySymbolsMatchDisplay() {
    let shortcuts: [AppShortcut] = [
      AppShortcuts.openSettings,
      AppShortcuts.newWorktree,
      AppShortcuts.copyPath,
    ]

    for shortcut in shortcuts {
      expectNoDifference(shortcut.displaySymbols.joined(), shortcut.display)
    }
  }
}
