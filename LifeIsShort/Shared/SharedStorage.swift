import Foundation
import ImageIO
import UniformTypeIdentifiers

enum SharedStorage {
    static let groupID = "group.com.pumpkinpietea.LifeIsShort"
    static let widgetKind = "LifeIsShortCountdown"
    static let appURL = URL(string: "lifeisshort://milestones")!

    static func store() throws -> LibraryFileStore {
        guard let directory = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupID) else {
            throw CocoaError(.fileReadNoPermission)
        }
        return LibraryFileStore(directory: directory.appendingPathComponent("Library", isDirectory: true))
    }

    static func photoURL(_ filename: String?) -> URL? {
        guard let filename, filename == (filename as NSString).lastPathComponent,
              UUID(uuidString: String(filename.dropLast(4))) != nil, filename.hasSuffix(".jpg") else { return nil }
        return try? store().photosURL.appendingPathComponent(filename)
    }
}

enum PhotoAssets {
    static func importImage(at sourceURL: URL, store: LibraryFileStore) throws -> String {
        guard let source = CGImageSourceCreateWithURL(sourceURL as CFURL, nil),
              let image = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: 1_280,
                kCGImageSourceShouldCacheImmediately: true
              ] as CFDictionary) else { throw CocoaError(.fileReadCorruptFile) }
        try FileManager.default.createDirectory(at: store.photosURL, withIntermediateDirectories: true)
        let name = UUID().uuidString + ".jpg"
        let url = store.photosURL.appendingPathComponent(name)
        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.jpeg.identifier as CFString, 1, nil) else {
            throw CocoaError(.fileWriteUnknown)
        }
        CGImageDestinationAddImage(destination, image, [kCGImageDestinationLossyCompressionQuality: 0.88] as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { throw CocoaError(.fileWriteUnknown) }
        return name
    }

    static func cleanUnused(in library: MilestoneLibrary, store: LibraryFileStore) {
        let referenced = Set(library.milestones.compactMap(\.photoFilename))
        guard let urls = try? FileManager.default.contentsOfDirectory(
            at: store.photosURL, includingPropertiesForKeys: [.contentModificationDateKey]
        ) else { return }
        for url in urls where !referenced.contains(url.lastPathComponent) {
            guard let modified = try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate,
                  modified < Date.now.addingTimeInterval(-86_400) else { continue }
            try? FileManager.default.removeItem(at: url)
        }
    }
}
