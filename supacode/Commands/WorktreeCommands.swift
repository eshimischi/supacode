import ComposableArchitecture
import SwiftUI

struct WorktreeCommands: Commands {
  let store: StoreOf<RepositoriesFeature>
  @ObservedObject private var viewStore: ViewStore<RepositoriesFeature.State, RepositoriesFeature.Action>
  @FocusedValue(\.openSelectedWorktreeAction) private var openSelectedWorktreeAction
  @FocusedValue(\.removeWorktreeAction) private var removeWorktreeAction

  init(store: StoreOf<RepositoriesFeature>) {
    self.store = store
    viewStore = ViewStore(store, observe: { $0 })
  }

  var body: some Commands {
    CommandGroup(replacing: .newItem) {
      Button("Open Repository...", systemImage: "folder") {
        store.send(.setOpenPanelPresented(true))
      }
      .keyboardShortcut(
        AppShortcuts.openRepository.keyEquivalent,
        modifiers: AppShortcuts.openRepository.modifiers
      )
      .help("Open Repository (\(AppShortcuts.openRepository.display))")
      Button("Open Worktree") {
        openSelectedWorktreeAction?()
      }
      .keyboardShortcut(
        AppShortcuts.openFinder.keyEquivalent,
        modifiers: AppShortcuts.openFinder.modifiers
      )
      .help("Open Worktree (\(AppShortcuts.openFinder.display))")
      .disabled(openSelectedWorktreeAction == nil)
      Button("New Worktree", systemImage: "plus") {
        store.send(.createRandomWorktree)
      }
      .keyboardShortcut(
        AppShortcuts.newWorktree.keyEquivalent, modifiers: AppShortcuts.newWorktree.modifiers
      )
      .help("New Worktree (\(AppShortcuts.newWorktree.display))")
      .disabled(!viewStore.canCreateWorktree)
      Button("Remove Worktree") {
        removeWorktreeAction?()
      }
      .keyboardShortcut(.delete, modifiers: .command)
      .help("Remove Worktree (⌘⌫)")
      .disabled(removeWorktreeAction == nil)
      Button("Refresh Worktrees") {
        store.send(.refreshWorktrees)
      }
      .keyboardShortcut(
        AppShortcuts.refreshWorktrees.keyEquivalent,
        modifiers: AppShortcuts.refreshWorktrees.modifiers
      )
      .help("Refresh Worktrees (\(AppShortcuts.refreshWorktrees.display))")
    }
  }
}

private struct RemoveWorktreeActionKey: FocusedValueKey {
  typealias Value = () -> Void
}

private struct OpenSelectedWorktreeActionKey: FocusedValueKey {
  typealias Value = () -> Void
}

extension FocusedValues {
  var openSelectedWorktreeAction: (() -> Void)? {
    get { self[OpenSelectedWorktreeActionKey.self] }
    set { self[OpenSelectedWorktreeActionKey.self] = newValue }
  }

  var removeWorktreeAction: (() -> Void)? {
    get { self[RemoveWorktreeActionKey.self] }
    set { self[RemoveWorktreeActionKey.self] = newValue }
  }
}
