import Foundation

public struct MilestoneLibrary: Codable, Equatable, Sendable {
    public static let selectionLimit = 3
    public var schemaVersion: Int
    public var milestones: [Milestone]
    public var rotationAnchor: Date

    public init(milestones: [Milestone] = [], rotationAnchor: Date = .now) {
        schemaVersion = 1
        self.milestones = milestones
        self.rotationAnchor = rotationAnchor
    }

    public var selected: [Milestone] { milestones.filter(\.isVisibleInWidget) }

    public func validate() throws {
        guard schemaVersion == 1 else { throw MilestoneError.unsupportedVersion }
        guard rotationAnchor.timeIntervalSince1970.isFinite,
              Set(milestones.map(\.id)).count == milestones.count else { throw MilestoneError.invalidSnapshot }
        guard selected.count <= Self.selectionLimit else { throw MilestoneError.selectionFull }
        try milestones.forEach { try $0.validate() }
    }

    public mutating func save(_ milestone: Milestone, replacingSelection replacementID: UUID? = nil) throws {
        var updated = self
        var value = milestone
        value.title = value.title.trimmingCharacters(in: .whitespacesAndNewlines)
        try value.validate()
        if let index = updated.milestones.firstIndex(where: { $0.id == value.id }) {
            updated.milestones[index] = value
        } else {
            updated.milestones.append(value)
        }
        if let replacementID {
            guard replacementID != value.id, value.isVisibleInWidget,
                  let index = updated.milestones.firstIndex(where: { $0.id == replacementID }),
                  updated.milestones[index].isVisibleInWidget else { throw MilestoneError.invalidReplacement }
            updated.milestones[index].isVisibleInWidget = false
        }
        try updated.validate()
        self = updated
    }

    public mutating func setVisibility(_ id: UUID, visible: Bool, replacing replacementID: UUID? = nil) throws {
        guard var value = milestones.first(where: { $0.id == id }) else { throw MilestoneError.missingMilestone }
        value.isVisibleInWidget = visible
        try save(value, replacingSelection: replacementID)
    }

    public mutating func delete(_ id: UUID) {
        milestones.removeAll { $0.id == id }
    }

    public mutating func move(from offsets: IndexSet, to destination: Int) {
        guard offsets.allSatisfy(milestones.indices.contains), (0...milestones.count).contains(destination) else { return }
        let moving = offsets.sorted().map { milestones[$0] }
        let remaining = milestones.enumerated().filter { !offsets.contains($0.offset) }.map(\.element)
        let adjusted = destination - offsets.filter { $0 < destination }.count
        milestones = Array(remaining.prefix(adjusted)) + moving + Array(remaining.dropFirst(adjusted))
    }
}

public struct LibraryFileStore: Sendable {
    public let directory: URL
    public var metadataURL: URL { directory.appendingPathComponent("milestones.json") }
    public var photosURL: URL { directory.appendingPathComponent("Photos", isDirectory: true) }

    public init(directory: URL) { self.directory = directory }

    public func load() throws -> MilestoneLibrary {
        guard FileManager.default.fileExists(atPath: metadataURL.path) else { return MilestoneLibrary() }
        let library = try JSONDecoder().decode(MilestoneLibrary.self, from: Data(contentsOf: metadataURL))
        try library.validate()
        return library
    }

    public func save(_ library: MilestoneLibrary) throws {
        try library.validate()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(library)
        try data.write(to: metadataURL, options: .atomic)
    }
}

public enum RotationSchedule {
    public static let interval: TimeInterval = 600

    public static func milestone(in library: MilestoneLibrary, at date: Date) -> Milestone? {
        let selected = library.selected
        guard !selected.isEmpty else { return nil }
        let elapsed = date.timeIntervalSince(library.rotationAnchor)
        guard elapsed.isFinite else { return selected.first }
        let slot = Int(floor(elapsed / interval))
        let index = ((slot % selected.count) + selected.count) % selected.count
        return selected[index]
    }

    public static func dates(in library: MilestoneLibrary, startingAt date: Date, hours: Int = 24) -> [Date] {
        guard library.selected.count > 1 else { return [date] }
        let slot = floor(date.timeIntervalSince(library.rotationAnchor) / interval)
        let next = library.rotationAnchor.addingTimeInterval((slot + 1) * interval)
        return [date] + (0..<(max(1, hours) * 6)).map { next.addingTimeInterval(Double($0) * interval) }
    }
}
