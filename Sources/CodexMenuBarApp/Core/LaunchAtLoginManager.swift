import Foundation
import ServiceManagement

@MainActor
final class LaunchAtLoginManager: ObservableObject {
    @Published private(set) var isEnabled: Bool

    init() {
        self.isEnabled = Self.currentStatus
    }

    func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            isEnabled = enabled
        } catch {
            isEnabled = Self.currentStatus
        }
    }

    private static var currentStatus: Bool {
        SMAppService.mainApp.status == .enabled
    }
}
