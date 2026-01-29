import ComposableArchitecture
import CustomDump
import Foundation
import Sentry

extension Reducer where State: Equatable {
  @ReducerBuilder<State, Action>
  func logActions() -> some Reducer<State, Action> {
    LogActionsReducer(base: self)
  }
}

struct LogActionsReducer<Base: Reducer>: Reducer where Base.State: Equatable {
  let base: Base

  func reduce(into state: inout Base.State, action: Base.Action) -> Effect<Base.Action> {
    let actionLabel = debugCaseOutput(action)
    #if DEBUG
      let previousState = state
      let effects = base.reduce(into: &state, action: action)
      print("Action: \(actionLabel)")
      if previousState != state, let diff = CustomDump.diff(previousState, state) {
        print(diff)
      }
      return effects
    #else
      let breadcrumb = Breadcrumb(level: .debug, category: "action")
      breadcrumb.message = actionLabel
      SentrySDK.addBreadcrumb(breadcrumb)
      return base.reduce(into: &state, action: action)
    #endif
  }
}

func debugCaseOutput(
  _ value: Any,
  abbreviated: Bool = false
) -> String {
  func debugCaseOutputHelp(_ value: Any) -> String {
    let mirror = Mirror(reflecting: value)
    switch mirror.displayStyle {
    case .enum:
      guard let child = mirror.children.first else {
        let childOutput = "\(value)"
        return childOutput == "\(typeName(type(of: value)))" ? "" : ".\(childOutput)"
      }
      let childOutput = debugCaseOutputHelp(child.value)
      return ".\(child.label ?? "")\(childOutput.isEmpty ? "" : "(\(childOutput))")"
    case .tuple:
      return mirror.children.map { label, value in
        let childOutput = debugCaseOutputHelp(value)
        let labelValue = label.map { isUnlabeledArgument($0) ? "_:" : "\($0):" } ?? ""
        let suffix = childOutput.isEmpty ? "" : " \(childOutput)"
        return "\(labelValue)\(suffix)"
      }
      .joined(separator: ", ")
    default:
      return ""
    }
  }

  return (value as? any CustomDebugStringConvertible)?.debugDescription
    ?? "\(abbreviated ? "" : typeName(type(of: value)))\(debugCaseOutputHelp(value))"
}

private func isUnlabeledArgument(_ label: String) -> Bool {
  label.firstIndex(where: { $0 != "." && !$0.isNumber }) == nil
}

private func typeName(
  _ type: Any.Type,
  qualified: Bool = true,
  genericsAbbreviated: Bool = true
) -> String {
  var name = _typeName(type, qualified: qualified)
    .replacingOccurrences(
      of: #"\(unknown context at \$[[:xdigit:]]+\)\."#,
      with: "",
      options: .regularExpression
    )
  for _ in 1...10 {
    let abbreviated =
      name
      .replacingOccurrences(
        of: #"\bSwift.Optional<([^><]+)>"#,
        with: "$1?",
        options: .regularExpression
      )
      .replacingOccurrences(
        of: #"\bSwift.Array<([^><]+)>"#,
        with: "[$1]",
        options: .regularExpression
      )
      .replacingOccurrences(
        of: #"\bSwift.Dictionary<([^,<]+), ([^><]+)>"#,
        with: "[$1: $2]",
        options: .regularExpression
      )
    if abbreviated == name { break }
    name = abbreviated
  }
  name = name.replacingOccurrences(
    of: #"\w+\.([\w.]+)"#,
    with: "$1",
    options: .regularExpression
  )
  if genericsAbbreviated {
    name = name.replacingOccurrences(
      of: #"<.+>"#,
      with: "",
      options: .regularExpression
    )
  }
  return name
}
