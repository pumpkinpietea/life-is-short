import SwiftUI
import Observation
import WidgetKit

@MainActor @Observable
final class AppModel {
    var library = MilestoneLibrary()
    var errorMessage: String?
    var storageAvailable = false
    private var store: LibraryFileStore?

    init() {
        do {
            let store = try SharedStorage.store()
            self.store = store
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-ui-testing") { try DebugFixtures.prepare(store: store) }
            #endif
            library = try store.load()
            storageAvailable = true
        } catch { errorMessage = Localized.text("Your saved milestones could not be opened. Please try again.") }
    }

    func reload() {
        do {
            let resolved = try store ?? SharedStorage.store()
            store = resolved
            library = try resolved.load()
            storageAvailable = true
        } catch {
            storageAvailable = false
            errorMessage = Localized.text("Your saved milestones could not be opened. Please try again.")
        }
    }

    func save(_ milestone: Milestone, replacing replacement: UUID? = nil) throws {
        try update { try $0.save(milestone, replacingSelection: replacement) }
    }
    func setVisibility(_ id: UUID, visible: Bool, replacing replacement: UUID? = nil) throws {
        try update { try $0.setVisibility(id, visible: visible, replacing: replacement) }
    }
    func delete(_ id: UUID) throws { try update { $0.delete(id) } }
    func move(from offsets: IndexSet, to destination: Int) throws { try update { $0.move(from: offsets, to: destination) } }

    private func update(_ mutation: (inout MilestoneLibrary) throws -> Void) throws {
        guard storageAvailable, let store else { throw CocoaError(.fileWriteNoPermission) }
        var updated = library
        try mutation(&updated)
        try store.save(updated)
        library = updated
        PhotoAssets.cleanUnused(in: updated, store: store)
        WidgetCenter.shared.reloadTimelines(ofKind: SharedStorage.widgetKind)
    }

    func importPhoto(at url: URL) async throws -> String {
        guard let store else { throw CocoaError(.fileWriteNoPermission) }
        return try await Task.detached(priority: .userInitiated) { try PhotoAssets.importImage(at: url, store: store) }.value
    }
    func report(_ error: Error) { errorMessage = Localized.error(error) }
}

#if DEBUG
enum DebugFixtures {
    static func prepare(store: LibraryFileStore) throws {
        let args = ProcessInfo.processInfo.arguments
        if args.contains("-preserve-library") { return }
        var library = MilestoneLibrary()
        if args.contains("-seed-samples") {
            let titles = ["A new adventure", "The next chapter", "A quiet celebration", "A saved memory"]
            for index in 0..<(args.contains("-seed-200") ? 200 : 4) {
                var item = Milestone(title: index < titles.count ? titles[index] : "Milestone \(index + 1)",
                                     targetDate: .now.addingTimeInterval(Double(26 + index * 24) * 3_600),
                                     timeZoneID: "Asia/Tokyo", countdownMode: index == 1 ? .clock : .units,
                                     isVisibleInWidget: index < 3)
                if index == 2 { item.targetDate = .now.addingTimeInterval(-60) }
                library.milestones.append(item)
            }
        }
        if args.contains("-seed-widget-proof") || args.contains("-seed-zero-crossing") || args.contains("-seed-day-crossing") {
            let remaining: TimeInterval = args.contains("-seed-zero-crossing") ? 35
                : args.contains("-seed-day-crossing") ? 86_425 : 50 * 86_400 + 3_661
            library = MilestoneLibrary(milestones: [Milestone(
                title: "Widget rendering proof", targetDate: .now.addingTimeInterval(remaining),
                countdownMode: .clock, isVisibleInWidget: true
            )])
        }
        if args.contains("-seed-rotation-proof") { library.rotationAnchor = .now.addingTimeInterval(-570) }
        try store.save(library)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
#endif
