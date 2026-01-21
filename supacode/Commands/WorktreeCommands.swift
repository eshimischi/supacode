import Observation
import SwiftUI

struct WorktreeCommands: Commands {
    let repositoryStore: RepositoryStore

    var body: some Commands {
        @Bindable var repositoryStore = repositoryStore
        CommandGroup(replacing: .newItem) {
            Button("New Worktree", systemImage: "plus") {
                Task {
                    await repositoryStore.createRandomWorktree()
                }
            }
            .keyboardShortcut(AppShortcuts.newWorktree.keyEquivalent, modifiers: AppShortcuts.newWorktree.modifiers)
            .help("New Worktree (\(AppShortcuts.newWorktree.display))")
            .disabled(!repositoryStore.canCreateWorktree)
        }
    }
}
