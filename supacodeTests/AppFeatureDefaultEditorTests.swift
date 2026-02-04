import ComposableArchitecture
import DependenciesTestSupport
import Foundation
import Testing

@testable import supacode

@MainActor
struct AppFeatureDefaultEditorTests {
  @Test(.dependencies) func defaultEditorAppliesToAutomaticRepositorySettings() async {
    let worktree = makeWorktree()
    let repositoriesState = makeRepositoriesState(worktree: worktree)
    var settings = GlobalSettings.default
    settings.defaultEditorID = OpenWorktreeAction.vscode.settingsID
    let store = TestStore(
      initialState: AppFeature.State(
        repositories: repositoriesState,
        settings: SettingsFeature.State(settings: settings)
      )
    ) {
      AppFeature()
    }

    await store.send(.repositories(.delegate(.selectedWorktreeChanged(worktree))))
    await store.receive(\.worktreeSettingsLoaded) {
      $0.openActionSelection = .vscode
      $0.selectedRunScript = ""
    }
    await store.finish()
  }

  private func makeWorktree() -> Worktree {
    Worktree(
      id: "/tmp/repo/wt-1",
      name: "wt-1",
      detail: "detail",
      workingDirectory: URL(fileURLWithPath: "/tmp/repo/wt-1"),
      repositoryRootURL: URL(fileURLWithPath: "/tmp/repo")
    )
  }

  private func makeRepositoriesState(worktree: Worktree) -> RepositoriesFeature.State {
    let repository = Repository(
      id: "/tmp/repo",
      rootURL: URL(fileURLWithPath: "/tmp/repo"),
      name: "repo",
      worktrees: [worktree]
    )
    var repositoriesState = RepositoriesFeature.State()
    repositoriesState.repositories = [repository]
    repositoriesState.selectedWorktreeID = worktree.id
    return repositoriesState
  }
}
