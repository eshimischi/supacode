import Dispatch
import Foundation
import Darwin

@MainActor
final class WorktreeInfoWatcherManager {
  private struct Watcher {
    let headURL: URL
    let source: DispatchSourceFileSystemObject
  }

  private var worktrees: [Worktree.ID: Worktree] = [:]
  private var watchers: [Worktree.ID: Watcher] = [:]
  private var debounceTasks: [Worktree.ID: Task<Void, Never>] = [:]
  private var restartTasks: [Worktree.ID: Task<Void, Never>] = [:]
  private var eventContinuation: AsyncStream<WorktreeInfoWatcherClient.Event>.Continuation?

  func handleCommand(_ command: WorktreeInfoWatcherClient.Command) {
    switch command {
    case .setWorktrees(let worktrees):
      setWorktrees(worktrees)
    case .stop:
      stopAll()
    }
  }

  func eventStream() -> AsyncStream<WorktreeInfoWatcherClient.Event> {
    eventContinuation?.finish()
    let (stream, continuation) = AsyncStream.makeStream(of: WorktreeInfoWatcherClient.Event.self)
    eventContinuation = continuation
    return stream
  }

  private func setWorktrees(_ worktrees: [Worktree]) {
    let worktreesByID = Dictionary(uniqueKeysWithValues: worktrees.map { ($0.id, $0) })
    let desiredIDs = Set(worktreesByID.keys)
    let currentIDs = Set(self.worktrees.keys)
    let removedIDs = currentIDs.subtracting(desiredIDs)
    for id in removedIDs {
      stopWatcher(for: id)
    }
    self.worktrees = worktreesByID
    for worktree in worktrees {
      configureWatcher(for: worktree)
    }
  }

  private func configureWatcher(for worktree: Worktree) {
    guard let headURL = GitWorktreeHeadResolver.headURL(
      for: worktree.workingDirectory,
      fileManager: .default
    ) else {
      stopWatcher(for: worktree.id)
      return
    }
    if let existing = watchers[worktree.id], existing.headURL == headURL {
      return
    }
    stopWatcher(for: worktree.id)
    startWatcher(worktreeID: worktree.id, headURL: headURL)
  }

  private func startWatcher(worktreeID: Worktree.ID, headURL: URL) {
    let path = headURL.path(percentEncoded: false)
    let fileDescriptor = open(path, O_EVTONLY)
    guard fileDescriptor >= 0 else {
      return
    }
    let queue = DispatchQueue(label: "worktree-info-watcher.\(worktreeID)")
    let source = DispatchSource.makeFileSystemObjectSource(
      fileDescriptor: fileDescriptor,
      eventMask: [.write, .rename, .delete, .attrib],
      queue: queue
    )
    source.setEventHandler { [weak self, weak source] in
      guard let source else { return }
      let event = source.data
      Task { @MainActor in
        self?.handleEvent(worktreeID: worktreeID, event: event)
      }
    }
    source.setCancelHandler {
      close(fileDescriptor)
    }
    source.resume()
    watchers[worktreeID] = Watcher(headURL: headURL, source: source)
  }

  private func handleEvent(
    worktreeID: Worktree.ID,
    event: DispatchSource.FileSystemEvent
  ) {
    if event.contains(.delete) || event.contains(.rename) {
      stopWatcher(for: worktreeID)
      scheduleRestart(worktreeID: worktreeID)
      return
    }
    scheduleBranchChanged(worktreeID: worktreeID)
  }

  private func scheduleBranchChanged(worktreeID: Worktree.ID) {
    debounceTasks[worktreeID]?.cancel()
    let task = Task { [weak self] in
      try? await Task.sleep(for: .milliseconds(200))
      await MainActor.run {
        self?.emit(.branchChanged(worktreeID: worktreeID))
      }
    }
    debounceTasks[worktreeID] = task
  }

  private func scheduleRestart(worktreeID: Worktree.ID) {
    restartTasks[worktreeID]?.cancel()
    let task = Task { [weak self] in
      try? await Task.sleep(for: .milliseconds(200))
      await MainActor.run {
        self?.restartWatcher(worktreeID: worktreeID)
      }
    }
    restartTasks[worktreeID] = task
  }

  private func restartWatcher(worktreeID: Worktree.ID) {
    guard watchers[worktreeID] == nil else {
      return
    }
    guard let worktree = worktrees[worktreeID] else {
      return
    }
    configureWatcher(for: worktree)
  }

  private func stopWatcher(for worktreeID: Worktree.ID) {
    if let watcher = watchers.removeValue(forKey: worktreeID) {
      watcher.source.cancel()
    }
    debounceTasks.removeValue(forKey: worktreeID)?.cancel()
    restartTasks.removeValue(forKey: worktreeID)?.cancel()
  }

  private func stopAll() {
    for (id, watcher) in watchers {
      watcher.source.cancel()
      debounceTasks.removeValue(forKey: id)?.cancel()
      restartTasks.removeValue(forKey: id)?.cancel()
    }
    watchers.removeAll()
    worktrees.removeAll()
    eventContinuation?.finish()
  }

  private func emit(_ event: WorktreeInfoWatcherClient.Event) {
    eventContinuation?.yield(event)
  }
}
