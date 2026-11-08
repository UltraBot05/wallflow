import AppKit
import SwiftUI

// Native macOS window, adaptive gallery and system inspector.
// Native NavigationSplitView, toolbar and inspector own the platform's Liquid Glass.
// Do not simulate a second titlebar or force NSWindow floating/fullscreen behavior.

private struct WallpaperThumbnail: View {
    let path: String
    let fit: Bool
    @StoredState private var image: NSImage?

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(nsColor: .controlBackgroundColor)
                if let image {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: fit ? .fit : .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                } else {
                    Image(systemName: "photo.on.rectangle")
                        .font(.title2).foregroundStyle(.secondary)
                }
            }
        }
        .task(id: path) {
            image = await Task.detached(priority: .utility) {
                ThumbnailCache.shared.load(path)
            }.value
        }
    }
}

private struct WallpaperCard: View {
    let wallpaper: Wallpaper
    let selected: Bool
    let active: Bool
    let favored: Bool
    let select: () -> Void
    let favorite: () -> Void
    let apply: () -> Void
    @StoredState private var hovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            WallpaperThumbnail(path: wallpaper.path, fit: false)
                .aspectRatio(1.55, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(alignment: .topTrailing) {
                    Button(action: favorite) {
                        Image(systemName: favored ? "heart.fill" : "heart")
                            .foregroundStyle(favored ? .pink : .primary)
                            .frame(width: 30, height: 30)
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.circle)
                    .padding(9)
                    .help(favored ? "Remove from favorites" : "Save to favorites")
                }
                .overlay(alignment: .topLeading) {
                    if active {
                        Label("On desktop", systemImage: "checkmark.circle.fill")
                            .font(.caption2.weight(.semibold))
                            .padding(7)
                            .background(.regularMaterial, in: Capsule())
                            .padding(9)
                    }
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(selected ? Color.accentColor : .clear, lineWidth: 3)
                }
            HStack(spacing: 5) {
                Text(wallpaper.title)
                    .font(.caption.weight(selected ? .semibold : .medium))
                    .lineLimit(1)
                Spacer(minLength: 0)
                if hovering { Image(systemName: "arrow.up.left.and.arrow.down.right").foregroundStyle(.tertiary) }
            }
            .padding(.horizontal, 2)
        }
        .contentShape(Rectangle())
        .onTapGesture(count: 2, perform: apply)
        .onTapGesture(perform: select)
        .onHover { hovering = $0 }
        .contextMenu {
            Button("Set as Wallpaper", systemImage: "desktopcomputer", action: apply)
            Button(favored ? "Remove Favorite" : "Add Favorite", systemImage: "heart", action: favorite)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(wallpaper.title)
        .accessibilityAddTraits(.isButton)
    }
}

private struct WallflowView: View {
    @StateObject private var library = Library()
    @StoredState private var inspectorVisible = true
    private let hues = ["All", "Red", "Orange", "Yellow", "Green", "Cyan", "Blue", "Purple", "Pink", "Mono"]

    private func color(for hue: String) -> Color {
        switch hue {
        case "Red": return .red
        case "Orange": return .orange
        case "Yellow": return .yellow
        case "Green": return .green
        case "Cyan": return .cyan
        case "Blue": return .blue
        case "Purple": return .purple
        case "Pink": return .pink
        case "Mono": return .gray
        default: return .primary
        }
    }

    private func sidebarItem(_ label: String, symbol: String, count: Int, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Label(label, systemImage: symbol)
                    .lineLimit(1)
                Spacer(minLength: 4)
                Text("\(count)")
                    .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(active ? Color.accentColor.opacity(0.18) : .clear,
                        in: RoundedRectangle(cornerRadius: 9))
        }
        .buttonStyle(.plain)
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            List {
                Section("Library") {
                    sidebarItem("All Wallpapers", symbol: "square.grid.2x2", count: library.items.count,
                                active: library.category == "All categories" && !library.favoritesOnly) {
                        library.category = "All categories"; library.favoritesOnly = false
                    }
                    sidebarItem("Favorites", symbol: "heart", count: library.favorites.count,
                                active: library.favoritesOnly) {
                        library.category = "All categories"; library.favoritesOnly = true
                    }
                }
                Section("Collections") {
                    ForEach(library.categories.filter { $0 != "All categories" }, id: \.self) { name in
                        sidebarItem(name, symbol: "folder", count: library.items.filter { $0.category == name }.count,
                                    active: library.category == name && !library.favoritesOnly) {
                            library.category = name; library.favoritesOnly = false
                        }
                    }
                }
            }
            .listStyle(.sidebar)
            Divider()
            Button { library.chooseFolder() } label: {
                Label(library.folderName, systemImage: "folder")
                    .lineLimit(1)
            }
            .buttonStyle(.plain)
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(14)
            .help("Change wallpaper folder")
        }
        .navigationTitle("Wallflow")
        .navigationSplitViewColumnWidth(min: 175, ideal: 215, max: 260)
    }

    private var filters: some View {
        HStack(spacing: 9) {
            Text("COLOR")
                .font(.caption2.weight(.semibold)).foregroundStyle(.secondary)
            ForEach(hues, id: \.self) { hue in
                Button { library.hue = hue } label: {
                    Circle()
                        .fill(hue == "All" ? Color.primary : color(for: hue))
                        .frame(width: 12, height: 12)
                        .padding(5)
                        .overlay(Circle().strokeBorder(library.hue == hue ? Color.primary : .clear, lineWidth: 1.7))
                }
                .buttonStyle(.plain)
                .help(hue == "All" ? "Any color" : hue)
                .accessibilityLabel(hue)
            }
            Spacer(minLength: 0)
            Toggle(isOn: $library.darkOnly) {
                Label("Dark", systemImage: "moon")
            }
            .toggleStyle(.button)
            .controlSize(.small)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 13)
    }

    private var gallery: some View {
        VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(library.favoritesOnly ? "Favorites" :
                         (library.category == "All categories" ? "Discover" : library.category))
                        .font(.largeTitle.weight(.semibold))
                    Text("\(library.filtered.count) wallpapers" +
                         (library.indexing ? " · Indexing colors" : " · Ready"))
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal, 20).padding(.top, 19)
            filters
            Divider()
            GeometryReader { geometry in
                // An explicit width-derived grid prevents adaptive GridItem from
                // collapsing to one oversized card when the inspector opens.
                let usable = max(0, geometry.size.width - 40)
                let count = max(1, Int((usable + 14) / (170 + 14)))
                let columns = Array(repeating: GridItem(.flexible(minimum: 0), spacing: 14), count: count)
                ScrollView {
                    if library.filtered.isEmpty {
                        VStack(spacing: 16) {
                            ContentUnavailableView(
                                library.libraryRoot == nil ? "Choose a Wallpaper Folder" : "No Wallpapers",
                                systemImage: "photo.on.rectangle.angled",
                                description: Text(library.libraryRoot == nil
                                    ? "Select a folder with images to begin. No other apps are required."
                                    : "Try a different filter or choose another folder."))
                            Button("Choose Folder", systemImage: "folder.badge.plus") { library.chooseFolder() }
                                .buttonStyle(.borderedProminent)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 60)
                    } else {
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(library.filtered) { item in
                                WallpaperCard(wallpaper: item,
                                              selected: library.selection?.id == item.id,
                                              active: library.current == item.id,
                                              favored: library.favorites.contains(item.id),
                                              select: { library.choose(item) },
                                              favorite: { library.toggleFavorite(item) },
                                              apply: { library.choose(item); library.apply(item) })
                            }
                        }
                        .padding(20)
                    }
                }
            }
        }
        .navigationTitle("Wallpapers")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { library.chooseFolder() } label: { Image(systemName: "folder.badge.plus") }
                    .help("Choose wallpaper folder")
                    .accessibilityLabel("Choose wallpaper folder")
            }
            ToolbarItem(placement: .primaryAction) {
                Button { library.scan() } label: { Image(systemName: "arrow.clockwise") }
                    .help("Refresh Library")
                    .accessibilityLabel("Refresh wallpaper library")
            }
            ToolbarItem(placement: .primaryAction) {
                Button { inspectorVisible.toggle() } label: {
                    Image(systemName: "sidebar.right")
                }
                .help(inspectorVisible ? "Hide Inspector" : "Show Inspector")
                .accessibilityLabel("Toggle inspector")
            }
        }
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: 8) {
                Circle().fill(library.error ? .red : .green).frame(width: 6, height: 6)
                Text(library.status).lineLimit(1).truncationMode(.tail)
                Spacer(minLength: 0)
            }
            .font(.caption2)
            .foregroundStyle(library.error ? Color.red : Color.secondary)
            .padding(.horizontal, 15).padding(.vertical, 9)
            .background(.bar)
            .help(library.status)
        }
    }

    private var inspector: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let item = library.selection {
                    WallpaperThumbnail(path: item.path, fit: true)
                        .aspectRatio(1.45, contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 13))
                        .overlay(RoundedRectangle(cornerRadius: 13).strokeBorder(.primary.opacity(0.10)))
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(item.category.capitalized)
                                .font(.caption).foregroundStyle(.secondary)
                            Spacer()
                            if item.id == library.current {
                                Label("Active", systemImage: "checkmark.circle.fill")
                                    .font(.caption2).foregroundStyle(.green)
                            }
                        }
                        Text(item.title)
                            .font(.title3.weight(.semibold))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Divider()
                    LabeledContent("Dominant color") {
                        HStack(spacing: 7) {
                            Circle().fill(color(for: library.analyses[item.id]?.hue ?? "Mono"))
                                .frame(width: 10, height: 10)
                            Text(library.analyses[item.id]?.hue ?? "Analyzing")
                        }
                    }
                    LabeledContent("Appearance") {
                        Text(library.analyses[item.id]?.isDark == true ? "Dark" : "Light")
                    }
                    Button { library.toggleFavorite(item) } label: {
                        Label(library.favorites.contains(item.id) ? "Remove from Favorites" : "Save to Favorites",
                              systemImage: library.favorites.contains(item.id) ? "heart.fill" : "heart")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                } else {
                    ContentUnavailableView("Select a Wallpaper", systemImage: "photo")
                }
            }
            .padding(18)
        }
        .safeAreaInset(edge: .bottom) {
            Button {
                if let item = library.selection { library.apply(item) }
            } label: {
                HStack {
                    if library.applying { ProgressView().controlSize(.small) }
                    Label(library.applying ? "Applying…" : "Set Desktop Wallpaper", systemImage: "desktopcomputer")
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 5)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(library.applying || library.selection == nil)
            .padding(12)
            .background(.bar)
        }
        .inspectorColumnWidth(min: 250, ideal: 300, max: 380)
    }

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            gallery
        }
        .inspector(isPresented: $inspectorVisible) {
            inspector
        }
        .searchable(text: $library.query, placement: .toolbar, prompt: "Search wallpapers")
        .tint(.accentColor)
        .frame(minWidth: 750, minHeight: 510)
        // Standard macOS fullscreen: Window menu > Exit Full Screen or Ctrl-Cmd-F.
        // Never change NSWindow.level, collectionBehavior or native traffic lights.
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}

@main
struct WallflowNativeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    var body: some Scene {
        WindowGroup("Wallflow", id: "picker") {
            WallflowView()
        }
        .defaultSize(width: 1270, height: 800)
    }
}
