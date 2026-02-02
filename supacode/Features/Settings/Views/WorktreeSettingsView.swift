import ComposableArchitecture
import SwiftUI

struct WorktreeSettingsView: View {
  @Bindable var store: StoreOf<SettingsFeature>

  var body: some View {
    VStack(alignment: .leading) {
      Form {
        Section("Worktree") {
          VStack(alignment: .leading) {
            Toggle(
              "Delete branch on archive",
              isOn: $store.deleteBranchOnArchive
            )
            .help("Delete the local branch when archiving a worktree")
            Text("Delete the local branch when archiving a worktree.")
              .foregroundStyle(.secondary)
            Text("To delete the remote branch, configure it on GitHub.")
              .foregroundStyle(.secondary)
            Text("Warning: archived worktrees will be unrecoverable")
              .foregroundStyle(.red)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
        }
      }
      .formStyle(.grouped)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
  }
}
