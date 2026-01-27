import Foundation
import Testing

@testable import supacode

struct SettingsStorageTests {
  @Test func loadWritesDefaultsWhenMissing() throws {
    let root = try makeTempDirectory()
    defer { try? FileManager.default.removeItem(at: root) }
    let settingsURL = root.appending(path: "settings.json")
    let storage = SettingsStorage(settingsURL: settingsURL)

    let settings = storage.load()

    #expect(settings == .default)
    #expect(FileManager.default.fileExists(atPath: settingsURL.path(percentEncoded: false)))

    let data = try Data(contentsOf: settingsURL)
    let decoded = try JSONDecoder().decode(SettingsFile.self, from: data)
    #expect(decoded == .default)
  }

  @Test func saveAndReload() throws {
    let root = try makeTempDirectory()
    defer { try? FileManager.default.removeItem(at: root) }
    let settingsURL = root.appending(path: "settings.json")
    let storage = SettingsStorage(settingsURL: settingsURL)

    var settings = storage.load()
    settings.global.appearanceMode = .dark
    settings.repositoryRoots = ["/tmp/repo-a", "/tmp/repo-b"]
    settings.pinnedWorktreeIDs = ["/tmp/repo-a/wt-1"]
    storage.save(settings)

    let reloaded = SettingsStorage(settingsURL: settingsURL).load()
    #expect(reloaded.global.appearanceMode == .dark)
    #expect(reloaded.repositoryRoots == ["/tmp/repo-a", "/tmp/repo-b"])
    #expect(reloaded.pinnedWorktreeIDs == ["/tmp/repo-a/wt-1"])
  }

  @Test func invalidJSONResetsToDefaults() throws {
    let root = try makeTempDirectory()
    defer { try? FileManager.default.removeItem(at: root) }
    let settingsURL = root.appending(path: "settings.json")
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    try Data("{".utf8).write(to: settingsURL)

    let storage = SettingsStorage(settingsURL: settingsURL)
    let settings = storage.load()

    #expect(settings == .default)

    let data = try Data(contentsOf: settingsURL)
    let decoded = try JSONDecoder().decode(SettingsFile.self, from: data)
    #expect(decoded == .default)
  }

  @Test func migratesOldSettingsWithoutInAppNotificationsEnabled() throws {
    let root = try makeTempDirectory()
    defer { try? FileManager.default.removeItem(at: root) }
    let settingsURL = root.appending(path: "settings.json")
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)

    let oldSettings = """
      {
        "global": {
          "appearanceMode": "dark",
          "updatesAutomaticallyCheckForUpdates": false,
          "updatesAutomaticallyDownloadUpdates": true
        },
        "repositories": {}
      }
      """
    try Data(oldSettings.utf8).write(to: settingsURL)

    let storage = SettingsStorage(settingsURL: settingsURL)
    let settings = storage.load()

    #expect(settings.global.appearanceMode == .dark)
    #expect(settings.global.updatesAutomaticallyCheckForUpdates == false)
    #expect(settings.global.updatesAutomaticallyDownloadUpdates == true)
    #expect(settings.global.inAppNotificationsEnabled == true)
    #expect(settings.repositoryRoots.isEmpty)
    #expect(settings.pinnedWorktreeIDs.isEmpty)
  }

  private func makeTempDirectory() throws -> URL {
    let url = FileManager.default.temporaryDirectory
      .appending(path: UUID().uuidString, directoryHint: .isDirectory)
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
  }
}
