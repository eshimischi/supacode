import ComposableArchitecture
import DependenciesTestSupport
import Foundation
import Testing

@testable import supacode

@MainActor
struct RepositoriesFeaturePersistenceTests {
  @Test(.dependencies) func taskLoadsPinnedWorktreesBeforeRepositories() async {
    let pinned = ["/tmp/repo/wt-1"]
    let repositoryOrder = ["/tmp/repo"]
    let worktreeOrder = ["/tmp/repo": ["/tmp/repo/wt-1"]]
    let store = TestStore(initialState: RepositoriesFeature.State()) {
      RepositoriesFeature()
    } withDependencies: {
      $0.repositoryPersistence = RepositoryPersistenceClient(
        loadRoots: { [] },
        saveRoots: { _ in },
        loadPinnedWorktreeIDs: { pinned },
        savePinnedWorktreeIDs: { _ in },
        loadRepositoryOrderIDs: { repositoryOrder },
        saveRepositoryOrderIDs: { _ in },
        loadWorktreeOrderByRepository: { worktreeOrder },
        saveWorktreeOrderByRepository: { _ in },
        loadLastFocusedWorktreeID: { nil },
        saveLastFocusedWorktreeID: { _ in }
      )
    }

    await store.send(.task)
    await store.receive(\.pinnedWorktreeIDsLoaded) {
      $0.pinnedWorktreeIDs = pinned
    }
    await store.receive(\.repositoryOrderIDsLoaded) {
      $0.repositoryOrderIDs = repositoryOrder
    }
    await store.receive(\.worktreeOrderByRepositoryLoaded) {
      $0.worktreeOrderByRepository = worktreeOrder
    }
    await store.receive(\.lastFocusedWorktreeIDLoaded) {
      $0.lastFocusedWorktreeID = nil
      $0.shouldRestoreLastFocusedWorktree = true
    }
    await store.receive(\.loadPersistedRepositories)
    await store.receive(\.repositoriesLoaded) {
      $0.repositories = []
      $0.pinnedWorktreeIDs = []
      $0.repositoryOrderIDs = []
      $0.worktreeOrderByRepository = [:]
      $0.shouldRestoreLastFocusedWorktree = false
      $0.isInitialLoadComplete = true
    }
    await store.receive(\.delegate.repositoriesChanged)
    await store.finish()
  }
}
