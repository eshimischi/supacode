import ComposableArchitecture
import SwiftUI

struct RepositorySettingsView: View {
  @Bindable var store: StoreOf<RepositorySettingsFeature>

  var body: some View {
    let baseRefOptions =
      store.branchOptions.isEmpty ? [store.defaultWorktreeBaseRef] : store.branchOptions
    let settings = $store.settings
    Form {
      Section {
        if store.isBranchDataLoaded {
          Picker(
            "Branch new workspaces from",
            selection: $store.settings.worktreeBaseRef
          ) {
            Text("Automatic (\(store.defaultWorktreeBaseRef))")
              .tag(String?.none)
            ForEach(baseRefOptions, id: \.self) { ref in
              Text(ref)
                .tag(Optional(ref))
            }
          }
          .labelsHidden()
        } else {
          ProgressView()
            .controlSize(.small)
        }
      } header: {
        VStack(alignment: .leading, spacing: 4) {
          Text("Branch new workspaces from")
          Text("Each workspace is an isolated copy of your codebase.")
            .foregroundStyle(.secondary)
        }
      }
      Section {
        Toggle(
          "Copy ignored files to new worktrees",
          isOn: settings.copyIgnoredOnWorktreeCreate
        )
        .disabled(store.isBareRepository)
        Toggle(
          "Copy untracked files to new worktrees",
          isOn: settings.copyUntrackedOnWorktreeCreate
        )
        .disabled(store.isBareRepository)
        if store.isBareRepository {
          Text("Copy flags are ignored for bare repositories.")
            .foregroundStyle(.secondary)
        }
      } header: {
        VStack(alignment: .leading, spacing: 4) {
          Text("Worktree")
          Text("Applies when creating a new worktree")
            .foregroundStyle(.secondary)
        }
      }
      Section {
        ZStack(alignment: .topLeading) {
          TextEditor(
            text: settings.setupScript
          )
          .font(.body)
          .monospaced()
          .frame(minHeight: 120)
          if store.settings.setupScript.isEmpty {
            Text("claude --dangerously-skip-permissions")
              .foregroundStyle(.secondary)
              .padding(.leading, 6)
              .font(.body)
              .monospaced()
              .allowsHitTesting(false)
          }
        }
      } header: {
        VStack(alignment: .leading, spacing: 4) {
          Text("Setup Script")
          Text("Initial setup script that will be launched once after worktree creation")
            .foregroundStyle(.secondary)
        }
      }
      Section {
        ZStack(alignment: .topLeading) {
          TextEditor(
            text: settings.runScript
          )
          .font(.body)
          .monospaced()
          .frame(minHeight: 120)
          if store.settings.runScript.isEmpty {
            Text("npm run dev")
              .foregroundStyle(.secondary)
              .padding(.leading, 6)
              .font(.body)
              .monospaced()
              .allowsHitTesting(false)
          }
        }
      } header: {
        VStack(alignment: .leading, spacing: 4) {
          Text("Run Script")
          Text("Run script launched on demand from the toolbar")
            .foregroundStyle(.secondary)
        }
      }
    }
    .formStyle(.grouped)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .task {
      store.send(.task)
    }
  }
}
