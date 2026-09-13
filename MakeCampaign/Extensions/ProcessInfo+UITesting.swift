import Foundation

extension ProcessInfo {
    var isUITesting: Bool {
        arguments.contains("UI_TESTING")
    }
}
