import ComposableArchitecture
import SwiftUI

struct AppearanceSettingsView: View {
  @Bindable var store: StoreOf<SettingsFeature>

  var body: some View {
    VStack(alignment: .leading) {
      Form {
        Section("Appearance") {
          HStack {
            ForEach(AppearanceMode.allCases) { mode in
              AppearanceOptionCardView(
                mode: mode,
                isSelected: mode == store.appearanceMode
              ) {
                store.send(.setAppearanceMode(mode))
              }
            }
          }
        }
      }
      .formStyle(.grouped)
    }
    .frame(maxWidth: 520, maxHeight: .infinity, alignment: .topLeading)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
  }
}
