import AppKit
import SwiftUI
import ImageIO
import CoreGraphics

// Use the existing SwiftUI.State property wrapper instead of the Swift 6.4
// @State macro, whose plugin is not included in some Command Line Tools.
typealias StoredState<Value> = SwiftUI.State<Value>

let home = FileManager.default.homeDirectoryForCurrentUser
let wallflowConfig = home.appendingPathComponent(".config/wallflow", isDirectory: true)

struct Wallpaper: Identifiable, Hashable {
    let id: String
    let path: String
    let category: String
    let title: String
    let stamp: String
}

struct ImageAnalysis: Codable {
    let stamp: String
    let hue: String
    let isDark: Bool
}

private let hues = ["All", "Red", "Orange", "Yellow", "Green", "Cyan", "Blue", "Purple", "Pink", "Mono"]

private func hueColor(_ hue: String) -> Color {
    switch hue {
    case "Red": return Color(red: 0.93, green: 0.39, blue: 0.42)
    case "Orange": return Color(red: 0.98, green: 0.63, blue: 0.39)
    case "Yellow": return Color(red: 0.92, green: 0.80, blue: 0.43)
    case "Green": return Color(red: 0.42, green: 0.78, blue: 0.59)
    case "Cyan": return Color(red: 0.38, green: 0.75, blue: 0.86)
    case "Blue": return Color(red: 0.43, green: 0.58, blue: 0.93)
    case "Purple": return Color(red: 0.65, green: 0.50, blue: 0.90)
    case "Pink": return Color(red: 0.90, green: 0.56, blue: 0.73)
    default: return Color(red: 0.55, green: 0.58, blue: 0.64)
    }
}

private func makeThumbnail(_ path: String, size: Int) -> CGImage? {
    let url = URL(fileURLWithPath: path) as CFURL
    // Image metadata is untrusted. Reject implausibly large images before decoding.
    guard let source = CGImageSourceCreateWithURL(url, nil),
          let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any],
          let width = properties[kCGImagePropertyPixelWidth as String] as? NSNumber,
          let height = properties[kCGImagePropertyPixelHeight as String] as? NSNumber else {
        return nil
    }
    let pixelWidth = width.int64Value
    let pixelHeight = height.int64Value
    guard pixelWidth > 0, pixelHeight > 0,
          pixelWidth <= 32_768, pixelHeight <= 32_768,
          pixelWidth <= 150_000_000 / pixelHeight else {
        return nil
    }
    let options: [CFString: Any] = [
        kCGImageSourceCreateThumbnailFromImageAlways: true,
        kCGImageSourceCreateThumbnailWithTransform: true,
        kCGImageSourceThumbnailMaxPixelSize: size,
        kCGImageSourceShouldCacheImmediately: false
    ]
    return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
}

final class ThumbnailCache {
    static let shared = ThumbnailCache()
    private let images = NSCache<NSString, NSImage>()
    func load(_ path: String) -> NSImage? {
        let key = path as NSString
        if let cached = images.object(forKey: key) { return cached }
        guard let image = makeThumbnail(path, size: 420) else { return nil }
        let thumbnail = NSImage(cgImage: image, size: NSSize(width: image.width, height: image.height))
        images.setObject(thumbnail, forKey: key, cost: image.width * image.height * 4)
        images.totalCostLimit = 180 * 1024 * 1024
        return thumbnail
    }
}

func analyze(_ wallpaper: Wallpaper) -> ImageAnalysis {
    guard let image = makeThumbnail(wallpaper.path, size: 64) else {
        return ImageAnalysis(stamp: wallpaper.stamp, hue: "Mono", isDark: true)
    }
    let side = 64
    var bytes = [UInt8](repeating: 0, count: side * side * 4)
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let created = bytes.withUnsafeMutableBytes { memory -> Bool in
        guard let address = memory.baseAddress,
              let ctx = CGContext(data: address, width: side, height: side,
                                  bitsPerComponent: 8, bytesPerRow: side * 4,
                                  space: colorSpace,
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return false }
        ctx.interpolationQuality = .medium
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: side, height: side))
        return true
    }
    guard created else { return ImageAnalysis(stamp: wallpaper.stamp, hue: "Mono", isDark: true) }
    var scores = [Double](repeating: 0, count: 8)
    var brightness = 0.0
    var colored = 0
    var pixels = 0
    for i in stride(from: 0, to: bytes.count, by: 4) {
        if bytes[i + 3] < 120 { continue }
        let r = Double(bytes[i]) / 255.0
        let g = Double(bytes[i + 1]) / 255.0
        let b = Double(bytes[i + 2]) / 255.0
        brightness += 0.2126 * r + 0.7152 * g + 0.0722 * b
        pixels += 1
        let high = max(r, max(g, b))
        let low = min(r, min(g, b))
        let delta = high - low
        let saturation = high > 0 ? delta / high : 0
        if saturation < 0.19 || high < 0.12 || delta < 0.08 { continue }
        var h = 0.0
        if delta > 0 {
            if high == r { h = 60 * ((g - b) / delta).truncatingRemainder(dividingBy: 6) }
            else if high == g { h = 60 * ((b - r) / delta + 2) }
            else { h = 60 * ((r - g) / delta + 4) }
        }
        if h < 0 { h += 360 }
        let index: Int
        switch h {
        case 0..<14, 344...360: index = 0
        case 14..<43: index = 1
        case 43..<72: index = 2
        case 72..<165: index = 3
        case 165..<195: index = 4
        case 195..<255: index = 5
        case 255..<310: index = 6
        default: index = 7
        }
        scores[index] += pow(saturation, 1.5) * sqrt(high)
        colored += 1
    }
    let names = ["Red", "Orange", "Yellow", "Green", "Cyan", "Blue", "Purple", "Pink"]
    let best = scores.enumerated().max { $0.element < $1.element }
    let hue = (colored >= max(3, pixels / 300) && (best?.element ?? 0) > 0.1)
        ? names[best!.offset] : "Mono"
    return ImageAnalysis(stamp: wallpaper.stamp, hue: hue,
                         isDark: pixels == 0 ? true : brightness / Double(pixels) < 0.43)
}

