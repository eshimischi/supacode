nonisolated struct GlobalSettings: Codable, Equatable {
  var appearanceMode: AppearanceMode
  var updatesAutomaticallyCheckForUpdates: Bool
  var updatesAutomaticallyDownloadUpdates: Bool
  var inAppNotificationsEnabled: Bool

  static let `default` = GlobalSettings(
    appearanceMode: .system,
    updatesAutomaticallyCheckForUpdates: true,
    updatesAutomaticallyDownloadUpdates: false,
    inAppNotificationsEnabled: true
  )
}
