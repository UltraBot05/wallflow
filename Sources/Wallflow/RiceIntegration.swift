import AppKit
import ApplicationServices

func checkRiceDependencies() throws {
    // Both integrations are required for the Rice edition.
    let ghosttyKnown = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.mitchellh.ghostty") != nil
    let ghosttyPaths = ["/Applications/Ghostty.app", home.appendingPathComponent("Applications/Ghostty.app").path]
    guard ghosttyKnown || ghosttyPaths.contains(where: { FileManager.default.fileExists(atPath: $0) }) else {
        throw NSError(domain: "WallflowRice", code: 2,
                      userInfo: [NSLocalizedDescriptionKey: "Wallflow Rice requires Ghostty. Install Ghostty before applying wallpapers."])
    }
    // generateTheme checks that Matugen is executable and configured.
}

private func execute(_ executable: String, _ args: [String]) throws -> String {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: executable)
    process.arguments = args
    let err = Pipe()
    process.standardError = err
    process.standardOutput = Pipe()
    try process.run()
    process.waitUntilExit()
    let errorMessage = String(data: err.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
    if process.terminationStatus != 0 {
        throw NSError(domain: "Wallflow", code: Int(process.terminationStatus),
                      userInfo: [NSLocalizedDescriptionKey: errorMessage.isEmpty ? "Command failed: \(executable)" : errorMessage])
    }
    return errorMessage
}

func generateTheme(for path: String, sourceIndex: Int) throws {
    let config = home.appendingPathComponent(".config/matugen/config.toml").path
    guard FileManager.default.fileExists(atPath: config) else {
        throw NSError(domain: "Wallflow", code: 1,
                      userInfo: [NSLocalizedDescriptionKey: "Missing ~/.config/matugen/config.toml. Your existing Matugen setup is needed."])
    }
    var candidates = [home.appendingPathComponent(".cargo/bin/matugen").path,
                      "/opt/homebrew/bin/matugen", "/usr/local/bin/matugen"]
    if let env = ProcessInfo.processInfo.environment["PATH"] {
        candidates += env.split(separator: ":").map { String($0) + "/matugen" }
    }
    guard let binary = candidates.first(where: { FileManager.default.isExecutableFile(atPath: $0) }) else {
        throw NSError(domain: "Wallflow", code: 1,
                      userInfo: [NSLocalizedDescriptionKey: "Matugen binary not found in ~/.cargo/bin or Homebrew."])
    }
    _ = try execute(binary, ["-c", config, "image", path,
                             "--mode", "dark", "--source-color-index", String(sourceIndex)])
}

private func axChildren(_ element: AXUIElement) -> [AXUIElement] {
    var result: CFTypeRef?
    guard AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &result) == .success else { return [] }
    return result as? [AXUIElement] ?? []
}

private func axTitle(_ element: AXUIElement) -> String? {
    var result: CFTypeRef?
    guard AXUIElementCopyAttributeValue(element, kAXTitleAttribute as CFString, &result) == .success else { return nil }
    return result as? String
}

func attemptGhosttyReload() -> String? {
    // Run Accessibility actions in Wallflow itself. Launching /usr/bin/osascript
    // caused macOS to deny the *helper process* even when Wallflow was enabled.
    guard let ghostty = NSWorkspace.shared.runningApplications.first(where: {
        $0.bundleIdentifier == "com.mitchellh.ghostty" || $0.localizedName == "Ghostty"
    }) else { return nil } // Palette will be loaded on Ghostty's next launch.

    // Explicitly inspect the permission that belongs to this currently running binary.
    // Rebuilding with ad-hoc signing may invalidate an earlier TCC grant.
    guard AXIsProcessTrusted() else {
        return "The wallpaper and Matugen palette were applied, but Wallflow Rice cannot reload Ghostty yet. macOS has not granted Accessibility access to this build. Quit Wallflow Rice. Go to System Settings > Privacy & Security > Accessibility. Add the exact Wallflow Rice.app you launched, then enable it and reopen the app. For a development build, choose the app inside your project's dist folder. If an old Wallflow Rice entry is present, remove it first. Approval for Wallflow.app or Wallflow Core.app does not authorize Wallflow Rice.app."
    }
    let app = AXUIElementCreateApplication(ghostty.processIdentifier)
    var barValue: CFTypeRef?
    let barStatus = AXUIElementCopyAttributeValue(app, kAXMenuBarAttribute as CFString, &barValue)
    guard barStatus == .success, let bar = barValue else {
        return "Ghostty reload: cannot access its menu bar (AX error \(barStatus.rawValue))."
    }
    let menuBar = bar as! AXUIElement
    guard let ghosttyMenu = axChildren(menuBar).first(where: { axTitle($0) == "Ghostty" }) else {
        return "Ghostty reload: application menu not found."
    }
    // Menus may be lazy. Open the app menu to populate its children.
    _ = AXUIElementPerformAction(ghosttyMenu, kAXPressAction as CFString)
    let menuItems = axChildren(ghosttyMenu).flatMap { axChildren($0) }
    guard let reload = menuItems.first(where: { axTitle($0) == "Reload Configuration" }) else {
        return "Ghostty reload: 'Reload Configuration' menu item not found."
    }
    let result = AXUIElementPerformAction(reload, kAXPressAction as CFString)
    guard result == .success else {
        return "Ghostty reload: menu action failed (AX error \(result.rawValue))."
    }
    return nil
}

