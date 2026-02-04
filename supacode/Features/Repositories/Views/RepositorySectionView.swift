import ComposableArchitecture
import SwiftUI

struct RepositorySectionView: View {
  let repository: Repository
  @Binding var expandedRepoIDs: Set<Repository.ID>
  @Bindable var store: StoreOf<RepositoriesFeature>
  let terminalManager: WorktreeTerminalManager
  @Environment(\.colorScheme) private var colorScheme

  var body: some View {
    let state = store.state
    let isExpanded = expandedRepoIDs.contains(repository.id)
    let isRemovingRepository = state.isRemovingRepository(repository)
    let isExpandedBinding = Binding(
      get: { expandedRepoIDs.contains(repository.id) },
      set: { isExpanded in
        guard !isRemovingRepository else { return }
        withAnimation(.easeOut(duration: 0.2)) {
          if isExpanded {
            expandedRepoIDs.insert(repository.id)
          } else {
            expandedRepoIDs.remove(repository.id)
          }
        }
      }
    )
    let openRepoSettings = {
      _ = store.send(.openRepositorySettings(repository.id))
    }
    Section(isExpanded: isExpandedBinding) {
      WorktreeRowsView(
        repository: repository,
        isExpanded: isExpanded,
        store: store,
        terminalManager: terminalManager
      )
    } header: {
      HStack {
        RepoHeaderRow(
          name: repository.name,
          isRemoving: isRemovingRepository
        )
        .frame(maxWidth: .infinity, alignment: .leading)
        if isRemovingRepository {
          ProgressView()
            .controlSize(.small)
        }
        Menu {
          Button("Repo Settings") {
            openRepoSettings()
          }
          .help("Repo Settings ")
          Button("Remove Repository") {
            store.send(.requestRemoveRepository(repository.id))
          }
          .help("Remove repository ")
          .disabled(isRemovingRepository)
        } label: {
          Label("Repository options", systemImage: "ellipsis")
            .labelStyle(.iconOnly)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
        .help("Repository options ")
        .disabled(isRemovingRepository)
        Button {
          store.send(.createRandomWorktreeInRepository(repository.id))
        } label: {
          Label("New Worktree", systemImage: "plus")
            .labelStyle(.iconOnly)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
        .help("New Worktree (\(AppShortcuts.newWorktree.display))")
        .disabled(isRemovingRepository)
      }
      .contentShape(.rect)
      .contextMenu {
        Button("Repo Settings") {
          openRepoSettings()
        }
        .help("Repo Settings ")
        Button("Remove Repository") {
          store.send(.requestRemoveRepository(repository.id))
        }
        .help("Remove repository ")
        .disabled(isRemovingRepository)
      }
      .contentShape(.dragPreview, .rect)
      .environment(\.colorScheme, colorScheme)
      .preferredColorScheme(colorScheme)
      .listRowInsets(EdgeInsets())
    }
  }
}
