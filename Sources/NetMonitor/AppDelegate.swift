import AppKit
import ServiceManagement

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let interval: TimeInterval = 1.0

    private var statusItem: NSStatusItem!
    private var timer: Timer?
    private var last: Counters?
    private var lastTime = Date()

    private let totalInItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
    private let totalOutItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
    private let loginItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLogin), keyEquivalent: "")

    private let font = NSFont.monospacedDigitSystemFont(ofSize: 9, weight: .medium)

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.menu = buildMenu()
        render(up: 0, down: 0)

        last = NetworkStats.read()
        lastTime = Date()
        let timer = Timer(timeInterval: interval, repeats: true) { [weak self] _ in self?.tick() }
        RunLoop.main.add(timer, forMode: .common) // keep updating while the menu is open
        self.timer = timer
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()
        menu.delegate = self
        totalInItem.isEnabled = false
        totalOutItem.isEnabled = false
        menu.addItem(totalInItem)
        menu.addItem(totalOutItem)
        menu.addItem(.separator())
        loginItem.target = self
        menu.addItem(loginItem)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit NetMonitor", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        updateMenuInfo()
        return menu
    }

    func menuWillOpen(_ menu: NSMenu) {
        updateMenuInfo()
    }

    private func updateMenuInfo() {
        let c = last ?? Counters(rx: 0, tx: 0)
        totalInItem.title = "Received since boot: \(formatBytes(Double(c.rx)))"
        totalOutItem.title = "Sent since boot: \(formatBytes(Double(c.tx)))"
        loginItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
    }

    private func tick() {
        guard let now = NetworkStats.read() else { return }
        let t = Date()
        let dt = max(t.timeIntervalSince(lastTime), 0.001)
        if let prev = last {
            // Counters can drop when an interface goes away; treat that as zero traffic.
            let down = now.rx >= prev.rx ? Double(now.rx - prev.rx) / dt : 0
            let up = now.tx >= prev.tx ? Double(now.tx - prev.tx) / dt : 0
            render(up: up, down: down)
        }
        last = now
        lastTime = t
        updateMenuInfo()
    }

    /// Draws the two-line "↑ / ↓" label into a template image so it adapts to light/dark menu bars.
    private func render(up: Double, down: Double) {
        let lines = ["↑ " + formatRate(up), "↓ " + formatRate(down)]
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: NSColor.black]

        // Fixed width based on the widest plausible value, so the menu bar doesn't jitter.
        let widest = ("↓ 888.8 KB/s" as NSString).size(withAttributes: attrs).width
        let height = NSStatusBar.system.thickness
        let lineHeight = ceil(font.ascender - font.descender)
        let size = NSSize(width: ceil(widest) + 2, height: height)

        let image = NSImage(size: size, flipped: false) { _ in
            let top = (height + lineHeight * 2) / 2
            for (i, line) in lines.enumerated() {
                let str = line as NSString
                let w = str.size(withAttributes: attrs).width
                let y = top - lineHeight * CGFloat(i + 1)
                str.draw(at: NSPoint(x: size.width - w - 1, y: y), withAttributes: attrs)
            }
            return true
        }
        image.isTemplate = true
        statusItem.button?.image = image
        statusItem.button?.toolTip = "Up \(formatRate(up)) · Down \(formatRate(down))"
    }

    @objc private func toggleLogin() {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            let alert = NSAlert(error: error)
            alert.runModal()
        }
        updateMenuInfo()
    }
}
