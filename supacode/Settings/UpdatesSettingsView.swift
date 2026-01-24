import ComposableArchitecture
import SwiftUI

struct UpdatesSettingsView: View {
  @Bindable var settingsStore: StoreOf<SettingsFeature>
  let updatesStore: StoreOf<UpdatesFeature>

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      Form {
        Section("Automatic Updates") {
          Toggle(
            "Check for updates automatically",
            isOn: Binding(
              get: { settingsStore.updatesAutomaticallyCheckForUpdates },
              set: { settingsStore.send(.setUpdatesAutomaticallyCheckForUpdates($0)) }
            )
          )
          Toggle(
            "Download and install updates automatically",
            isOn: Binding(
              get: { settingsStore.updatesAutomaticallyDownloadUpdates },
              set: { settingsStore.send(.setUpdatesAutomaticallyDownloadUpdates($0)) }
            )
          )
          .disabled(!settingsStore.updatesAutomaticallyCheckForUpdates)
        }
      }
      .formStyle(.grouped)

      HStack {
        Button("Check for Updates Now") {
          updatesStore.send(.checkForUpdates)
        }
        .help("Check for Updates (\(AppShortcuts.checkForUpdates.display))")
        Spacer()
      }
      .padding(.top)
    }
    .frame(maxWidth: 520, maxHeight: .infinity, alignment: .topLeading)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
  }
}
