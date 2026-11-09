import AppKit
import Darwin
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

// Matugen is a user-installed executable. Avoid shells and inherited PATH search.
// A private, unlinked temporary file captures bounded diagnostic output without
// deadlocking the child if it writes extensively to stderr or stdout.
// Matugen can write ANSI formatting, full Rust backtraces and local file paths.
// Display only a bounded, single-line diagnostic in the application UI.
private func displayableMatugenError(_ raw: String) -> String {
    let withoutANSI = raw.replacingOccurrences(
        of: "\u{001B}\\[[0-9;]*[A-Za-z]", with: "", options: .regularExpression)
    let lines = withoutANSI.components(separatedBy: .newlines)
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    guard let first = lines.first(where: { !$0.isEmpty }) else {
        return "Matugen exited unsuccessfully."
    }
    let safe = first.replacingOccurrences(of: "[[:cntrl:]]", with: "", options: .regularExpression)
    if safe.contains("/Users/") || safe.contains("/home/") {
        return "Matugen failed. Check your configuration and the selected image."
    }
    return String(safe.prefix(240))
}

private func execute(_ executable: String, _ args: [String]) throws -> String {
    var template = Array(FileManager.default.temporaryDirectory
        .appendingPathComponent("wallflow-matugen-XXXXXX").path.utf8CString)
    let descriptor = template.withUnsafeMutableBufferPointer { buffer in
        mkstemp(buffer.baseAddress!)
    }
    guard descriptor >= 0 else {
        throw NSError(domain: "WallflowRice", code: 3,
                      userInfo: [NSLocalizedDescriptionKey: "Could not create private Matugen output log."])
    }
    _ = template.withUnsafeBufferPointer { buffer in unlink(buffer.baseAddress!) }
    let log = FileHandle(fileDescriptor: descriptor, closeOnDealloc: true)
    defer { log.closeFile() }

    let process = Process()
    process.executableURL = URL(fileURLWithPath: executable)
    process.arguments = args
    process.standardOutput = FileHandle.nullDevice
    process.standardError = log

    let completed = DispatchSemaphore(value: 0)
    process.terminationHandler = { _ in completed.signal() }
    try process.run()

    let finishedInTime = completed.wait(timeout: .now() + .seconds(45)) == .success
    if !finishedInTime {
        if process.isRunning { process.terminate() }
        if completed.wait(timeout: .now() + .seconds(2)) == .timedOut && process.isRunning {
            _ = kill(process.processIdentifier, SIGKILL)
            _ = completed.wait(timeout: .now() + .seconds(3))
        }
    }

    log.seek(toFileOffset: 0)
    let errorMessage = String(data: log.readData(ofLength: 8_192), encoding: .utf8)?
        .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    guard finishedInTime else {
        throw NSError(domain: "WallflowRice", code: 4,
                      userInfo: [NSLocalizedDescriptionKey: "Matugen did not finish within 45 seconds and was stopped."])
    }
    guard process.terminationReason == .exit && process.terminationStatus == 0 else {
        throw NSError(domain: "WallflowRice", code: Int(process.terminationStatus),
                      userInfo: [NSLocalizedDescriptionKey:
                          displayableMatugenError(errorMessage)])
    }
    return errorMessage
}

func generateTheme(for path: String, sourceIndex: Int) throws {
    let config = home.appendingPathComponent(".config/matugen/config.toml").path
    guard FileManager.default.fileExists(atPath: config) else {
        throw NSError(domain: "Wallflow", code: 1,
                      userInfo: [NSLocalizedDescriptionKey: "Missing ~/.config/matugen/config.toml. Your existing Matugen setup is needed."])
    }
    // Search only documented installation locations. Do not resolve executables
    // through an inherited PATH, which could redirect execution unexpectedly.
    let candidates = [home.appendingPathComponent(".cargo/bin/matugen").path,
                      home.appendingPathComponent(".local/bin/matugen").path,
                      "/opt/homebrew/bin/matugen", "/usr/local/bin/matugen"]
    guard let binary = candidates.first(where: { FileManager.default.isExecutableFile(atPath: $0) }) else {
        throw NSError(domain: "WallflowRice", code: 1,
                      userInfo: [NSLocalizedDescriptionKey: "Matugen not found in the supported Cargo, local, or Homebrew paths."])
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
        $0.bundleIdentifier == "com.mitchellh.ghostty"
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
    guard CFGetTypeID(bar) == AXUIElementGetTypeID() else {
        return "Ghostty reload: invalid menu bar element."
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

