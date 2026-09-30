// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2026 BarutSRB — https://github.com/OmniNull/OmniWM
// Copyright (C) 2026 Timur Iskakov — https://github.com/frostymur

import AppKit
import Observation
import SwiftUI

enum StatusMenuControlPreview: Equatable {
    case focusedWindow
    case keepAwake
    case focusMouse
    case focusEdge
    case mouseToFocused
    case followMonitor
    case moveEdge
    case mouseWarp
}

enum StatusMenuControl: String, CaseIterable, Identifiable {
    case bordersEnabled
    case preventSleepEnabled
    case focusFollowsMouse
    case focusCrossesMonitorAtEdge
    case moveMouseToFocusedWindow
    case focusFollowsWindowToMonitor
    case moveCrossesMonitorAtEdge
    case mouseWarpEnabled

    var id: String {
        rawValue
    }

    var icon: String {
        switch self {
        case .bordersEnabled:
            "square.dashed"
        case .preventSleepEnabled:
            "moon.zzz"
        case .focusFollowsMouse:
            "cursorarrow.motionlines"
        case .focusCrossesMonitorAtEdge:
            "display.2"
        case .moveMouseToFocusedWindow:
            "arrow.up.left.and.down.right.magnifyingglass"
        case .focusFollowsWindowToMonitor:
            "arrow.right.square"
        case .moveCrossesMonitorAtEdge:
            "macwindow.on.rectangle"
        case .mouseWarpEnabled:
            "arrow.left.arrow.right"
        }
    }

    var label: String {
        switch self {
        case .bordersEnabled:
            String(localized: "Borders")
        case .preventSleepEnabled:
            String(localized: "Keep Awake")
        case .focusFollowsMouse:
            String(localized: "Focus Mouse")
        case .focusCrossesMonitorAtEdge:
            String(localized: "Focus Edge")
        case .moveMouseToFocusedWindow:
            String(localized: "Mouse to Focused")
        case .focusFollowsWindowToMonitor:
            String(localized: "Follow Monitor")
        case .moveCrossesMonitorAtEdge:
            String(localized: "Move Edge")
        case .mouseWarpEnabled:
            String(localized: "Mouse Warp")
        }
    }

    var accessibilityName: String {
        switch self {
        case .bordersEnabled:
            String(localized: "Window Borders")
        case .preventSleepEnabled:
            String(localized: "Keep Awake")
        case .focusFollowsMouse:
            String(localized: "Focus Follows Mouse")
        case .focusCrossesMonitorAtEdge:
            String(localized: "Focus Across Monitor at Edge")
        case .moveMouseToFocusedWindow:
            String(localized: "Mouse to Focused")
        case .focusFollowsWindowToMonitor:
            String(localized: "Follow Window to Monitor")
        case .moveCrossesMonitorAtEdge:
            String(localized: "Move Window Across Monitor at Edge")
        case .mouseWarpEnabled:
            String(localized: "Mouse Warp")
        }
    }

    var explanation: String {
        String(localized: explanationResource)
    }

    private var explanationResource: LocalizedStringResource {
        switch self {
        case .bordersEnabled:
            "Shows a colored outline around the currently focused managed window. Customize its appearance in Settings."
        case .preventSleepEnabled:
            "Prevents idle display sleep while your user session is active. Manual sleep and closing the laptop lid still work."
        case .focusFollowsMouse:
            "Focuses a managed window when the pointer enters it—no click needed. Choose whether AeroFlow explicitly raises it in Settings, or hold Focus Lock to cross windows without changing focus."
        case .focusCrossesMonitorAtEdge:
            "At the last window in any direction, Focus continues left, right, up, or down onto the adjacent display in AeroFlow’s Routing Arrangement."
        case .moveMouseToFocusedWindow:
            "Moves the pointer into a window after AeroFlow navigation changes focus. It stays put if already inside or the pointer caused the focus."
        case .focusFollowsWindowToMonitor:
            "After moving a window or column to another workspace, switches there and keeps it focused. When off, you stay in the source workspace."
        case .moveCrossesMonitorAtEdge:
            "At a workspace edge, Move Window sends the focused window left, right, up, or down to the adjacent routed display and follows it."
        case .mouseWarpEnabled:
            "Moves the pointer across matching display edges using AeroFlow’s Routing Arrangement. Available only with multiple displays."
        }
    }

    var preview: StatusMenuControlPreview {
        switch self {
        case .bordersEnabled:
            .focusedWindow
        case .preventSleepEnabled:
            .keepAwake
        case .focusFollowsMouse:
            .focusMouse
        case .focusCrossesMonitorAtEdge:
            .focusEdge
        case .moveMouseToFocusedWindow:
            .mouseToFocused
        case .focusFollowsWindowToMonitor:
            .followMonitor
        case .moveCrossesMonitorAtEdge:
            .moveEdge
        case .mouseWarpEnabled:
            .mouseWarp
        }
    }
}

struct ToggleTileSpec: Identifiable {
    let control: StatusMenuControl
    let isOn: Binding<Bool>

    var id: String {
        control.id
    }
}

@MainActor
@Observable
final class StatusMenuModel {
    let settings: SettingsStore
    private(set) weak var controller: WMController?
    var cliManager: AppCLIManager?
    var updateCoordinator: (any AppUpdateCoordinating)?
    var checkForUpdatesAction: (() -> Void)?
    var ipcMenuEnabled = false
    var infoAlertPresenter: (String, String) -> Void
    var confirmationAlertPresenter: (String, String, String, String) -> Bool
    var settingsFileActionPerformer: (SettingsFileAction, SettingsStore) throws -> SettingsFileStatus
    private(set) var cliStatus: AppCLIExposureStatus?
    private(set) var menuPresentationGeneration = 0

    init(settings: SettingsStore, controller: WMController) {
        self.settings = settings
        self.controller = controller
        infoAlertPresenter = { title, message in
            let alert = NSAlert()
            alert.alertStyle = .informational
            alert.messageText = title
            alert.informativeText = message
            alert.addButton(withTitle: String(localized: "OK"))
            NSApplication.shared.activate(ignoringOtherApps: true)
            _ = alert.runModal()
        }
        confirmationAlertPresenter = { title, message, confirmTitle, cancelTitle in
            let alert = NSAlert()
            alert.alertStyle = .warning
            alert.messageText = title
            alert.informativeText = message
            alert.addButton(withTitle: confirmTitle)
            alert.addButton(withTitle: cancelTitle)
            NSApplication.shared.activate(ignoringOtherApps: true)
            return alert.runModal() == .alertFirstButtonReturn
        }
        settingsFileActionPerformer = { action, settings in
            try SettingsFileWorkflow.perform(
                action,
                settings: settings
            )
        }
    }

    var diagnosticsIssues: [DiagnosticsIssue] {
        controller?.diagnosticsIssues ?? []
    }

    var displaySpacesMode: DisplaySpacesMode {
        controller?.displaySpacesMode ?? .enabled
    }

    var isTraceCaptureActive: Bool {
        controller?.isTraceCaptureActive ?? false
    }

    var traceCapturePhase: TraceCapturePhase {
        controller?.traceCaptureStatus.phase ?? .idle
    }

    var traceCaptureProfile: TraceCaptureProfile? {
        controller?.traceCaptureStatus.profile
    }

    func menuWillOpen() {
        menuPresentationGeneration += 1
        controller?.refreshDiagnosticsIssues()
        cliStatus = cliManager?.exposureStatus()
    }

    func menuDidClose() {
        menuPresentationGeneration += 1
    }

    var toggleTiles: [ToggleTileSpec] {
        let settings = settings
        weak var controller = controller
        var tiles: [ToggleTileSpec] = [
            ToggleTileSpec(
                control: .bordersEnabled,
                isOn: Binding(
                    get: { settings.borders.enabled },
                    set: {
                        settings.borders.enabled = $0
                        controller?.borderSettingsChanged()
                    }
                )
            ),
            ToggleTileSpec(
                control: .preventSleepEnabled,
                isOn: Binding(
                    get: { settings.preventSleepEnabled },
                    set: {
                        settings.preventSleepEnabled = $0
                        controller?.setPreventSleepEnabled($0)
                    }
                )
            ),
            ToggleTileSpec(
                control: .focusFollowsMouse,
                isOn: Binding(
                    get: { settings.focus.followsMouse },
                    set: {
                        settings.focus.followsMouse = $0
                        controller?.setFocusFollowsMouse($0)
                    }
                )
            ),
            ToggleTileSpec(
                control: .focusCrossesMonitorAtEdge,
                isOn: Binding(
                    get: { settings.focus.crossesMonitorAtEdge },
                    set: { settings.focus.crossesMonitorAtEdge = $0 }
                )
            ),
            ToggleTileSpec(
                control: .moveMouseToFocusedWindow,
                isOn: Binding(
                    get: { settings.focus.moveMouseToFocusedWindow },
                    set: {
                        settings.focus.moveMouseToFocusedWindow = $0
                        controller?.setMoveMouseToFocusedWindow($0)
                    }
                )
            ),
            ToggleTileSpec(
                control: .focusFollowsWindowToMonitor,
                isOn: Binding(
                    get: { settings.focus.followsWindowToMonitor },
                    set: { settings.focus.followsWindowToMonitor = $0 }
                )
            ),
            ToggleTileSpec(
                control: .moveCrossesMonitorAtEdge,
                isOn: Binding(
                    get: { settings.focus.moveCrossesMonitorAtEdge },
                    set: { settings.focus.moveCrossesMonitorAtEdge = $0 }
                )
            ),
            ToggleTileSpec(
                control: .mouseWarpEnabled,
                isOn: Binding(
                    get: { settings.pointer.enabled },
                    set: { settings.pointer.enabled = $0 }
                )
            )
        ]
        return tiles
    }

    func openSettings(section: SettingsSection? = nil) {
        guard let controller else { return }
        SettingsWindowController.shared.show(
            settings: settings,
            controller: controller,
            updateCoordinator: updateCoordinator,
            section: section
        )
    }

    func openAppRules() {
        guard let controller else { return }
        AppRulesWindowController.shared.show(settings: settings, controller: controller)
    }

    func openReportIssue() {
        openSettings(section: .reportIssue)
    }

    func checkForUpdates() {
        checkForUpdatesAction?()
    }

    func openSponsors() {
        controller?.openSponsorsWindow()
    }

    func quit(terminate: @escaping @MainActor () -> Void = { NSApplication.shared.terminate(nil) }) {
        scheduleOnMainRunLoop(terminate)
    }

    func toggleTraceRecording(profile: TraceCaptureProfile = .problem) {
        guard let controller else { return }
        let wasRecording = controller.isTraceCaptureActive
        Task {
            switch await controller.toggleTraceCapture(desiredState: .toggle, profile: profile) {
            case .noChange,
                 .started:
                break
            case let .stopped(artifact):
                NSWorkspace.shared.activateFileViewerSelecting([artifact.url])
            case let .writeFailed(reason):
                infoAlertPresenter(
                    wasRecording
                        ? String(localized: "Recording could not be saved")
                        : String(localized: "Recording could not be started"),
                    reason
                )
            }
        }
    }

    func performSettingsFileAction(_ action: SettingsFileAction) {
        do {
            _ = try settingsFileActionPerformer(
                action,
                settings
            )
        } catch {
            Log.config.error("settings file action failed: \(error.localizedDescription)")
        }
    }

    func installCLI() {
        guard let cliManager else { return }
        let status = cliManager.exposureStatus()
        guard case let .notInstalled(linkURL, directoryOnPath) = status else {
            cliStatus = status
            return
        }

        let directoryURL = linkURL.deletingLastPathComponent()
        var message =
            String(
                localized: "AeroFlow will create a symlink at \(linkURL.path) pointing to its bundled aeroflowctl binary."
            )
        if !directoryOnPath {
            message +=
                String(
                    localized: "\n\n\(directoryURL.path) is not currently in your PATH, so Terminal may not find `aeroflowctl` until you add that directory."
                )
        }

        guard confirmationAlertPresenter(
            String(localized: "Install CLI to PATH?"),
            message,
            String(localized: "Install"),
            String(localized: "Cancel")
        ) else {
            return
        }

        do {
            let result = try cliManager.installCLIToPATH()
            cliStatus = cliManager.exposureStatus()
            infoAlertPresenter(String(localized: "CLI Installed"), installResultMessage(result))
        } catch {
            infoAlertPresenter(String(localized: "CLI Install Failed"), error.localizedDescription)
        }
    }

    func removeCLI() {
        guard let cliManager else { return }
        guard confirmationAlertPresenter(
            String(localized: "Remove CLI from PATH?"),
            String(localized: "AeroFlow will remove the symlink it created for `aeroflowctl`."),
            String(localized: "Remove"),
            String(localized: "Cancel")
        ) else {
            return
        }

        do {
            let result = try cliManager.removeInstalledCLI()
            cliStatus = cliManager.exposureStatus()
            infoAlertPresenter(String(localized: "CLI Link Updated"), installResultMessage(result))
        } catch {
            infoAlertPresenter(String(localized: "CLI Removal Failed"), error.localizedDescription)
        }
    }

    func installResultMessage(_ result: AppCLIInstallResult) -> String {
        switch result {
        case let .installed(linkURL, directoryOnPath),
             let .alreadyInstalled(linkURL, directoryOnPath):
            let state = directoryOnPath
                ? String(localized: "You can now run `aeroflowctl` from Terminal.")
                :
                String(
                    localized: "Add \(linkURL.deletingLastPathComponent().path) to PATH before using `aeroflowctl` in Terminal."
                )
            return "\(linkURL.path)\n\n\(state)"
        case let .homebrewManaged(linkURL):
            return String(localized: "Homebrew already manages `aeroflowctl` at \(linkURL.path).")
        case let .notInstalled(linkURL):
            return String(localized: "No AeroFlow-managed CLI symlink was found at \(linkURL.path).")
        case let .removed(linkURL):
            return String(localized: "Removed AeroFlow's CLI symlink at \(linkURL.path).")
        }
    }
}
