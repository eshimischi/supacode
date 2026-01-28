import ComposableArchitecture

struct RepositoryPersistenceClient {
  var loadRoots: @Sendable () -> [String]
  var saveRoots: @Sendable ([String]) -> Void
  var loadPinnedWorktreeIDs: @Sendable () -> [Worktree.ID]
  var savePinnedWorktreeIDs: @Sendable ([Worktree.ID]) -> Void
}

extension RepositoryPersistenceClient: DependencyKey {
  static let liveValue: RepositoryPersistenceClient = {
    return RepositoryPersistenceClient(
      loadRoots: {
        SettingsStorage().load().repositoryRoots
      },
      saveRoots: { roots in
        var settings = SettingsStorage().load()
        settings.repositoryRoots = roots
        SettingsStorage().save(settings)
      },
      loadPinnedWorktreeIDs: {
        SettingsStorage().load().pinnedWorktreeIDs
      },
      savePinnedWorktreeIDs: { ids in
        var settings = SettingsStorage().load()
        settings.pinnedWorktreeIDs = ids
        SettingsStorage().save(settings)
      }
    )
  }()
  static let testValue = RepositoryPersistenceClient(
    loadRoots: { [] },
    saveRoots: { _ in },
    loadPinnedWorktreeIDs: { [] },
    savePinnedWorktreeIDs: { _ in }
  )
}

extension DependencyValues {
  var repositoryPersistence: RepositoryPersistenceClient {
    get { self[RepositoryPersistenceClient.self] }
    set { self[RepositoryPersistenceClient.self] = newValue }
  }
}
