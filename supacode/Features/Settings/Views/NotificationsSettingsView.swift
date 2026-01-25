import ComposableArchitecture
import SwiftUI

struct NotificationsSettingsView: View {
  @Bindable var store: StoreOf<SettingsFeature>

  var body: some View {
    VStack(alignment: .leading) {
      Form {
        Section("Notifications") {
          Toggle(
            "In-app notifications",
            isOn: Binding(
              get: { store.inAppNotificationsEnabled },
              set: { store.send(.setInAppNotificationsEnabled($0)) }
            )
          )
          .help("In-app notifications (no shortcut)")
        }
      }
      .formStyle(.grouped)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
  }
}
