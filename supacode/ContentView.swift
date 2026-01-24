//
//  ContentView.swift
//  supacode
//
//  Created by khoi on 20/1/26.
//

import ComposableArchitecture
import Kingfisher
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
  @Bindable var store: StoreOf<AppFeature>
  let terminalStore: WorktreeTerminalStore
  @Environment(\.scenePhase) private var scenePhase
  @State private var sidebarVisibility: NavigationSplitViewVisibility = .all

  init(store: StoreOf<AppFeature>, terminalStore: WorktreeTerminalStore) {
    self.store = store
    self.terminalStore = terminalStore
  }

  var body: some View {
    let repositoriesStore = store.scope(state: \.repositories, action: \.repositories)
    NavigationSplitView(columnVisibility: $sidebarVisibility) {
      SidebarView(store: repositoriesStore)
    } detail: {
      WorktreeDetailView(store: store, terminalStore: terminalStore)
    }
    .navigationSplitViewStyle(.balanced)
    .task {
      store.send(.task)
    }
    .onChange(of: scenePhase) { _, newValue in
      store.send(.scenePhaseChanged(newValue))
    }
    .fileImporter(
      isPresented: Binding(
        get: { store.repositories.isOpenPanelPresented },
        set: { store.send(.repositories(.setOpenPanelPresented($0))) }
      ),
      allowedContentTypes: [.folder],
      allowsMultipleSelection: true
    ) { result in
      switch result {
      case .success(let urls):
        store.send(.repositories(.openRepositories(urls)))
      case .failure:
        store.send(
          .repositories(
            .presentAlert(
              title: "Unable to open folders",
              message: "Supacode could not read the selected folders."
            )
          )
        )
      }
    }
    .alert(store: repositoriesStore.scope(state: \.$alert, action: \.alert))
    .alert(store: store.scope(state: \.$alert, action: \.alert))
    .focusedSceneValue(\.toggleSidebarAction, toggleSidebar)
  }

  private func toggleSidebar() {
    withAnimation(.easeInOut(duration: 0.2)) {
      sidebarVisibility = sidebarVisibility == .detailOnly ? .all : .detailOnly
    }
  }
}

private struct WorktreeDetailView: View {
  @Bindable var store: StoreOf<AppFeature>
  let terminalStore: WorktreeTerminalStore

  var body: some View {
    detailBody(state: store.state)
  }

  @ViewBuilder
  private func detailBody(state: AppFeature.State) -> some View {
    let repositories = state.repositories
    let selectedRow = repositories.selectedRow(for: repositories.selectedWorktreeID)
    let selectedWorktree = repositories.worktree(for: repositories.selectedWorktreeID)
    let loadingInfo = loadingInfo(for: selectedRow, repositories: repositories)
    let isOpenDisabled = selectedWorktree == nil || loadingInfo != nil
    let openActionSelection = state.openActionSelection
    let openSelectedWorktreeAction: (() -> Void)? = isOpenDisabled
      ? nil
      : { store.send(.openSelectedWorktree) }
    let newTerminalAction: (() -> Void)? = isOpenDisabled
      ? nil
      : { store.send(.newTerminal) }
    let closeTabAction: (() -> Void)? = isOpenDisabled
      ? nil
      : { store.send(.closeTab) }
    let closeSurfaceAction: (() -> Void)? = isOpenDisabled
      ? nil
      : { store.send(.closeSurface) }
    Group {
      if let loadingInfo {
        WorktreeLoadingView(info: loadingInfo)
      } else if let selectedWorktree {
        let shouldRunSetupScript = repositories.pendingSetupScriptWorktreeIDs.contains(selectedWorktree.id)
        WorktreeTerminalTabsView(
          worktree: selectedWorktree,
          store: terminalStore,
          shouldRunSetupScript: shouldRunSetupScript,
          createTab: { store.send(.newTerminal) }
        )
        .id(selectedWorktree.id)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
          if shouldRunSetupScript {
            store.send(.repositories(.consumeSetupScript(selectedWorktree.id)))
          }
        }
      } else {
        EmptyStateView(store: store.scope(state: \.repositories, action: \.repositories))
      }
    }
    .navigationTitle(selectedWorktree?.name ?? loadingInfo?.name ?? "Supacode")
    .toolbar {
      openToolbar(isOpenDisabled: isOpenDisabled, openActionSelection: openActionSelection)
    }
    .focusedSceneValue(\.newTerminalAction, newTerminalAction)
    .focusedSceneValue(\.closeTabAction, closeTabAction)
    .focusedSceneValue(\.closeSurfaceAction, closeSurfaceAction)
    .focusedSceneValue(\.openSelectedWorktreeAction, openSelectedWorktreeAction)
  }

  private func loadingInfo(
    for selectedRow: WorktreeRowModel?,
    repositories: RepositoriesFeature.State
  ) -> WorktreeLoadingInfo? {
    guard let selectedRow else { return nil }
    let repositoryName = repositories.repositoryName(for: selectedRow.repositoryID)
    if selectedRow.isDeleting {
      return WorktreeLoadingInfo(
        name: selectedRow.name,
        repositoryName: repositoryName,
        state: .removing
      )
    }
    if selectedRow.isPending {
      return WorktreeLoadingInfo(
        name: selectedRow.name,
        repositoryName: repositoryName,
        state: .creating
      )
    }
    return nil
  }

  @ToolbarContentBuilder
  private func openToolbar(
    isOpenDisabled: Bool,
    openActionSelection: OpenWorktreeAction
  ) -> some ToolbarContent {
    if !isOpenDisabled {
      ToolbarItemGroup(placement: .primaryAction) {
        openMenu(openActionSelection: openActionSelection)
      }
    }
  }

  @ViewBuilder
  private func openMenu(openActionSelection: OpenWorktreeAction) -> some View {
    Menu {
      ForEach(OpenWorktreeAction.allCases) { action in
        let isDefault = action == openActionSelection
        Button {
          store.send(.openActionSelectionChanged(action))
          store.send(.openWorktree(action))
        } label: {
          if let appIcon = action.appIcon {
            Label {
              Text(action.title)
            } icon: {
              Image(nsImage: appIcon)
                .accessibilityHidden(true)
            }
          } else {
            Label(action.title, systemImage: "app")
          }
        }
        .help(openActionHelpText(for: action, isDefault: isDefault))
      }
    } label: {
      Label {
        Text("Open")
      } icon: {
        if let appIcon = openActionSelection.appIcon {
          Image(nsImage: appIcon)
            .resizable()
            .scaledToFit()
            .accessibilityHidden(true)
        } else {
          Image(systemName: "folder")
            .resizable()
            .scaledToFit()
            .accessibilityHidden(true)
        }
      }
    }
    .help(openActionHelpText(for: openActionSelection, isDefault: true))
  }

  private func openActionHelpText(for action: OpenWorktreeAction, isDefault: Bool) -> String {
    isDefault
      ? "\(action.title) (\(AppShortcuts.openFinder.display))"
      : action.title
  }
}

private struct SidebarView: View {
  @Bindable var store: StoreOf<RepositoriesFeature>
  @State private var expandedRepoIDs: Set<Repository.ID>

  init(store: StoreOf<RepositoriesFeature>) {
    self.store = store
    let repositoryIDs = Set(store.repositories.map(\.id))
    let pendingRepositoryIDs = Set(store.pendingWorktrees.map(\.repositoryID))
    _expandedRepoIDs = State(initialValue: repositoryIDs.union(pendingRepositoryIDs))
  }

  var body: some View {
    let state = store.state
    let selectedRow = state.selectedRow(for: state.selectedWorktreeID)
    let removeWorktreeAction: (() -> Void)? = {
      guard let selectedRow, selectedRow.isRemovable else { return nil }
      return {
        store.send(.requestRemoveWorktree(selectedRow.id, selectedRow.repositoryID))
      }
    }()
    SidebarListView(store: store, expandedRepoIDs: $expandedRepoIDs)
      .focusedSceneValue(\.removeWorktreeAction, removeWorktreeAction)
  }
}

private struct SidebarListView: View {
  @Bindable var store: StoreOf<RepositoriesFeature>
  @Binding var expandedRepoIDs: Set<Repository.ID>

  var body: some View {
    let selection = Binding<Worktree.ID?>(
      get: { store.selectedWorktreeID },
      set: { store.send(.selectWorktree($0)) }
    )
    List(selection: selection) {
      ForEach(store.repositories) { repository in
        RepositorySectionView(
          repository: repository,
          expandedRepoIDs: $expandedRepoIDs,
          store: store
        )
      }
    }
    .listStyle(.sidebar)
    .frame(minWidth: 220)
    .onChange(of: store.repositories) { _, newValue in
      let current = Set(newValue.map(\.id))
      expandedRepoIDs.formUnion(current)
      expandedRepoIDs = expandedRepoIDs.intersection(current)
    }
    .onChange(of: store.pendingWorktrees) { _, newValue in
      let repositoryIDs = Set(newValue.map(\.repositoryID))
      expandedRepoIDs.formUnion(repositoryIDs)
    }
    .dropDestination(for: URL.self) { urls, _ in
      let fileURLs = urls.filter(\.isFileURL)
      guard !fileURLs.isEmpty else { return false }
      store.send(.openRepositories(fileURLs))
      return true
    }
  }
}

private struct RepositorySectionView: View {
  let repository: Repository
  @Binding var expandedRepoIDs: Set<Repository.ID>
  @Bindable var store: StoreOf<RepositoriesFeature>
  @Environment(\.openWindow) private var openWindow

  var body: some View {
    let state = store.state
    let isExpanded = expandedRepoIDs.contains(repository.id)
    let isRemovingRepository = state.isRemovingRepository(repository)
    let openRepoSettings = {
      openWindow(id: WindowIdentifiers.repoSettings, value: repository.id)
    }
    Section {
      WorktreeRowsView(
        repository: repository,
        isExpanded: isExpanded,
        store: store
      )
    } header: {
      HStack {
        Button {
          if expandedRepoIDs.contains(repository.id) {
            expandedRepoIDs.remove(repository.id)
          } else {
            expandedRepoIDs.insert(repository.id)
          }
        } label: {
          RepoHeaderRow(
            name: repository.name,
            initials: repository.initials,
            profileURL: repository.githubOwner.flatMap {
              Github.profilePictureURL(username: $0, size: 48)
            },
            isExpanded: isExpanded,
            isRemoving: isRemovingRepository
          )
        }
        .buttonStyle(.plain)
        .disabled(isRemovingRepository)
        .contextMenu {
          Button("Repo Settings") {
            openRepoSettings()
          }
          .help("Repo Settings (no shortcut)")
          Button("Remove Repository") {
            store.send(.requestRemoveRepository(repository.id))
          }
          .help("Remove repository (no shortcut)")
          .disabled(isRemovingRepository)
        }
        Spacer()
        if isRemovingRepository {
          ProgressView()
            .controlSize(.small)
        }
        Menu {
          Button("Repo Settings") {
            openRepoSettings()
          }
          .help("Repo Settings (no shortcut)")
        } label: {
          Label("Repository options", systemImage: "ellipsis")
        }
        .labelStyle(.iconOnly)
        .buttonStyle(.plain)
        .foregroundStyle(.primary)
        .help("Repository options (no shortcut)")
        .disabled(isRemovingRepository)
        Button("New Worktree", systemImage: "plus") {
          store.send(.createRandomWorktreeInRepository(repository.id))
        }
        .labelStyle(.iconOnly)
        .buttonStyle(.plain)
        .foregroundStyle(.primary)
        .padding(.trailing, 6)
        .help("New Worktree (\(AppShortcuts.newWorktree.display))")
        .disabled(isRemovingRepository)
      }
      .padding()
      .padding(.bottom, 6)
    }
  }
}

private struct WorktreeRowsView: View {
  let repository: Repository
  let isExpanded: Bool
  @Bindable var store: StoreOf<RepositoriesFeature>

  var body: some View {
    if isExpanded {
      let state = store.state
      let rows = state.worktreeRows(in: repository)
      let isRepositoryRemoving = state.isRemovingRepository(repository)
      ForEach(rows) { row in
        rowView(row, isRepositoryRemoving: isRepositoryRemoving)
      }
    }
  }

  @ViewBuilder
  private func rowView(_ row: WorktreeRowModel, isRepositoryRemoving: Bool) -> some View {
    if row.isRemovable, let worktree = store.state.worktree(for: row.id), !isRepositoryRemoving {
      WorktreeRow(
        name: row.name,
        isPinned: row.isPinned,
        isLoading: row.isPending || row.isDeleting
      )
      .tag(row.id)
      .contextMenu {
        if row.isPinned {
          Button("Unpin") {
            store.send(.unpinWorktree(worktree.id))
          }
          .help("Unpin (no shortcut)")
        } else {
          Button("Pin to top") {
            store.send(.pinWorktree(worktree.id))
          }
          .help("Pin to top (no shortcut)")
        }
        Button("Remove") {
          store.send(.requestRemoveWorktree(worktree.id, repository.id))
        }
        .help("Remove worktree (⌘⌫)")
      }
    } else {
      WorktreeRow(
        name: row.name,
        isPinned: row.isPinned,
        isLoading: row.isPending || row.isDeleting
      )
      .tag(row.id)
      .disabled(isRepositoryRemoving)
    }
  }
}

private struct RepoHeaderRow: View {
  let name: String
  let initials: String
  let profileURL: URL?
  let isExpanded: Bool
  let isRemoving: Bool

  var body: some View {
    HStack {
      Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
        .font(.caption)
        .foregroundStyle(.secondary)
        .accessibilityHidden(true)
      ZStack {
        RoundedRectangle(cornerRadius: 6, style: .continuous)
          .fill(.secondary.opacity(0.2))
        if let profileURL {
          KFImage(profileURL)
            .resizable()
            .placeholder {
              Text(initials)
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .scaledToFill()
        } else {
          Text(initials)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
      .frame(width: 24, height: 24)
      .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
      Text(name)
        .font(.headline)
        .foregroundStyle(.primary)
      if isRemoving {
        Text("Removing...")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
  }
}

private struct WorktreeRow: View {
  let name: String
  let isPinned: Bool
  let isLoading: Bool

  var body: some View {
    HStack(alignment: .firstTextBaseline) {
      ZStack {
        Image(systemName: "arrow.triangle.branch")
          .font(.caption)
          .foregroundStyle(.secondary)
          .opacity(isLoading ? 0 : 1)
          .accessibilityHidden(true)
        if isLoading {
          ProgressView()
            .controlSize(.small)
        }
      }
      Text(name)
      Spacer(minLength: 8)
      if isPinned {
        Image(systemName: "pin.fill")
          .font(.caption)
          .foregroundStyle(.secondary)
          .accessibilityHidden(true)
      }
    }
  }
}

private enum WorktreeLoadingState {
  case creating
  case removing
}

private struct WorktreeLoadingInfo: Hashable {
  let name: String
  let repositoryName: String?
  let state: WorktreeLoadingState
}

private struct WorktreeLoadingView: View {
  let info: WorktreeLoadingInfo

  var body: some View {
    let actionLabel = info.state == .creating ? "Creating" : "Removing"
    let followup =
      info.state == .creating
      ? "We will open the terminal when it's ready."
      : "We will close the terminal when it's ready."
    VStack {
      ProgressView()
      Text(info.name)
        .font(.headline)
      if let repositoryName = info.repositoryName {
        Text("\(actionLabel) worktree in \(repositoryName)")
          .font(.subheadline)
          .foregroundStyle(.secondary)
      } else {
        Text("\(actionLabel) worktree...")
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }
      Text(followup)
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .multilineTextAlignment(.center)
  }
}

private struct EmptyStateView: View {
  let store: StoreOf<RepositoriesFeature>

  var body: some View {
    VStack {
      Image(systemName: "tray")
        .font(.title2)
        .accessibilityHidden(true)
      Text("Open a git repository")
        .font(.headline)
      Text(
        "Press \(AppShortcuts.openRepository.display) "
          + "or click Open Repository to choose a repository."
      )
      .font(.subheadline)
      .foregroundStyle(.secondary)
      Button("Open Repository...") {
        store.send(.setOpenPanelPresented(true))
      }
      .keyboardShortcut(
        AppShortcuts.openRepository.keyEquivalent,
        modifiers: AppShortcuts.openRepository.modifiers
      )
      .help("Open Repository (\(AppShortcuts.openRepository.display))")
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(nsColor: .windowBackgroundColor))
    .multilineTextAlignment(.center)
  }
}
