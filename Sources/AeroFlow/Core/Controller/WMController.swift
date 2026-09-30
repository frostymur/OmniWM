// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2026 BarutSRB — https://github.com/OmniNull/OmniWM
// Copyright (C) 2026 Timur Iskakov — https://github.com/frostymur

import AppKit
import Foundation
import AeroFlowIPC

@MainActor @Observable
final class WMController {
    private struct BorderLayoutConfig: Equatable {
        let enabled: Bool
        let width: CGFloat

        func clearance(scale: CGFloat) -> CGFloat {
            BorderConfig.layoutClearance(enabled: enabled, width: width, scale: scale)
        }
    }

    var isEnabled: Bool = true
    var hotkeysEnabled: Bool = true
    private(set) var desiredEnabled: Bool = true
    private(set) var desiredHotkeysEnabled: Bool = true
    private(set) var accessibilityPermissionGranted = AccessibilityPermissionMonitor.shared.isGranted
    private(set) var focusFollowsMouseEnabled: Bool = false
    private(set) var moveMouseToFocusedWindowEnabled: Bool = false
    private(set) var displaySpacesMode: DisplaySpacesMode = .enabled
    private var displaySpacesAlertShown = false
    var pendingCrashReport: FatalCapture.PendingCrashReport?
    var diagnosticsIssues: [DiagnosticsIssue] = []

    let settings: SettingsStore
    @ObservationIgnored
    private var appliedBorderLayoutConfig: BorderLayoutConfig
    let workspaceManager: WorkspaceManager
    let hotkeys = HotkeyCenter()
    private(set) var hotkeyRegistrationFailures: [HotkeyCommand: HotkeyRegistrationFailureReason] = [:]
    private(set) var systemHyperTriggerFailure: SystemHyperTriggerFailure?
    var isHyperTriggerActive: Bool {
        hotkeys.isHyperTriggerActive
    }

    let secureInputMonitor = SecureInputMonitor()
    let lockScreenObserver = LockScreenObserver()
    var isLockScreenActive: Bool = false {
        didSet {
            guard oldValue != isLockScreenActive else { return }
            if isLockScreenActive {
                layoutRefreshController.suspendForLockScreen()
                mouseEventHandler.handleInputSuppressionBegan()
            } else {
                layoutRefreshController.awaitPostUnlockTopologySample()
            }
        }
    }

    let axManager = AXManager()
    let traceCaptureCoordinator: RuntimeTraceCaptureCoordinator
    let appInfoCache = AppInfoCache()
    let eventIntake = EventIntake()
    let factResolver = FactResolver()
    let intentLedger = IntentLedger()
    let deadlineWheel = DeadlineWheel()

    @ObservationIgnored
    private(set) lazy var eventInterpreter = EventInterpreter(controller: self)
    let focusPolicyEngine: FocusPolicyEngine
    let windowRuleEngine = WindowRuleEngine()

    @ObservationIgnored
    private(set) lazy var tabRailManager = TabRailManager(motionPolicy: motionPolicy, appInfoCache: appInfoCache)
    @ObservationIgnored
    lazy var nativeFullscreenPlaceholderManager: NativeFullscreenPlaceholderManager = {
        let manager = NativeFullscreenPlaceholderManager()
        manager.appInfoCache = appInfoCache
        manager.onActivate = { [weak self] originalToken in
            self?.activateNativeFullscreenPlaceholder(originalToken)
        }
        return manager
    }()

    @ObservationIgnored
    private(set) lazy var surfaceReconciler = SurfaceReconciler(controller: self)
    @ObservationIgnored
    private var runtimeFrameJobCancellationSuppressionDepth: Int = 0
    @ObservationIgnored
    let floatDemotionTracker = FloatDemotionTracker()

    @ObservationIgnored
    private(set) lazy var sponsorsWindowController: SponsorsWindowController = .init(
        motionPolicy: motionPolicy,
        ownedWindowRegistry: ownedWindowRegistry
    )

    var isTransferringWindow: Bool = false

    @ObservationIgnored
    private(set) lazy var mouseEventHandler = MouseEventHandler(controller: self)
    @ObservationIgnored
    private(set) lazy var mouseWarpHandler = MouseWarpHandler(controller: self)
    @ObservationIgnored
    private(set) lazy var axEventHandler = AXEventHandler(controller: self)
    @ObservationIgnored
    private(set) lazy var placementResolver = PlacementResolver(workspaceManager: workspaceManager)
    @ObservationIgnored
    private(set) lazy var spaceTracker = SpaceTracker(controller: self)
    @ObservationIgnored
    private(set) lazy var commandHandler = CommandHandler(controller: self)
    @ObservationIgnored
    private(set) lazy var workspaceNavigationHandler = WorkspaceNavigationHandler(controller: self)
    @ObservationIgnored
    private(set) lazy var layoutRefreshController = LayoutRefreshController(controller: self)
    var niriLayoutHandler: NiriLayoutHandler {
        layoutRefreshController.niriHandler
    }

    var dwindleLayoutHandler: DwindleLayoutHandler {
        layoutRefreshController.dwindleHandler
    }

    @ObservationIgnored
    private(set) lazy var serviceLifecycleManager = ServiceLifecycleManager(controller: self)
    @ObservationIgnored
    private(set) var windowActionHandlerStorage: WindowActionHandler?
    var windowActionHandler: WindowActionHandler {
        if let windowActionHandlerStorage {
            return windowActionHandlerStorage
        }
        let handler = WindowActionHandler(controller: self)
        windowActionHandlerStorage = handler
        return handler
    }

    @ObservationIgnored
    private(set) lazy var focusNotificationDispatcher = FocusNotificationDispatcher(controller: self)
    @ObservationIgnored
    var hasStartedServices = false
    @ObservationIgnored
    private(set) var isMouseWarpPolicyEnabled = false
    @ObservationIgnored
    let ownedWindowRegistry: OwnedWindowRegistry
    @ObservationIgnored
    var warpMouseCursorPosition: (CGPoint) -> Void = { CGWarpMouseCursorPosition($0) }
    @ObservationIgnored
    var currentMouseLocation: () -> CGPoint = { NSEvent.mouseLocation }
    @ObservationIgnored
    weak var ipcApplicationBridge: IPCApplicationBridge?

    let animationClock = AnimationClock()
    let motionPolicy: MotionPolicy
    let diagnosticsDirectory: URL
    let windowFocusOperations: WindowFocusOperations
    weak var statusBarController: StatusBarController?
    @ObservationIgnored
    var effectiveAppearanceObserver: NSKeyValueObservation?
    @ObservationIgnored
    var borderUsesDarkAppearance = false

    init(
        settings: SettingsStore,
        diagnosticsDirectory: URL = AeroFlowStoragePaths.live.diagnosticsDirectory,
        windowFocusOperations: WindowFocusOperations = .live,
        ownedWindowRegistry: OwnedWindowRegistry = .shared
    ) {
        self.settings = settings
        appliedBorderLayoutConfig = BorderLayoutConfig(
            enabled: settings.borders.enabled,
            width: CGFloat(settings.borders.width)
        )
        motionPolicy = MotionPolicy(animationsEnabled: settings.animationsEnabled)
        self.diagnosticsDirectory = diagnosticsDirectory
        traceCaptureCoordinator = RuntimeTraceCaptureCoordinator(diagnosticsDirectory: diagnosticsDirectory)
        self.windowFocusOperations = windowFocusOperations
        self.ownedWindowRegistry = ownedWindowRegistry
        workspaceManager = WorkspaceManager(settings: settings)
        focusPolicyEngine = FocusPolicyEngine()
        configureInputRouting()
        configureSurfaceCallbacks()
        configureWorldCallbacks()
        configureFocusAndMenuCallbacks()
        installEffectiveAppearanceObserver()
    }
}

extension WMController {
    func setEnabled(_ enabled: Bool) {
        desiredEnabled = enabled
        if enabled {
            serviceLifecycleManager.start()
        } else {
            serviceLifecycleManager.stopRestoringWindows()
        }
        reconcileEnabledAndHotkeysState()
    }

    func setHotkeysEnabled(_ enabled: Bool) {
        desiredHotkeysEnabled = enabled
        reconcileEnabledAndHotkeysState()
    }

    func updateAccessibilityPermissionGranted(_ granted: Bool) {
        accessibilityPermissionGranted = granted
        reconcileEnabledAndHotkeysState()
    }

    func updateDisplaySpacesMode(_ mode: DisplaySpacesMode) {
        guard displaySpacesMode != mode else { return }
        displaySpacesMode = mode
        if mode == .disabled, !displaySpacesAlertShown {
            displaySpacesAlertShown = true
            presentSeparateSpacesAlert()
        }
    }

    func reconcileEnabledAndHotkeysState() {
        isEnabled = desiredEnabled && accessibilityPermissionGranted
            && !serviceLifecycleManager.isStoppingForUser && !serviceLifecycleManager.quitRequested

        let shouldEnableHotkeys = desiredHotkeysEnabled
            && isEnabled
            && hasStartedServices
            && !serviceLifecycleManager.isSecureInputActive
        hotkeysEnabled = shouldEnableHotkeys
        if shouldEnableHotkeys {
            hotkeys.start()
        } else {
            hotkeys.stop()
        }
        refreshHotkeyFailureSnapshots()
    }

    func borderSettingsChanged() {
        let current = BorderLayoutConfig(
            enabled: settings.borders.enabled,
            width: CGFloat(settings.borders.width)
        )
        let previous = appliedBorderLayoutConfig
        appliedBorderLayoutConfig = current
        let clearanceChanged = workspaceManager.monitors.contains { monitor in
            let scale = backingScaleFactor(for: monitor)
            return previous.clearance(scale: scale) != current.clearance(scale: scale)
        }
        if clearanceChanged {
            workspaceManager.invalidateAllLayouts()
            layoutRefreshController.requestRelayout(reason: .layoutConfigChanged)
            surfaceReconciler.noteWorldChanged()
        } else {
            surfaceReconciler.noteBorderChanged()
        }
    }

    func setFocusFollowsMouse(_ enabled: Bool) {
        focusFollowsMouseEnabled = enabled
        guard !enabled,
              let request = intentLedger.activeManagedRequest,
              request.origin == .focusFollowsMouse
        else {
            return
        }
        cancelManagedFocusRequestAndRestoreSource(request)
    }

    func setMoveMouseToFocusedWindow(_ enabled: Bool) {
        moveMouseToFocusedWindowEnabled = enabled
    }

    func refreshHotkeyFailureSnapshots() {
        hotkeyRegistrationFailures = hotkeys.registrationFailures
        systemHyperTriggerFailure = hotkeys.systemHyperTriggerFailure
    }

    var statusBarRefreshIsEnabled: Bool {
        statusBarController != nil && settings.statusBar.showWorkspaceName
    }

    func handleRuntimeInvalidation(
        workspaceId: WorkspaceDescriptor.ID?,
        domains: InvalidationDomain,
        surfaceScope: SessionSurfaceInvalidationScope
    ) {
        layoutRefreshController.workspaceSwipe.handleInvalidation(workspaceId: workspaceId, domains: domains)
        switch surfaceScope {
        case .full:
            surfaceReconciler.noteWorldChanged()
        case .border:
            surfaceReconciler.noteBorderChanged()
        }
        guard domains.contains(.workspace) || domains.contains(.fullscreen) else { return }
        guard runtimeFrameJobCancellationSuppressionDepth == 0 else { return }
        cancelPendingFrameJobsForInvalidation(workspaceId: workspaceId)
    }

    func withRuntimeFrameJobCancellationSuppressed<T>(_ body: () throws -> T) rethrows -> T {
        runtimeFrameJobCancellationSuppressionDepth += 1
        defer { runtimeFrameJobCancellationSuppressionDepth -= 1 }
        return try body()
    }

    #if DEBUG
        func testFloatingSpawnMonitorId(pid: pid_t) -> Monitor.ID? {
            placementResolver.floatingSpawnMonitorId(pid: pid)
        }
    #endif


    @discardableResult
    func syncMouseWarpPolicy(for monitors: [Monitor]? = nil) -> Bool {
        let effectiveMonitors = monitors ?? workspaceManager.monitors
        let shouldEnable = shouldUseMouseWarp(for: effectiveMonitors)

        guard shouldEnable != isMouseWarpPolicyEnabled else {
            return shouldEnable
        }

        if shouldEnable {
            mouseWarpHandler.setup()
        } else {
            mouseWarpHandler.cleanup()
        }

        isMouseWarpPolicyEnabled = shouldEnable
        return shouldEnable
    }

    func resetMouseWarpPolicy() {
        mouseWarpHandler.cleanup()
        isMouseWarpPolicyEnabled = false
    }

    func cleanupUIOnStop() {
    }
}
