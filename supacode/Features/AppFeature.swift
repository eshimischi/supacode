import ComposableArchitecture
import SwiftUI

@Reducer
struct AppFeature {
  @ObservableState
  struct State: Equatable {
    var repositories: RepositoriesFeature.State
    var settings: SettingsFeature.State
    var updates = UpdatesFeature.State()
    var openActionSelection: OpenWorktreeAction = .finder
    var didConfigureUpdates = false
    @Presents var alert: AlertState<Alert>?

    init(
      repositories: RepositoriesFeature.State = .init(),
      settings: SettingsFeature.State = .init()
    ) {
      self.repositories = repositories
      self.settings = settings
    }
  }

  enum Action: Equatable {
    case task
    case scenePhaseChanged(ScenePhase)
    case repositories(RepositoriesFeature.Action)
    case settings(SettingsFeature.Action)
    case updates(UpdatesFeature.Action)
    case openActionSelectionChanged(OpenWorktreeAction)
    case openSelectedWorktree
    case openWorktree(OpenWorktreeAction)
    case openWorktreeFailed(OpenActionError)
    case newTerminal
    case closeTab
    case closeSurface
    case alert(PresentationAction<Alert>)
  }

  enum Alert: Equatable {
    case dismiss
  }

  @Dependency(\.repositorySettingsClient) private var repositorySettingsClient
  @Dependency(\.workspaceClient) private var workspaceClient
  @Dependency(\.terminalClient) private var terminalClient

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .task:
        return .merge(
          .send(.repositories(.task)),
          .send(.settings(.task))
        )

      case .scenePhaseChanged(let phase):
        guard phase == .active else { return .none }
        return .send(.repositories(.loadPersistedRepositories))

      case .repositories(.delegate(.selectedWorktreeChanged(let worktree))):
        guard let worktree else {
          state.openActionSelection = .finder
          return .none
        }
        let settings = repositorySettingsClient.load(worktree.repositoryRootURL)
        state.openActionSelection = OpenWorktreeAction.fromSettingsID(settings.openActionID)
        return .none

      case .repositories(.delegate(.repositoriesChanged(let repositories))):
        let ids = Set(repositories.flatMap { $0.worktrees.map(\.id) })
        return .run { _ in
          await terminalClient.prune(ids)
        }

      case .settings(.delegate(.settingsChanged(let settings))):
        let checkInBackground = !state.didConfigureUpdates
        state.didConfigureUpdates = true
        return .send(
          .updates(
            .applySettings(
              automaticallyChecks: settings.updatesAutomaticallyCheckForUpdates,
              automaticallyDownloads: settings.updatesAutomaticallyDownloadUpdates,
              checkInBackground: checkInBackground
            )
          )
        )

      case .openActionSelectionChanged(let action):
        state.openActionSelection = action
        guard let worktree = state.repositories.worktree(for: state.repositories.selectedWorktreeID) else {
          return .none
        }
        var settings = repositorySettingsClient.load(worktree.repositoryRootURL)
        settings.openActionID = action.settingsID
        repositorySettingsClient.save(settings, worktree.repositoryRootURL)
        return .none

      case .openSelectedWorktree:
        return .send(.openWorktree(state.openActionSelection))

      case .openWorktree(let action):
        guard let worktree = state.repositories.worktree(for: state.repositories.selectedWorktreeID) else {
          return .none
        }
        return .run { send in
          await workspaceClient.open(action, worktree) { error in
            send(.openWorktreeFailed(error))
          }
        }

      case .openWorktreeFailed(let error):
        state.alert = AlertState {
          TextState(error.title)
        } actions: {
          ButtonState(role: .cancel, action: .dismiss) {
            TextState("OK")
          }
        } message: {
          TextState(error.message)
        }
        return .none

      case .newTerminal:
        guard let worktree = state.repositories.worktree(for: state.repositories.selectedWorktreeID) else {
          return .none
        }
        return .run { _ in
          _ = await terminalClient.createTab(worktree, nil)
        }

      case .closeTab:
        guard let worktree = state.repositories.worktree(for: state.repositories.selectedWorktreeID) else {
          return .none
        }
        return .run { _ in
          _ = await terminalClient.closeFocusedTab(worktree)
        }

      case .closeSurface:
        guard let worktree = state.repositories.worktree(for: state.repositories.selectedWorktreeID) else {
          return .none
        }
        return .run { _ in
          _ = await terminalClient.closeFocusedSurface(worktree)
        }

      case .alert(.dismiss):
        state.alert = nil
        return .none

      case .alert:
        return .none

      case .repositories:
        return .none

      case .settings:
        return .none

      case .updates:
        return .none
      }
    }
    ._printChanges()
    Scope(state: \.repositories, action: \.repositories) {
      RepositoriesFeature()
    }
    Scope(state: \.settings, action: \.settings) {
      SettingsFeature()
    }
    Scope(state: \.updates, action: \.updates) {
      UpdatesFeature()
    }
  }
}
