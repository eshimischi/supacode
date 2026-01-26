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

  init(
    appearanceMode: AppearanceMode,
    updatesAutomaticallyCheckForUpdates: Bool,
    updatesAutomaticallyDownloadUpdates: Bool,
    inAppNotificationsEnabled: Bool
  ) {
    self.appearanceMode = appearanceMode
    self.updatesAutomaticallyCheckForUpdates = updatesAutomaticallyCheckForUpdates
    self.updatesAutomaticallyDownloadUpdates = updatesAutomaticallyDownloadUpdates
    self.inAppNotificationsEnabled = inAppNotificationsEnabled
  }

  init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    appearanceMode = try container.decode(AppearanceMode.self, forKey: .appearanceMode)
    updatesAutomaticallyCheckForUpdates = try container.decode(Bool.self, forKey: .updatesAutomaticallyCheckForUpdates)
    updatesAutomaticallyDownloadUpdates = try container.decode(Bool.self, forKey: .updatesAutomaticallyDownloadUpdates)
    inAppNotificationsEnabled = try container.decodeIfPresent(Bool.self, forKey: .inAppNotificationsEnabled) ?? Self.default.inAppNotificationsEnabled
  }
}
