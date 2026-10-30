import CoreGraphics
import Foundation

var checks = 0
var failures = 0
func check(_ value: @autoclosure () -> Bool, _ message: String) {
    checks += 1
    if !value() { failures += 1; print("FAIL: \(message)") }
}
func wheel(continuous: Bool = false, phase: Int64 = 0, momentum: Int64 = 0) -> CGEvent {
    let event = CGEvent(scrollWheelEvent2Source: nil, units: .line, wheelCount: 2,
                        wheel1: 3, wheel2: -2, wheel3: 0)!
    event.setIntegerValueField(.scrollWheelEventIsContinuous, value: continuous ? 1 : 0)
    event.setIntegerValueField(.scrollWheelEventScrollPhase, value: phase)
    event.setIntegerValueField(.scrollWheelEventMomentumPhase, value: momentum)
    return event
}
let fields: [CGEventField] = [
    .scrollWheelEventDeltaAxis1, .scrollWheelEventFixedPtDeltaAxis1, .scrollWheelEventPointDeltaAxis1,
    .scrollWheelEventDeltaAxis2, .scrollWheelEventFixedPtDeltaAxis2, .scrollWheelEventPointDeltaAxis2
]
let event = wheel()
for (index, field) in fields.enumerated() { event.setIntegerValueField(field, value: Int64(index + 11)) }
event.flags = [.maskShift, .maskControl]
event.timestamp = 123456789
let beforeValues = fields.map { event.getIntegerValueField($0) }
ScrollFilter.apply(to: event, horizontal: true)
for (index, field) in fields.enumerated() {
    let actual = event.getIntegerValueField(field)
    check(actual == -beforeValues[index],
          "Field \(field.rawValue): before \(beforeValues[index]), after \(actual)")
}
check(event.timestamp == 123456789, "Timing changed.")
check(event.flags == [.maskShift, .maskControl], "Modifier keys changed.")
for protected in [wheel(continuous: true), wheel(phase: 1), wheel(momentum: 1)] {
    let before = protected.data! as Data
    ScrollFilter.apply(to: protected, horizontal: true)
    check((protected.data! as Data) == before, "Trackpad/phase/momentum event changed.")
}
let verticalOnly = wheel()
let horizontalBefore = fields.suffix(3).map { verticalOnly.getIntegerValueField($0) }
ScrollFilter.apply(to: verticalOnly, horizontal: false)
check(fields.suffix(3).map { verticalOnly.getIntegerValueField($0) } == horizontalBefore,
      "Horizontal scroll must remain unchanged when disabled.")
let mouseMove = CGEvent(mouseEventSource: nil, mouseType: .mouseMoved,
                        mouseCursorPosition: CGPoint(x: 4, y: 8), mouseButton: .left)!
check(!ScrollFilter.shouldReverse(mouseMove), "Non-scroll input selected.")
let extreme = wheel()
extreme.setIntegerValueField(.scrollWheelEventPointDeltaAxis1, value: Int64(Int32.min))
ScrollFilter.apply(to: extreme, horizontal: true)
check(extreme.getIntegerValueField(.scrollWheelEventPointDeltaAxis1) == Int64(Int32.max), "Overflow handling failed.")
check(ScrollState.resolve(enabled: true, trusted: true, running: true, natural: true) == .active,
      "Authorized running service must show active.")
check(ScrollState.resolve(enabled: false, trusted: true, running: false, natural: true) == .paused,
      "Pause must be reflected in menu bar.")
check(ScrollState.resolve(enabled: false, trusted: false, running: false, natural: true) == .paused,
      "An explicit pause must remain paused while permission is missing.")
check(ScrollState.resolve(enabled: true, trusted: false, running: false, natural: true) == .permission,
      "Requested activation cannot appear active before permission.")
check(ScrollState.resolve(enabled: true, trusted: true, running: false, natural: true) == .unavailable,
      "Service failure must never appear active.")
check(ScrollState.resolve(enabled: true, trusted: true, running: true, natural: false) == .systemSetting,
      "Disabled system natural scrolling must show a setting warning.")
check(ScrollState.resolve(enabled: true, trusted: true, running: true, natural: nil) == .active,
      "An unknown system preference must not imply a service failure.")
check(LaunchRules.showWindow(isLogin: false, hasSeenVersion: true, showOnLogin: false),
      "Manual launches must always open a window.")
check(LaunchRules.showWindow(isLogin: true, hasSeenVersion: false, showOnLogin: false),
      "The first launch after installation or upgrade must open a window.")
check(!LaunchRules.showWindow(isLogin: true, hasSeenVersion: true, showOnLogin: false),
      "Subsequent login launches must respect silent startup.")
check(LaunchRules.showWindow(isLogin: true, hasSeenVersion: true, showOnLogin: true),
      "Login startup must respect the show-window preference.")
let laptop = CGRect(x: 0, y: 50, width: 1280, height: 650)
let lostWindow = CGRect(x: 3000, y: -900, width: 980, height: 780)
check(laptop.contains(WindowPlacement.restoredFrame(lostWindow, in: laptop, center: true)),
      "A disconnected display must not strand the window or title bar offscreen.")
let external = CGRect(x: -1920, y: 900, width: 1920, height: 1040)
check(external.contains(WindowPlacement.restoredFrame(lostWindow, in: external, center: false)),
      "Window placement must support displays with negative coordinates.")
let visibleWindow = CGRect(x: 20, y: 100, width: 900, height: 600)
check(WindowPlacement.restoredFrame(visibleWindow, in: laptop, center: false) == visibleWindow,
      "A visible window must preserve its position.")
print("\(failures == 0 ? "PASS" : "FAIL"): \(checks) checks, \(failures) failures.")
exit(failures == 0 ? 0 : 1)
