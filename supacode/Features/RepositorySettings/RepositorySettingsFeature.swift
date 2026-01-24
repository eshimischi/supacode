import ComposableArchitecture
import Foundation

@Reducer
struct RepositorySettingsFeature {
  @ObservableState
  struct State: Equatable {
    var rootURL: URL
    var settings: RepositorySettings

    init(rootURL: URL, settings: RepositorySettings = .default) {
      self.rootURL = rootURL
      self.settings = settings
    }
  }

  enum Action: Equatable {
    case task
    case setSetupScript(String)
  }

  @Dependency(\.repositorySettingsClient) private var repositorySettingsClient

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .task:
        state.settings = repositorySettingsClient.load(state.rootURL)
        return .none

      case .setSetupScript(let script):
        state.settings.setupScript = script
        repositorySettingsClient.save(state.settings, state.rootURL)
        return .none
      }
    }
  }
}
