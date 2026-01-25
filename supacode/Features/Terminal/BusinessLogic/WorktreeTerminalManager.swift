import Observation

@MainActor
@Observable
final class WorktreeTerminalManager {
  private let runtime: GhosttyRuntime
  private var states: [Worktree.ID: WorktreeTerminalState] = [:]
  private var notificationsEnabled = true

  init(runtime: GhosttyRuntime) {
    self.runtime = runtime
  }

  func state(
    for worktree: Worktree,
    runSetupScriptIfNew: () -> Bool = { false }
  ) -> WorktreeTerminalState {
    if let existing = states[worktree.id] {
      return existing
    }
    let runSetupScript = runSetupScriptIfNew()
    let state = WorktreeTerminalState(
      runtime: runtime,
      worktree: worktree,
      runSetupScript: runSetupScript
    )
    state.setNotificationsEnabled(notificationsEnabled)
    states[worktree.id] = state
    return state
  }

  func createTab(in worktree: Worktree) {
    let state = state(for: worktree)
    _ = state.createTab()
  }

  @discardableResult
  func closeFocusedTab(in worktree: Worktree) -> Bool {
    let state = state(for: worktree)
    return state.closeFocusedTab()
  }

  @discardableResult
  func closeFocusedSurface(in worktree: Worktree) -> Bool {
    let state = state(for: worktree)
    return state.closeFocusedSurface()
  }

  func prune(keeping worktreeIDs: Set<Worktree.ID>) {
    var removed: [WorktreeTerminalState] = []
    for (id, state) in states where !worktreeIDs.contains(id) {
      removed.append(state)
    }
    for state in removed {
      state.closeAllSurfaces()
    }
    states = states.filter { worktreeIDs.contains($0.key) }
  }

  func focusedTaskStatus(for worktreeID: Worktree.ID) -> WorktreeTaskStatus? {
    states[worktreeID]?.focusedTaskStatus
  }

  func setNotificationsEnabled(_ enabled: Bool) {
    notificationsEnabled = enabled
    for state in states.values {
      state.setNotificationsEnabled(enabled)
    }
  }

  func hasUnseenNotifications(for worktreeID: Worktree.ID) -> Bool {
    states[worktreeID]?.hasUnseenNotification == true
  }

  func clearNotificationIndicator(for worktree: Worktree) {
    states[worktree.id]?.clearNotificationIndicator()
  }
}
