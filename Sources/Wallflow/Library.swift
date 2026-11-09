import AppKit
import SwiftUI

@MainActor
final class Library: ObservableObject {
    @Published var libraryRoot: URL?
    @Published var items: [Wallpaper] = []
    @Published var analyses: [String: ImageAnalysis] = [:]
    @Published var favorites: Set<String> = []
    @Published var current = ""
    @Published var selected: String = ""
    @Published var query = ""
    @Published var category = "All categories"
    @Published var hue = "All"
    @Published var darkOnly = false
    @Published var favoritesOnly = false
    @Published var indexing = false
    @Published var applying = false
    @Published var status = "Choose a wallpaper to preview and apply."
    @Published var error = false
    @Published var sourceIndex = 0

    init() {
        let favFile = wallflowConfig.appendingPathComponent("favorites.json")
        if let data = try? Data(contentsOf: favFile), let list = try? JSONDecoder().decode([String].self, from: data) {
            favorites = Set(list)
        }
        let currentFile = wallflowConfig.appendingPathComponent("current.json")
        if let data = try? Data(contentsOf: currentFile),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let id = json["id"] as? String { current = id }
        let defaults = UserDefaults.standard
        if let path = defaults.string(forKey: "wallflow.libraryRoot"),
           FileManager.default.fileExists(atPath: path) {
            libraryRoot = URL(fileURLWithPath: path, isDirectory: true)
        } else {
            let previous = home.appendingPathComponent("wallpapers", isDirectory: true)
            if FileManager.default.fileExists(atPath: previous.path) { libraryRoot = previous }
        }
        scan()
    }

    var categories: [String] { ["All categories"] + Array(Set(items.map(\.category))).sorted() }
    var selection: Wallpaper? {
        let visible = filtered
        return visible.first(where: { $0.id == selected }) ?? visible.first
    }

    func choose(_ item: Wallpaper) {
        selected = item.id
        sourceIndex = 0
    }

    func moveSelection(by delta: Int) {
        let visible = filtered
        guard !visible.isEmpty else { return }
        let index = visible.firstIndex(where: { $0.id == selected }) ?? 0
        choose(visible[max(0, min(visible.count - 1, index + delta))])
    }
    var filtered: [Wallpaper] {
        let words = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return items.filter { item in
            (category == "All categories" || item.category == category)
            && (words.isEmpty || item.id.localizedCaseInsensitiveContains(words) || item.title.localizedCaseInsensitiveContains(words))
            && (!favoritesOnly || favorites.contains(item.id))
            && (!darkOnly || analyses[item.id]?.isDark == true)
            && (hue == "All" || analyses[item.id]?.hue == hue)
        }
    }

    func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Use This Folder"
        panel.message = "Choose the folder containing your wallpaper images."
        if let folder = libraryRoot { panel.directoryURL = folder }
        if panel.runModal() == .OK, let url = panel.url {
            libraryRoot = url
            UserDefaults.standard.set(url.path, forKey: "wallflow.libraryRoot")
            category = "All categories"
            favoritesOnly = false
            hue = "All"
            selected = ""
            scan()
        }
    }

    var folderName: String { libraryRoot?.lastPathComponent ?? "No folder selected" }

    func scan() {
        guard let wallpapersRoot = libraryRoot else {
            items = []
            analyses = [:]
            selected = ""
            indexing = false
            error = false
            status = "Choose a wallpaper folder to get started."
            return
        }
        let manager = FileManager.default
        guard let enumerator = manager.enumerator(at: wallpapersRoot,
                includingPropertiesForKeys: [.isRegularFileKey, .isSymbolicLinkKey, .fileSizeKey, .contentModificationDateKey],
                options: [.skipsHiddenFiles]) else {
            error = true
            status = "Wallpaper folder unavailable. Choose another folder."
            return
        }
        let extensions: Set<String> = ["jpg", "jpeg", "png", "webp", "heic", "tif", "tiff"]
        var found: [Wallpaper] = []
        for case let url as URL in enumerator {
            if !extensions.contains(url.pathExtension.lowercased()) { continue }
            let attr = try? url.resourceValues(forKeys: [.isRegularFileKey, .isSymbolicLinkKey, .fileSizeKey, .contentModificationDateKey])
            if attr?.isRegularFile != true || attr?.isSymbolicLink == true { continue }
            // Avoid indexing extremely large or empty files as wallpapers.
            guard let fileSize = attr?.fileSize,
                  fileSize > 0, fileSize <= 150 * 1024 * 1024 else { continue }
            guard hasUsableWallpaperMetadata(url.path) else { continue }
            let id = String(url.path.dropFirst(wallpapersRoot.path.count + 1))
            let cat = id.contains("/") ? (id.split(separator: "/").first.map(String.init) ?? "Unsorted") : "Unsorted"
            let stamp = "\(attr?.fileSize ?? 0):\(Int(attr?.contentModificationDate?.timeIntervalSince1970 ?? 0))"
            found.append(Wallpaper(id: id, path: url.path, category: cat,
                                   title: url.deletingPathExtension().lastPathComponent.replacingOccurrences(of: "_", with: " ").replacingOccurrences(of: "-", with: " "), stamp: stamp))
        }
        items = found.sorted { $0.id.localizedStandardCompare($1.id) == .orderedAscending }
        if selected.isEmpty || !items.contains(where: { $0.id == selected }) {
            selected = items.first(where: { $0.id == current })?.id ?? items.first?.id ?? ""
        }
        let cacheFile = wallflowConfig.appendingPathComponent("native-index.json")
        let cached = (try? Data(contentsOf: cacheFile)).flatMap { try? JSONDecoder().decode([String: ImageAnalysis].self, from: $0) } ?? [:]
        analyses = cached.filter { key, info in found.contains(where: { $0.id == key && $0.stamp == info.stamp }) }
        let missing = items.filter { analyses[$0.id] == nil }
        if missing.isEmpty { indexing = false; return }
        indexing = true
        let ready = analyses
        Task.detached(priority: .utility) {
            var result = ready
            for chunkStart in stride(from: 0, to: missing.count, by: 24) {
                for item in missing[chunkStart..<min(chunkStart + 24, missing.count)] { result[item.id] = analyze(item) }
                let snapshot = result
                await MainActor.run { self.analyses = snapshot }
            }
            if let data = try? JSONEncoder().encode(result) {
                try? FileManager.default.createDirectory(at: wallflowConfig, withIntermediateDirectories: true)
                try? data.write(to: cacheFile, options: .atomic)
            }
            await MainActor.run { self.indexing = false }
        }
    }

    func toggleFavorite(_ item: Wallpaper) {
        if favorites.contains(item.id) { favorites.remove(item.id) }
        else { favorites.insert(item.id) }
        try? FileManager.default.createDirectory(at: wallflowConfig, withIntermediateDirectories: true)
        if let data = try? JSONEncoder().encode(Array(favorites).sorted()) {
            try? data.write(to: wallflowConfig.appendingPathComponent("favorites.json"), options: .atomic)
        }
    }

    func apply(_ item: Wallpaper) {
        guard !applying else { return }
        guard isDecodableWallpaper(item.path) else {
            error = true
            status = "This wallpaper is missing, unreadable, or has changed. Refresh the library and choose another image."
            return
        }
        applying = true
        error = false
        status = "Applying wallpaper..."
        defer { applying = false }
        do {
            for screen in NSScreen.screens {
                try NSWorkspace.shared.setDesktopImageURL(
                    URL(fileURLWithPath: item.path), for: screen, options: [:])
            }
            current = item.id
            try? FileManager.default.createDirectory(at: wallflowConfig, withIntermediateDirectories: true)
            let record: [String: Any] = ["id": item.id]
            if let data = try? JSONSerialization.data(withJSONObject: record, options: [.prettyPrinted]) {
                try? data.write(to: wallflowConfig.appendingPathComponent("current.json"), options: .atomic)
            }
            status = "Wallpaper applied."
        } catch {
            self.error = true
            status = "Could not apply wallpaper: \(error.localizedDescription)"
        }
    }
}

