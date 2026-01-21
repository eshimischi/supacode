//
//  ContentView.swift
//  supacode
//
//  Created by khoi on 20/1/26.
//

import Observation
import SwiftUI
import UniformTypeIdentifiers
import Kingfisher

struct ContentView: View {
    let runtime: GhosttyRuntime
    @Environment(RepositoryStore.self) private var repositoryStore
    @State private var terminalStore: WorktreeTerminalStore
    @State private var sidebarVisibility: NavigationSplitViewVisibility = .all

    init(runtime: GhosttyRuntime) {
        self.runtime = runtime
        _terminalStore = State(initialValue: WorktreeTerminalStore(runtime: runtime))
    }

    var body: some View {
        @Bindable var repositoryStore = repositoryStore
        let selectedWorktree = repositoryStore.worktree(for: repositoryStore.selectedWorktreeID)
        let pendingWorktree = repositoryStore.pendingWorktree(for: repositoryStore.selectedWorktreeID)
        NavigationSplitView(columnVisibility: $sidebarVisibility) {
            SidebarView(
                repositories: repositoryStore.repositories,
                pendingWorktrees: repositoryStore.pendingWorktrees,
                selection: $repositoryStore.selectedWorktreeID,
                createWorktree: { repository in
                    Task {
                        await repositoryStore.createRandomWorktree(in: repository)
                    }
                }
            )
        } detail: {
            WorktreeDetailView(
                selectedWorktree: selectedWorktree,
                pendingWorktree: pendingWorktree,
                terminalStore: terminalStore,
                toggleSidebar: toggleSidebar
            )
        }
        .navigationSplitViewStyle(.balanced)
        .onChange(of: repositoryStore.repositories) { _, newValue in
            var worktreeIDs: Set<Worktree.ID> = []
            for repository in newValue {
                for worktree in repository.worktrees {
                    worktreeIDs.insert(worktree.id)
                }
            }
            terminalStore.prune(keeping: worktreeIDs)
        }
        .fileImporter(
            isPresented: $repositoryStore.isOpenPanelPresented,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                Task {
                    await repositoryStore.openRepositories(at: urls)
                }
            case .failure:
                repositoryStore.openError = OpenRepositoryError(
                    id: UUID(),
                    title: "Unable to open folders",
                    message: "Supacode could not read the selected folders."
                )
            }
        }
        .alert(item: $repositoryStore.openError) { error in
            Alert(
                title: Text(error.title),
                message: Text(error.message),
                dismissButton: .default(Text("OK"))
            )
        }
        .alert(item: $repositoryStore.createWorktreeError) { error in
            Alert(
                title: Text(error.title),
                message: Text(error.message),
                dismissButton: .default(Text("OK"))
            )
        }
        .focusedSceneValue(\.toggleSidebarAction, toggleSidebar)
    }

    private func toggleSidebar() {
        withAnimation(.easeInOut(duration: 0.2)) {
            sidebarVisibility = sidebarVisibility == .detailOnly ? .all : .detailOnly
        }
    }
}

private struct WorktreeDetailView: View {
    let selectedWorktree: Worktree?
    let pendingWorktree: PendingWorktree?
    let terminalStore: WorktreeTerminalStore
    let toggleSidebar: () -> Void
    @State private var openActionError: OpenActionError?

    var body: some View {
        Group {
            if let selectedWorktree {
                WorktreeTerminalTabsView(worktree: selectedWorktree, store: terminalStore)
                    .id(selectedWorktree.id)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let pendingWorktree {
                WorktreeLoadingView(name: pendingWorktree.name)
            } else {
                EmptyStateView()
            }
        }
        .navigationTitle(selectedWorktree?.name ?? pendingWorktree?.name ?? "Supacode")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Menu {
                    ForEach(OpenWorktreeAction.allCases) { action in
                        Button {
                            performOpenAction(action)
                        } label: {
                            if let appIcon = action.appIcon {
                                Label { Text(action.title) } icon: { Image(nsImage: appIcon) }
                            } else {
                                Label(action.title, systemImage: "app")
                            }
                        }
                        .modifier(OpenActionShortcutModifier(shortcut: action.shortcut))
                        .help(action.helpText)
                        .disabled(selectedWorktree == nil)
                    }
                } label: {
                    Label("Open", systemImage: "folder")
                }
                .help("Open Finder (\(AppShortcuts.openFinder.display))")
                .disabled(selectedWorktree == nil)
            }
        }
        .alert(item: $openActionError) { error in
            Alert(
                title: Text(error.title),
                message: Text(error.message),
                dismissButton: .default(Text("OK"))
            )
        }
        .focusedSceneValue(\.newTerminalAction, {
            guard let selectedWorktree else { return }
            terminalStore.createTab(in: selectedWorktree)
        })
        .focusedSceneValue(\.closeTabAction, {
            guard let selectedWorktree else { return }
            terminalStore.closeFocusedTab(in: selectedWorktree)
        })
    }

    private func performOpenAction(_ action: OpenWorktreeAction) {
        guard let selectedWorktree else { return }
        action.perform(with: selectedWorktree) { error in
            openActionError = error
        }
    }
}

private struct SidebarView: View {
    let repositories: [Repository]
    let pendingWorktrees: [PendingWorktree]
    @Binding var selection: Worktree.ID?
    let createWorktree: (Repository) -> Void
    @State private var expandedRepoIDs: Set<Repository.ID>

    init(
        repositories: [Repository],
        pendingWorktrees: [PendingWorktree],
        selection: Binding<Worktree.ID?>,
        createWorktree: @escaping (Repository) -> Void
    ) {
        self.repositories = repositories
        self.pendingWorktrees = pendingWorktrees
        _selection = selection
        self.createWorktree = createWorktree
        let repositoryIDs = Set(repositories.map(\.id))
        let pendingRepositoryIDs = Set(pendingWorktrees.map(\.repositoryID))
        _expandedRepoIDs = State(initialValue: repositoryIDs.union(pendingRepositoryIDs))
    }

    var body: some View {
        List(selection: $selection) {
            ForEach(repositories) { repository in
                Section {
                    if expandedRepoIDs.contains(repository.id) {
                        ForEach(pendingWorktrees.filter { $0.repositoryID == repository.id }) { pendingWorktree in
                            WorktreeRow(name: pendingWorktree.name, detail: pendingWorktree.detail, isLoading: true)
                                .tag(pendingWorktree.id)
                        }
                        ForEach(repository.worktrees) { worktree in
                            WorktreeRow(name: worktree.name, detail: worktree.detail, isLoading: false)
                                .tag(worktree.id)
                        }
                    }
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
                                isExpanded: expandedRepoIDs.contains(repository.id)
                            )
                        }
                        .buttonStyle(.plain)
                        Spacer()
                        Button("New Worktree", systemImage: "plus") {
                            createWorktree(repository)
                        }
                        .labelStyle(.iconOnly)
                        .buttonStyle(.plain)
                        .foregroundStyle(.primary)
                        .padding(.trailing, 6)
                        .help("New Worktree (\(AppShortcuts.newWorktree.display))")
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: 220)
        .onChange(of: repositories) { _, newValue in
            let current = Set(newValue.map(\.id))
            expandedRepoIDs.formUnion(current)
            expandedRepoIDs = expandedRepoIDs.intersection(current)
        }
        .onChange(of: pendingWorktrees) { _, newValue in
            let repositoryIDs = Set(newValue.map(\.repositoryID))
            expandedRepoIDs.formUnion(repositoryIDs)
        }
    }
}

private struct RepoHeaderRow: View {
    let name: String
    let initials: String
    let profileURL: URL?
    let isExpanded: Bool
    
    var body: some View {
        HStack {
            Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
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
        }
    }
}

private struct WorktreeRow: View {
    let name: String
    let detail: String
    let isLoading: Bool

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            ZStack {
                Image(systemName: "arrow.triangle.branch")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .opacity(isLoading ? 0 : 1)
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                }
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                Text(detail.isEmpty ? " " : detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .opacity(detail.isEmpty ? 0 : 1)
            }
        }
    }
}

private struct WorktreeLoadingView: View {
    let name: String

    var body: some View {
        VStack {
            ProgressView()
            Text(name)
                .font(.headline)
            Text("We will open the terminal when it's ready.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .multilineTextAlignment(.center)
    }
}

private struct EmptyStateView: View {
    @Environment(RepositoryStore.self) private var repositoryStore

    var body: some View {
        VStack {
            Image(systemName: "tray")
                .font(.title2)
            Text("Open a project or worktree")
                .font(.headline)
            Text("Press \(AppShortcuts.openRepository.display) or click Open Repository to choose a repository.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button("Open Repository...") {
                repositoryStore.isOpenPanelPresented = true
            }
            .help("Open Repository (\(AppShortcuts.openRepository.display))")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
        .multilineTextAlignment(.center)
    }
}

private struct OpenActionShortcutModifier: ViewModifier {
    let shortcut: AppShortcut?

    func body(content: Content) -> some View {
        if let shortcut {
            content.keyboardShortcut(shortcut.keyEquivalent, modifiers: shortcut.modifiers)
        } else {
            content
        }
    }
}
