import SwiftUI

struct WorktreeNotificationsListView: View {
  @Bindable var state: WorktreeTerminalState

  var body: some View {
    if state.notificationsEnabled, !state.notifications.isEmpty {
      VStack(alignment: .leading) {
        Text("Notifications")
          .foregroundStyle(.secondary)
        ForEach(state.notifications) { notification in
          Button {
            _ = state.focusSurface(id: notification.surfaceId)
          } label: {
            VStack(alignment: .leading) {
              if !notification.title.isEmpty {
                Text(notification.title)
                  .bold()
              }
              if !notification.body.isEmpty {
                Text(notification.body)
                  .foregroundStyle(.secondary)
              }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
          }
          .buttonStyle(.plain)
          .help("Focus pane (no shortcut)")
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }
}
