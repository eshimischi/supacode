import ComposableArchitecture

@Reducer
struct UpdatesFeature {
  @ObservableState
  struct State: Equatable {
  }

  enum Action: Equatable {
    case applySettings(
      automaticallyChecks: Bool,
      automaticallyDownloads: Bool,
      checkInBackground: Bool
    )
    case checkForUpdates
  }

  @Dependency(\.updaterClient) private var updaterClient

  var body: some Reducer<State, Action> {
    Reduce { _, action in
      switch action {
      case let .applySettings(checks, downloads, checkInBackground):
        return .run { _ in
          await updaterClient.configure(checks, downloads, checkInBackground)
        }

      case .checkForUpdates:
        return .run { _ in
          await updaterClient.checkForUpdates()
        }
      }
    }
  }
}
