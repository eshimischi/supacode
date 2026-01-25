import Foundation

struct TerminalTabItem: Identifiable, Equatable, Sendable {
  let id: TerminalTabID
  var title: String
  var icon: String?
  var isDirty: Bool

  init(
    id: TerminalTabID = TerminalTabID(),
    title: String,
    icon: String?,
    isDirty: Bool = false
  ) {
    self.id = id
    self.title = title
    self.icon = icon
    self.isDirty = isDirty
  }
}
