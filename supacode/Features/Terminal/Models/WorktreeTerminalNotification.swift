import Foundation

struct WorktreeTerminalNotification: Identifiable, Equatable, Sendable {
  let id: UUID
  let surfaceId: UUID
  let title: String
  let body: String

  init(id: UUID = UUID(), surfaceId: UUID, title: String, body: String) {
    self.id = id
    self.surfaceId = surfaceId
    self.title = title
    self.body = body
  }
}
