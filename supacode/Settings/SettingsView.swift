import ComposableArchitecture
import SwiftUI

struct SettingsView: View {
  let store: StoreOf<AppFeature>

  var body: some View {
    let settingsStore = store.scope(state: \.settings, action: \.settings)
    let updatesStore = store.scope(state: \.updates, action: \.updates)
    TabView {
      Tab("Agents", systemImage: "terminal") {
        CodingAgentSettingsView()
      }
      Tab("Chat", systemImage: "bubble.left.and.bubble.right") {
        ChatSettingsView()
      }
      Tab("Appearance", systemImage: "paintpalette") {
        AppearanceSettingsView(store: settingsStore)
      }
      Tab("Updates", systemImage: "arrow.down.circle") {
        UpdatesSettingsView(settingsStore: settingsStore, updatesStore: updatesStore)
      }
    }
    .scenePadding()
    .frame(minWidth: 560, minHeight: 420)
    .background(WindowLevelSetter(level: .floating))
  }
}
