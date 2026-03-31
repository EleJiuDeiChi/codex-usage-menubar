import AppKit
import ServiceManagement
import SwiftUI

@main
struct CodexMenuBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var snapshot = MenuBarSnapshot()
    @State private var refreshTask: Task<Void, Never>?
    @StateObject private var launchAtLoginManager = LaunchAtLoginManager()

    private let viewModel = MenuBarViewModel()
    private let refreshTimer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var body: some Scene {
        MenuBarExtra {
            MenuBarContentView(
                snapshot: snapshot,
                launchAtLoginEnabled: launchAtLoginManager.isEnabled,
                onRefresh: scheduleRefresh,
                onToggleLaunchAtLogin: { launchAtLoginManager.setEnabled($0) },
                onQuit: { NSApp.terminate(nil) }
            )
            .task {
                await refresh()
            }
            .onReceive(refreshTimer) { _ in
                scheduleRefresh()
            }
        } label: {
            Text(snapshot.menuBarTitle)
        }
        .menuBarExtraStyle(.window)
    }

    private func scheduleRefresh() {
        refreshTask?.cancel()
        refreshTask = Task {
            await refresh()
        }
    }

    @MainActor
    private func refresh() async {
        await viewModel.refresh()
        snapshot = await viewModel.snapshot
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}
