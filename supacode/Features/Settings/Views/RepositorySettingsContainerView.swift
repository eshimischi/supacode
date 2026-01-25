import ComposableArchitecture
import SwiftUI

struct RepositorySettingsContainerView: View {
  let repository: Repository
  @State private var store: StoreOf<RepositorySettingsFeature>

  init(repository: Repository) {
    self.repository = repository
    _store = State(
      initialValue: Store(
        initialState: RepositorySettingsFeature.State(rootURL: repository.rootURL)
      ) {
        RepositorySettingsFeature()
      }
    )
  }

  var body: some View {
    RepositorySettingsView(store: store)
  }
}
