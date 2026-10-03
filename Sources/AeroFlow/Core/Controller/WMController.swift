// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2026 BarutSRB — https://github.com/OmniNull/OmniWM
// Copyright (C) 2026 Timur Iskakov — https://github.com/frostymur

import AeroFlowIPC
import AppKit
import Foundation

@MainActor @Observable
final class WMController {
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

    init(
        settings: SettingsStore,
        diagnosticsDirectory: URL = AeroFlowStoragePaths.live.diagnosticsDirectory,
        windowFocusOperations: WindowFocusOperations = .live,
        ownedWindowRegistry: OwnedWindowRegistry = .shared
    ) {
        self.settings = settings
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

    func handleRuntimeInvalidation(
        workspaceId: WorkspaceDescriptor.ID?,
        domains: InvalidationDomain,
        surfaceScope: SessionSurfaceInvalidationScope
    ) {
        layoutRefreshController.workspaceSwipe.handleInvalidation(workspaceId: workspaceId, domains: domains)
        if surfaceScope == .full {
            surfaceReconciler.noteWorldChanged()
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
