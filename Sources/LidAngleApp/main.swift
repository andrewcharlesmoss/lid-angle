import AppKit
import Foundation
import IOKit.hid

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate, NSMenuDelegate {
    private var window: NSWindow!
    private var controller: LidAngleViewController!
    private var menuBarDisplayMenuItem: NSMenuItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)

        controller = LidAngleViewController()
        configureMainMenu()
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 430),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Lid Angle"
        window.minSize = NSSize(width: 560, height: 430)
        window.maxSize = NSSize(width: 560, height: 430)
        window.contentViewController = controller
        window.delegate = self
        window.centreOnMainScreen()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            showWindow()
        }
        return true
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        sender.orderOut(nil)
        return false
    }

    func applicationWillTerminate(_ notification: Notification) {
        controller.stop()
    }

    private func showWindow() {
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func configureMainMenu() {
        let mainMenu = NSMenu()
        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)

        let appMenu = NSMenu(title: "Lid Angle")
        appMenu.delegate = self
        appMenuItem.submenu = appMenu

        appMenu.addItem(NSMenuItem(title: "About Lid Angle", action: #selector(showAboutPanel), keyEquivalent: ""))
        appMenu.addItem(.separator())
        appMenu.addItem(NSMenuItem(title: "Show Lid Angle", action: #selector(showWindowFromAppMenu), keyEquivalent: ""))

        menuBarDisplayMenuItem = NSMenuItem(title: "Enable Menu Bar Display", action: #selector(toggleMenuBarDisplayFromAppMenu), keyEquivalent: "")
        appMenu.addItem(menuBarDisplayMenuItem)

        appMenu.addItem(.separator())
        appMenu.addItem(NSMenuItem(title: "Support Lid Angle", action: #selector(openSupportPage), keyEquivalent: ""))
        appMenu.addItem(NSMenuItem(title: "GitHub Page", action: #selector(openGitHubPage), keyEquivalent: ""))
        appMenu.addItem(.separator())
        appMenu.addItem(NSMenuItem(title: "Quit Lid Angle", action: #selector(quitFromAppMenu), keyEquivalent: "q"))
        appMenu.items.forEach { $0.target = self }

        NSApp.mainMenu = mainMenu
    }

    func menuWillOpen(_ menu: NSMenu) {
        let isEnabled = controller.isMenuBarDisplayEnabled
        menuBarDisplayMenuItem.title = isEnabled ? "Disable Menu Bar Display" : "Enable Menu Bar Display"
        menuBarDisplayMenuItem.state = isEnabled ? .on : .off
    }

    @objc private func showAboutPanel() {
        NSApp.orderFrontStandardAboutPanel(options: [
            .applicationVersion: "1.0.6",
            .version: "6",
            NSApplication.AboutPanelOptionKey(rawValue: "Copyright"): "© 2026 Andrew Moss"
        ])
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func showWindowFromAppMenu() {
        showWindow()
    }

    @objc private func toggleMenuBarDisplayFromAppMenu() {
        controller.setMenuBarDisplayEnabled(!controller.isMenuBarDisplayEnabled)
    }

    @objc private func openSupportPage() {
        openURL("https://buymeacoffee.com/andrewmoss")
    }

    @objc private func openGitHubPage() {
        openURL("https://github.com/andrewcharlesmoss/lid-angle")
    }

    @objc private func quitFromAppMenu() {
        NSApp.terminate(nil)
    }

    private func openURL(_ string: String) {
        guard let url = URL(string: string) else {
            return
        }

        NSWorkspace.shared.open(url)
    }
}

private extension NSWindow {
    func centreOnMainScreen() {
        guard let screenFrame = NSScreen.main?.visibleFrame else {
            center()
            return
        }
        let origin = NSPoint(
            x: screenFrame.midX - frame.width / 2,
            y: screenFrame.midY - frame.height / 2
        )
        setFrameOrigin(origin)
    }
}

struct AngleStabiliser {
    private let consistentReadingCount: Int
    private let immediateChangeThreshold: Int
    private(set) var value: Int?
    private var candidate: Int?
    private var candidateCount = 0

    init(consistentReadingCount: Int = 3, immediateChangeThreshold: Int = 2) {
        precondition(consistentReadingCount > 0)
        precondition(immediateChangeThreshold > 0)
        self.consistentReadingCount = consistentReadingCount
        self.immediateChangeThreshold = immediateChangeThreshold
    }

    mutating func update(with reading: Int) -> Int {
        guard let value else {
            self.value = reading
            clearCandidate()
            return reading
        }

        guard reading != value else {
            clearCandidate()
            return value
        }

        if abs(reading - value) >= immediateChangeThreshold {
            self.value = reading
            clearCandidate()
            return reading
        }

        if candidate == reading {
            candidateCount += 1
        } else {
            candidate = reading
            candidateCount = 1
        }

        if candidateCount >= consistentReadingCount {
            self.value = reading
            clearCandidate()
        }

        return self.value ?? reading
    }

    mutating func reset() {
        value = nil
        clearCandidate()
    }

    private mutating func clearCandidate() {
        candidate = nil
        candidateCount = 0
    }
}

final class LidAngleViewController: NSViewController {
    private enum DisplayMode: Int {
        case fromFlat = 0
        case hinge = 1
    }

    private let reader = LidAngleReader()
    private let titleLabel = NSTextField(labelWithString: "MacBook Lid Angle")
    private let referenceLabel = NSTextField(labelWithString: "0° Reference")
    private let controlRow = NSStackView()
    private let optionsRow = NSStackView()
    private let modeControl = NSSegmentedControl(labels: ["Fully Open", "Closed"], trackingMode: .selectOne, target: nil, action: nil)
    private let menuBarCheckbox = NSButton(checkboxWithTitle: "Menu Bar", target: nil, action: nil)
    private let creakCheckbox = NSButton(checkboxWithTitle: "Sound", target: nil, action: nil)
    private let angleLabel = NSTextField(labelWithString: "--")
    private let statusLabel = NSTextField(labelWithString: "Looking for the lid angle sensor...")
    private let visualiser = LidVisualiserView()
    private var statusItem: NSStatusItem?
    private var creakSound: NSSound?
    private var timer: Timer?
    private var titleTopConstraint: NSLayoutConstraint!
    private var visualiserTopConstraint: NSLayoutConstraint!
    private var visualiserWidthConstraint: NSLayoutConstraint!
    private var visualiserHeightConstraint: NSLayoutConstraint!
    private var angleTopConstraint: NSLayoutConstraint!
    private var statusTopConstraint: NSLayoutConstraint!
    private var modeTopConstraint: NSLayoutConstraint!
    private var modeWidthConstraint: NSLayoutConstraint!
    private var angleStabiliser = AngleStabiliser()
    private var lastSensorAngle: Int?
    private var lastCreakAngle: Int?
    private var lastCreakTime: TimeInterval = 0

    override func loadView() {
        view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor

        titleLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        titleLabel.alignment = .center
        titleLabel.textColor = .labelColor

        referenceLabel.font = .systemFont(ofSize: 11, weight: .medium)
        referenceLabel.alignment = .center
        referenceLabel.textColor = .secondaryLabelColor

        modeControl.selectedSegment = DisplayMode.fromFlat.rawValue
        modeControl.target = self
        modeControl.action = #selector(displayModeChanged)
        modeControl.setImage(ModeIcon.closed, forSegment: DisplayMode.hinge.rawValue)
        modeControl.setImage(ModeIcon.flat, forSegment: DisplayMode.fromFlat.rawValue)
        modeControl.setImageScaling(.scaleProportionallyDown, forSegment: DisplayMode.hinge.rawValue)
        modeControl.setImageScaling(.scaleProportionallyDown, forSegment: DisplayMode.fromFlat.rawValue)
        modeControl.setToolTip("Show 0 degrees when the lid is closed", forSegment: DisplayMode.hinge.rawValue)
        modeControl.setToolTip("Show 0 degrees when the lid is fully open", forSegment: DisplayMode.fromFlat.rawValue)
        modeControl.setWidth(112, forSegment: DisplayMode.hinge.rawValue)
        modeControl.setWidth(138, forSegment: DisplayMode.fromFlat.rawValue)
        modeControl.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        menuBarCheckbox.target = self
        menuBarCheckbox.action = #selector(menuBarDisplayChanged)
        menuBarCheckbox.toolTip = "Show or hide the live angle in the menu bar"
        menuBarCheckbox.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        creakCheckbox.target = self
        creakCheckbox.action = #selector(creakSoundChanged)
        creakCheckbox.toolTip = "Play a short sound when the lid angle changes"
        creakCheckbox.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        optionsRow.orientation = .horizontal
        optionsRow.alignment = .centerY
        optionsRow.spacing = 12
        optionsRow.distribution = .gravityAreas
        optionsRow.addArrangedSubview(menuBarCheckbox)
        optionsRow.addArrangedSubview(creakCheckbox)

        controlRow.orientation = .vertical
        controlRow.alignment = .centerX
        controlRow.spacing = 6
        controlRow.distribution = .gravityAreas
        controlRow.addArrangedSubview(referenceLabel)
        controlRow.addArrangedSubview(modeControl)
        controlRow.addArrangedSubview(optionsRow)

        angleLabel.font = .monospacedDigitSystemFont(ofSize: 72, weight: .bold)
        angleLabel.alignment = .center
        angleLabel.textColor = .labelColor
        angleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        statusLabel.font = .systemFont(ofSize: 13, weight: .regular)
        statusLabel.alignment = .center
        statusLabel.textColor = .secondaryLabelColor
        statusLabel.lineBreakMode = .byWordWrapping
        statusLabel.maximumNumberOfLines = 2
        statusLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        visualiser.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        controlRow.translatesAutoresizingMaskIntoConstraints = false
        angleLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(titleLabel)
        view.addSubview(controlRow)
        view.addSubview(visualiser)
        view.addSubview(angleLabel)
        view.addSubview(statusLabel)

        titleTopConstraint = titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 14)
        modeTopConstraint = controlRow.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8)
        modeWidthConstraint = modeControl.widthAnchor.constraint(equalToConstant: 250)
        visualiserTopConstraint = visualiser.topAnchor.constraint(equalTo: controlRow.bottomAnchor, constant: 20)
        visualiserWidthConstraint = visualiser.widthAnchor.constraint(equalToConstant: 260)
        visualiserHeightConstraint = visualiser.heightAnchor.constraint(equalToConstant: 122)
        angleTopConstraint = angleLabel.topAnchor.constraint(equalTo: visualiser.bottomAnchor, constant: 16)
        statusTopConstraint = statusLabel.topAnchor.constraint(equalTo: angleLabel.bottomAnchor, constant: 14)

        NSLayoutConstraint.activate([
            titleTopConstraint,
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            modeTopConstraint,
            controlRow.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            modeWidthConstraint,

            visualiserTopConstraint,
            visualiser.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: -18),
            visualiser.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, constant: -48),
            visualiserWidthConstraint,
            visualiserHeightConstraint,

            angleTopConstraint,
            angleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            angleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            statusTopConstraint,
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            statusLabel.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -20)
        ])
    }

    override func viewDidLayout() {
        super.viewDidLayout()
        updateResponsiveLayout()
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        start()
    }

    func start() {
        update()
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.update()
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        reader.close()
        removeStatusItem()
    }

    var isMenuBarDisplayEnabled: Bool {
        menuBarCheckbox.state == .on
    }

    func setMenuBarDisplayEnabled(_ enabled: Bool) {
        menuBarCheckbox.state = enabled ? .on : .off
        menuBarDisplayChanged()
    }

    @objc private func displayModeChanged() {
        updateDisplayedAngle()
    }

    @objc private func menuBarDisplayChanged() {
        if menuBarCheckbox.state == .on {
            createStatusItemIfNeeded()
        } else {
            removeStatusItem()
        }
        updateMenuBarItem()
    }

    @objc private func creakSoundChanged() {
        lastCreakAngle = lastSensorAngle
        if creakCheckbox.state == .on {
            loadCreakSoundIfNeeded()
        } else {
            creakSound?.stop()
        }
    }

    private func update() {
        switch reader.readAngle() {
        case .success(let angle):
            if angle == 1 {
                angleStabiliser.reset()
                lastSensorAngle = nil
                angleLabel.stringValue = "Docked"
                statusLabel.stringValue = "The sensor reports docked mode."
                visualiser.angle = 0
                updateMenuBarItem(title: "Docked", tooltip: "The lid angle sensor reports docked mode.")
                return
            }

            let clamped = max(0, min(angle, 180))
            let stabilised = angleStabiliser.update(with: clamped)
            playCreakIfNeeded(for: stabilised)
            lastSensorAngle = stabilised
            visualiser.angle = CGFloat(stabilised)
            updateDisplayedAngle()

        case .failure(let error):
            angleStabiliser.reset()
            lastSensorAngle = nil
            angleLabel.stringValue = "--"
            statusLabel.stringValue = error.userMessage
            visualiser.angle = 105
            updateMenuBarItem(title: "--°", tooltip: error.userMessage)
        }
    }

    private func updateDisplayedAngle() {
        guard let sensorAngle = lastSensorAngle else {
            return
        }

        let mode = DisplayMode(rawValue: modeControl.selectedSegment) ?? .fromFlat
        switch mode {
        case .hinge:
            angleLabel.stringValue = "\(sensorAngle)°"
            statusLabel.stringValue = "0° is closed.\nLarger numbers mean the lid is more open."
            updateMenuBarItem(title: "Closed \(sensorAngle)°", tooltip: "0 degrees is closed.")
        case .fromFlat:
            let fromFlat = max(0, 180 - sensorAngle)
            angleLabel.stringValue = "\(fromFlat)°"
            statusLabel.stringValue = "0° is fully open.\nLarger numbers mean the lid is closing."
            updateMenuBarItem(title: "Open \(fromFlat)°", tooltip: "0 degrees is fully open.")
        }

    }

    private func loadCreakSoundIfNeeded() {
        guard creakSound == nil else {
            return
        }

        guard let url = Bundle.main.url(forResource: "DoorCreak", withExtension: "wav") else {
            statusLabel.stringValue = "Sound file is missing from the app bundle."
            return
        }

        creakSound = NSSound(contentsOf: url, byReference: false)
        creakSound?.volume = 0.55
    }

    private func playCreakIfNeeded(for sensorAngle: Int) {
        guard creakCheckbox.state == .on else {
            lastCreakAngle = sensorAngle
            return
        }

        loadCreakSoundIfNeeded()

        guard let previousAngle = lastCreakAngle else {
            lastCreakAngle = sensorAngle
            return
        }

        let delta = abs(sensorAngle - previousAngle)
        let now = Date.timeIntervalSinceReferenceDate
        guard delta >= 2, now - lastCreakTime > 0.45 else {
            return
        }

        creakSound?.stop()
        creakSound?.currentTime = 0
        creakSound?.play()
        lastCreakAngle = sensorAngle
        lastCreakTime = now
    }

    private func createStatusItemIfNeeded() {
        guard statusItem == nil else {
            return
        }

        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.font = .monospacedDigitSystemFont(ofSize: 13, weight: .semibold)

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Show Lid Angle", action: #selector(showWindowFromMenuBar), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit Lid Angle", action: #selector(quitFromMenuBar), keyEquivalent: "q"))
        menu.items.forEach { $0.target = self }
        item.menu = menu

        statusItem = item
    }

    private func removeStatusItem() {
        guard let statusItem else {
            return
        }

        NSStatusBar.system.removeStatusItem(statusItem)
        self.statusItem = nil
    }

    private func updateMenuBarItem(title: String? = nil, tooltip: String? = nil) {
        guard menuBarCheckbox.state == .on else {
            return
        }

        createStatusItemIfNeeded()
        statusItem?.button?.title = title ?? angleLabel.stringValue
        statusItem?.button?.toolTip = tooltip ?? statusLabel.stringValue
    }

    @objc private func showWindowFromMenuBar() {
        guard let window = view.window else {
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func quitFromMenuBar() {
        NSApp.terminate(nil)
    }

    private func updateResponsiveLayout() {
        let width = max(view.bounds.width, 1)
        let scale = min(max(width / 420, 0.86), 1.35)

        titleLabel.font = .systemFont(ofSize: 20 * scale, weight: .semibold)
        angleLabel.font = .monospacedDigitSystemFont(ofSize: 72 * scale, weight: .bold)
        statusLabel.font = .systemFont(ofSize: 13 * scale, weight: .regular)
        referenceLabel.font = .systemFont(ofSize: 11 * scale, weight: .medium)
        modeControl.font = .systemFont(ofSize: 12 * scale, weight: .medium)
        menuBarCheckbox.font = .systemFont(ofSize: 12 * scale, weight: .medium)
        creakCheckbox.font = .systemFont(ofSize: 12 * scale, weight: .medium)

        titleTopConstraint.constant = 10 * scale
        modeTopConstraint.constant = 8 * scale
        visualiserTopConstraint.constant = -14 * scale
        angleTopConstraint.constant = 8 * scale
        statusTopConstraint.constant = 16 * scale
        modeWidthConstraint.constant = 250
        visualiserWidthConstraint.constant = min(max(width * 0.72, 235), 560)
        visualiserHeightConstraint.constant = min(max(width * 0.38, 168), 225)
        visualiser.strokeScale = scale
    }
}

final class LidVisualiserView: NSView {
    var angle: CGFloat = 105 {
        didSet { needsDisplay = true }
    }
    var strokeScale: CGFloat = 1 {
        didSet { needsDisplay = true }
    }

    override var isFlipped: Bool { true }

    override func hitTest(_ point: NSPoint) -> NSView? {
        nil
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let bounds = bounds.insetBy(dx: 12 * strokeScale, dy: 12 * strokeScale)
        let lineWidth = max(9, 12 * strokeScale)
        let baseHeight = max(12, 16 * strokeScale)
        let hingeRadius = max(6, 7 * strokeScale)
        let screenLength = max(90 * strokeScale, min(bounds.height * 0.82, bounds.width * 0.46))
        let hingeInset = min(
            max(screenLength * 0.9 + lineWidth, bounds.width * 0.28),
            bounds.width - screenLength - lineWidth
        )
        let hinge = CGPoint(
            x: bounds.minX + hingeInset,
            y: bounds.maxY - max(24, 28 * strokeScale)
        )
        let radians = angle * .pi / 180
        let xDirection = cos(radians)
        let yDirection = sin(radians)
        let end = CGPoint(
            x: hinge.x + xDirection * screenLength,
            y: hinge.y - yDirection * screenLength
        )

        let baseTail = max(6, 8 * strokeScale)
        let baseWidth = min(screenLength + baseTail, bounds.maxX - hinge.x - lineWidth * 0.35)
        let baseRect = NSRect(
            x: hinge.x,
            y: hinge.y,
            width: baseWidth,
            height: baseHeight
        )

        NSColor.separatorColor.setFill()
        NSBezierPath(roundedRect: baseRect, xRadius: 4 * strokeScale, yRadius: 4 * strokeScale).fill()

        NSColor.controlAccentColor.setFill()
        NSBezierPath(
            ovalIn: NSRect(
                x: hinge.x - hingeRadius,
                y: hinge.y - hingeRadius,
                width: hingeRadius * 2,
                height: hingeRadius * 2
            )
        ).fill()

        let lidPath = NSBezierPath()
        lidPath.lineWidth = lineWidth
        lidPath.lineCapStyle = .round
        NSColor.labelColor.withAlphaComponent(0.88).setStroke()
        lidPath.move(to: hinge)
        lidPath.line(to: end)
        lidPath.stroke()

        let highlightPath = NSBezierPath()
        highlightPath.lineWidth = max(2, 3.5 * strokeScale)
        highlightPath.lineCapStyle = .round
        NSColor.white.withAlphaComponent(0.28).setStroke()
        let inset = min(screenLength * 0.14, 18 * strokeScale)
        let innerStart = CGPoint(
            x: hinge.x + xDirection * inset,
            y: hinge.y - yDirection * inset
        )
        let innerEnd = CGPoint(
            x: hinge.x + xDirection * (screenLength - inset),
            y: hinge.y - yDirection * (screenLength - inset)
        )
        highlightPath.move(to: innerStart)
        highlightPath.line(to: innerEnd)
        highlightPath.stroke()
    }
}

@MainActor
enum ModeIcon {
    static let closed = makeIcon(kind: .closed)
    static let flat = makeIcon(kind: .flat)

    private enum Kind {
        case closed
        case flat
    }

    private static func makeIcon(kind: Kind) -> NSImage {
        let size = NSSize(width: 28, height: 18)
        let image = NSImage(size: size)
        image.lockFocus()
        defer { image.unlockFocus() }

        NSColor.black.setStroke()
        NSColor.black.setFill()

        switch kind {
        case .closed:
            let base = NSBezierPath()
            base.lineWidth = 2.2
            base.lineCapStyle = .round
            base.move(to: NSPoint(x: 5, y: 6))
            base.line(to: NSPoint(x: 23, y: 6))
            base.stroke()

            let lid = NSBezierPath()
            lid.lineWidth = 2.2
            lid.lineCapStyle = .round
            lid.move(to: NSPoint(x: 6, y: 9))
            lid.line(to: NSPoint(x: 22, y: 9))
            lid.stroke()

        case .flat:
            let base = NSBezierPath()
            base.lineWidth = 2.2
            base.lineCapStyle = .round
            base.move(to: NSPoint(x: 14, y: 7))
            base.line(to: NSPoint(x: 24, y: 7))
            base.stroke()

            let lid = NSBezierPath()
            lid.lineWidth = 2.2
            lid.lineCapStyle = .round
            lid.move(to: NSPoint(x: 4, y: 7))
            lid.line(to: NSPoint(x: 14, y: 7))
            lid.stroke()

            let hinge = NSBezierPath(ovalIn: NSRect(x: 12.2, y: 5.2, width: 3.6, height: 3.6))
            hinge.fill()
        }

        image.isTemplate = true
        return image
    }
}

enum LidAngleReadError: Error {
    case noSensor
    case openFailed
    case readFailed

    var userMessage: String {
        switch self {
        case .noSensor:
            "No compatible lid angle sensor was found. This requires a MacBook that exposes the compatible HID lid angle sensor."
        case .openFailed:
            "The lid angle sensor was found, but macOS would not let this app open it."
        case .readFailed:
            "The lid angle sensor did not return a readable feature report."
        }
    }
}

final class LidAngleReader {
    private var device: IOHIDDevice?
    private var isOpen = false

    deinit {
        close()
    }

    func readAngle() -> Result<Int, LidAngleReadError> {
        do {
            let device = try openedDevice()
            var report = [UInt8](repeating: 0, count: 8)
            var length = report.count

            let result = IOHIDDeviceGetReport(
                device,
                kIOHIDReportTypeFeature,
                CFIndex(1),
                &report,
                &length
            )

            guard result == kIOReturnSuccess, length >= 3 else {
                return .failure(.readFailed)
            }

            let low = Int(report[1])
            let high = Int(report[2]) << 8
            return .success(high | low)
        } catch let error as LidAngleReadError {
            return .failure(error)
        } catch {
            return .failure(.readFailed)
        }
    }

    func close() {
        if let device, isOpen {
            IOHIDDeviceClose(device, IOOptionBits(kIOHIDOptionsTypeNone))
        }
        device = nil
        isOpen = false
    }

    private func openedDevice() throws -> IOHIDDevice {
        if let device, isOpen {
            return device
        }

        guard let foundDevice = findSensor() else {
            throw LidAngleReadError.noSensor
        }

        let result = IOHIDDeviceOpen(foundDevice, IOOptionBits(kIOHIDOptionsTypeNone))
        guard result == kIOReturnSuccess else {
            throw LidAngleReadError.openFailed
        }

        device = foundDevice
        isOpen = true
        return foundDevice
    }

    private func findSensor() -> IOHIDDevice? {
        let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))

        let matching: [String: Any] = [
            kIOHIDVendorIDKey: 0x05AC,
            kIOHIDProductIDKey: 0x8104,
            kIOHIDDeviceUsagePageKey: 0x0020,
            kIOHIDDeviceUsageKey: 0x008A
        ]

        IOHIDManagerSetDeviceMatching(manager, matching as CFDictionary)
        guard IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone)) == kIOReturnSuccess else {
            return nil
        }
        defer {
            IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        }

        guard let devices = IOHIDManagerCopyDevices(manager) as? Set<IOHIDDevice> else {
            return nil
        }

        for candidate in devices {
            guard IOHIDDeviceOpen(candidate, IOOptionBits(kIOHIDOptionsTypeNone)) == kIOReturnSuccess else {
                continue
            }

            var report = [UInt8](repeating: 0, count: 8)
            var length = report.count
            let result = IOHIDDeviceGetReport(
                candidate,
                kIOHIDReportTypeFeature,
                CFIndex(1),
                &report,
                &length
            )
            IOHIDDeviceClose(candidate, IOOptionBits(kIOHIDOptionsTypeNone))

            if result == kIOReturnSuccess, length >= 3 {
                return candidate
            }
        }

        return nil
    }
}

private func printOneShotReading() {
    let reader = LidAngleReader()
    switch reader.readAngle() {
    case .success(let angle):
        if angle == 1 {
            print("Docked")
        } else {
            print("Lid angle: \(angle) degrees")
        }
    case .failure(let error):
        print("Lid angle unavailable: \(error.userMessage)")
    }
}

@main
struct LidAngleApplication {
    static func main() {
        if CommandLine.arguments.contains("--once") {
            printOneShotReading()
            return
        }

        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }
}
