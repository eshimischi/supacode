import ComposableArchitecture
import CustomDump
import Testing

@testable import supacode

@MainActor
struct CommandPaletteFeatureTests {
  @Test func showsGlobalItemsWhenQueryEmpty() {
    let openSettings = CommandPaletteItem(
      id: "global.open-settings",
      title: "Open Settings",
      subtitle: nil,
      kind: .openSettings
    )
    let newWorktree = CommandPaletteItem(
      id: "global.new-worktree",
      title: "New Worktree",
      subtitle: nil,
      kind: .newWorktree
    )
    let selectFox = CommandPaletteItem(
      id: "worktree.fox.select",
      title: "Repo / fox",
      subtitle: "main",
      kind: .worktreeSelect("wt-fox")
    )
    var state = CommandPaletteFeature.State()
    state.items = [openSettings, newWorktree, selectFox]

    expectNoDifference(state.filteredItems, [openSettings, newWorktree])
  }

  @Test func queryFiltersItemsAndSelectsFirst() async {
    let openSettings = CommandPaletteItem(
      id: "global.open-settings",
      title: "Open Settings",
      subtitle: nil,
      kind: .openSettings
    )
    let selectFox = CommandPaletteItem(
      id: "worktree.fox.select",
      title: "Repo / fox",
      subtitle: "main",
      kind: .worktreeSelect("wt-fox")
    )
    let runFox = CommandPaletteItem(
      id: "worktree.fox.run",
      title: "Repo / fox",
      subtitle: "Run - main",
      kind: .runWorktree("wt-fox")
    )
    let editorFox = CommandPaletteItem(
      id: "worktree.fox.editor",
      title: "Repo / fox",
      subtitle: "Open in Editor - main",
      kind: .openWorktreeInEditor("wt-fox")
    )
    let removeFox = CommandPaletteItem(
      id: "worktree.fox.remove",
      title: "Repo / fox",
      subtitle: "Remove Worktree - main",
      kind: .removeWorktree("wt-fox", "repo-fox")
    )
    var state = CommandPaletteFeature.State()
    state.items = [openSettings, selectFox, runFox, editorFox, removeFox]
    let store = TestStore(initialState: state) {
      CommandPaletteFeature()
    }

    await store.send(.binding(.set(\.query, "fox"))) {
      $0.query = "fox"
      $0.selectedIndex = 0
    }

    expectNoDifference(
      store.state.filteredItems.map(\.id),
      [selectFox.id, runFox.id]
    )
  }

  @Test func queryMatchesGlobalItemsBeforeWorktrees() {
    let openSettings = CommandPaletteItem(
      id: "global.open-settings",
      title: "Open Settings",
      subtitle: nil,
      kind: .openSettings
    )
    let selectSettings = CommandPaletteItem(
      id: "worktree.settings.select",
      title: "Repo / settings",
      subtitle: "main",
      kind: .worktreeSelect("wt-settings")
    )
    var state = CommandPaletteFeature.State()
    state.items = [selectSettings, openSettings]

    expectNoDifference(
      CommandPaletteFeature.filterItems(items: state.items, query: "set"),
      [openSettings, selectSettings]
    )
  }

  @Test func moveSelectionWraps() async {
    let selectFox = CommandPaletteItem(
      id: "worktree.fox.select",
      title: "Repo / fox",
      subtitle: "main",
      kind: .worktreeSelect("wt-fox")
    )
    let runFox = CommandPaletteItem(
      id: "worktree.fox.run",
      title: "Repo / fox",
      subtitle: "Run - main",
      kind: .runWorktree("wt-fox")
    )
    var state = CommandPaletteFeature.State()
    state.items = [selectFox, runFox]
    state.query = "fox"
    state.selectedIndex = 0
    let store = TestStore(initialState: state) {
      CommandPaletteFeature()
    }

    await store.send(.moveSelection(.down)) {
      $0.selectedIndex = 1
    }
    await store.send(.moveSelection(.down)) {
      $0.selectedIndex = 0
    }
    await store.send(.moveSelection(.up)) {
      $0.selectedIndex = 1
    }
  }

  @Test func submitSelectedDispatchesDelegate() async {
    let selectFox = CommandPaletteItem(
      id: "worktree.fox.select",
      title: "Repo / fox",
      subtitle: "main",
      kind: .worktreeSelect("wt-fox")
    )
    let selectBear = CommandPaletteItem(
      id: "worktree.bear.select",
      title: "Repo / bear",
      subtitle: "dev",
      kind: .worktreeSelect("wt-bear")
    )
    let runBear = CommandPaletteItem(
      id: "worktree.bear.run",
      title: "Repo / bear",
      subtitle: "Run - dev",
      kind: .runWorktree("wt-bear")
    )
    var state = CommandPaletteFeature.State()
    state.isPresented = true
    state.items = [selectFox, selectBear, runBear]
    state.query = "bear"
    state.selectedIndex = 1
    let store = TestStore(initialState: state) {
      CommandPaletteFeature()
    }

    await store.send(.submitSelected) {
      $0.isPresented = false
      $0.query = ""
      $0.selectedIndex = nil
    }
    await store.receive(.delegate(.runWorktree("wt-bear")))
  }
}
