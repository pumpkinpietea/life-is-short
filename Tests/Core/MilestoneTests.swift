import Foundation
import Testing
@testable import LifeIsShortCore

private let origin = Date(timeIntervalSince1970: 1_900_000_000)

private func sample(_ name: String = "Sample", visible: Bool = false) -> Milestone {
    Milestone(title: name, targetDate: origin.addingTimeInterval(90_000),
              timeZoneID: "Asia/Tokyo", isVisibleInWidget: visible)
}

@Test func ageResolutionAndLeapDayPolicy() throws {
    let birth = CivilDate(year: 2000, month: 2, day: 29)
    let ordinary = try TargetResolver.birthday(birthDate: birth, targetAge: 25, timeZoneID: "Asia/Tokyo")
    let leap = try TargetResolver.birthday(birthDate: birth, targetAge: 24, timeZoneID: "Asia/Tokyo")
    #expect(CivilDate(ordinary, timeZone: TimeZone(identifier: "Asia/Tokyo")!) == CivilDate(year: 2025, month: 2, day: 28))
    #expect(CivilDate(leap, timeZone: TimeZone(identifier: "Asia/Tokyo")!) == CivilDate(year: 2024, month: 2, day: 29))
    #expect(throws: MilestoneError.invalidAge) {
        try TargetResolver.birthday(birthDate: birth, targetAge: -1, timeZoneID: "Asia/Tokyo")
    }
}

@Test func targetTimeZoneAndOmittedTime() throws {
    let day = CivilDate(year: 2030, month: 1, day: 1)
    let midnight = try TargetResolver.resolve(day: day, timeZoneID: "Asia/Tokyo")
    let timed = try TargetResolver.resolve(day: day, hour: 10, minute: 30, timeZoneID: "Asia/Tokyo")
    #expect(timed.timeIntervalSince(midnight) == 37_800)
    let item = Milestone(title: "Saved zone", targetDate: timed, timeZoneID: "Asia/Tokyo")
    let decoded = try JSONDecoder().decode(Milestone.self, from: JSONEncoder().encode(item))
    #expect(decoded.targetDate == timed)
    #expect(decoded.timeZoneID == "Asia/Tokyo")
    #expect(throws: MilestoneError.invalidDate) {
        try TargetResolver.resolve(day: CivilDate(year: 2030, month: 2, day: 30), timeZoneID: "UTC")
    }
}

@Test func daylightSavingResolution() throws {
    let date = try TargetResolver.resolve(day: CivilDate(year: 2030, month: 3, day: 10),
                                          hour: 2, minute: 30, timeZoneID: "America/New_York")
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "America/New_York")!
    #expect(calendar.component(.hour, from: date) == 3)
    let repeated = try TargetResolver.resolve(day: CivilDate(year: 2030, month: 11, day: 3),
                                              hour: 1, minute: 30, timeZoneID: "America/New_York")
    #expect(calendar.timeZone.secondsFromGMT(for: repeated) == -14_400)
}

@Test func countdownDurationAndZeroBoundaries() {
    let target = origin.addingTimeInterval(26 * 3_600)
    let parts = CountdownParts(target: target, now: origin)
    #expect(parts == CountdownParts(target: target, now: origin))
    #expect(parts.days == 1 && parts.hours == 2 && parts.clock == "02:00:00")
    #expect(CountdownFormatStyle(target: target).format(origin) == "1 day")
    #expect(CountdownFormatStyle(target: target, mode: .clock).format(origin) == "1 day 02:00:00")
    #expect(CountdownFormatStyle(target: target, unit: .weeks).format(origin) == "<1 week")
    #expect(CountdownFormatStyle(target: target, unit: .hours).format(origin) == "26 hours")
    #expect(CountdownFormatStyle(target: target).format(target) == "0 days")
    #expect(CountdownFormatStyle(target: target, mode: .clock).format(target.addingTimeInterval(1)) == "0 days 00:00:00")
    #expect(CountdownFormatStyle(target: origin.addingTimeInterval(1), mode: .clock).format(origin.addingTimeInterval(0.9)) == "0 days 00:00:01")
}

@Test(arguments: [CountdownUnit.days, .weeks, .hours])
func subunitAndWholeUnitFormatting(unit: CountdownUnit) {
    let style = CountdownFormatStyle(target: origin.addingTimeInterval(unit.seconds), unit: unit)
    #expect(style.format(origin).hasPrefix("1 "))
    #expect(style.format(origin.addingTimeInterval(1)).hasPrefix("<1 "))
    #expect(style.format(origin.addingTimeInterval(unit.seconds)).hasPrefix("0 "))
}

@Test func discreteFormatSchedulesActuallyDifferentValues() throws {
    for mode in CountdownMode.allCases {
        for remaining in [0.2, 1.0, 1.2, 3_600.0, 86_400.0, 86_400.2, 9_876_543.0] {
            let style = CountdownFormatStyle(target: origin.addingTimeInterval(remaining), mode: mode)
            let after = try #require(style.discreteInput(after: origin))
            let before = try #require(style.discreteInput(before: origin))
            #expect(after > origin)
            #expect(before < origin)
            #expect(style.format(after) != style.format(origin))
            #expect(style.format(before) != style.format(origin))
        }
    }
    #expect(CountdownFormatStyle(target: origin).discreteInput(after: origin) == nil)
}

@Test func liveComponentsScheduleOnlyChangedOutput() {
    for mode in CountdownMode.allCases {
        for component in [CountdownFormatStyle.Component.value, .unit, .days, .clock, .full] {
            for remaining in [0.2, 1, 1.2, 86_400, 86_400.2, 172_800, 9_876_543] {
                let style = CountdownFormatStyle(target: origin.addingTimeInterval(remaining), mode: mode, component: component)
                if let next = style.discreteInput(after: origin) {
                    #expect(next > origin)
                    #expect(style.format(next) != style.format(origin))
                }
                if let previous = style.discreteInput(before: origin) {
                    #expect(previous < origin)
                    #expect(style.format(previous) != style.format(origin))
                }
            }
        }
    }
}

@Test func selectionReplacementIsAtomicAndRetainsData() throws {
    let first = sample("First", visible: true)
    let second = sample("Second", visible: true)
    let third = sample("Third", visible: true)
    let fourth = sample("Fourth")
    var library = MilestoneLibrary(milestones: [first, second, third, fourth], rotationAnchor: origin)
    let unchanged = library
    #expect(throws: MilestoneError.selectionFull) { try library.setVisibility(fourth.id, visible: true) }
    #expect(library == unchanged)
    try library.setVisibility(fourth.id, visible: true, replacing: second.id)
    #expect(library.selected.map(\.id) == [first.id, third.id, fourth.id])
    #expect(library.milestones.count == 4)
    #expect(library.milestones[1].title == "Second")
    #expect(!library.milestones[1].isVisibleInWidget)
    let beforeFailure = library
    #expect(throws: MilestoneError.invalidReplacement) {
        try library.setVisibility(second.id, visible: true, replacing: UUID())
    }
    #expect(library == beforeFailure)
}

@Test func overwriteHideReorderDeleteAndEmptySelection() throws {
    let a = sample("A", visible: true), b = sample("B"), c = sample("C", visible: true)
    var library = MilestoneLibrary(milestones: [a, b, c], rotationAnchor: origin)
    var edited = a
    edited.title = "Changed"
    try library.save(edited)
    #expect(library.milestones.count == 3 && library.milestones[0].title == "Changed")
    library.move(from: IndexSet(integer: 2), to: 0)
    #expect(library.selected.map(\.id) == [c.id, a.id])
    try library.setVisibility(a.id, visible: false)
    #expect(library.milestones.count == 3)
    try library.setVisibility(a.id, visible: true)
    #expect(library.selected.map(\.id) == [c.id, a.id])
    library.delete(c.id)
    #expect(library.selected.map(\.id) == [a.id])
    try library.setVisibility(a.id, visible: false)
    #expect(RotationSchedule.milestone(in: library, at: origin) == nil)
    #expect(library.milestones.count == 2)
}

@Test func rotationUsesAnchorAndSkipsHiddenMilestones() {
    let a = sample("A", visible: true), b = sample("B"), c = sample("C", visible: true)
    let library = MilestoneLibrary(milestones: [a, b, c], rotationAnchor: origin)
    #expect(RotationSchedule.milestone(in: library, at: origin)?.id == a.id)
    #expect(RotationSchedule.milestone(in: library, at: origin.addingTimeInterval(600))?.id == c.id)
    #expect(RotationSchedule.milestone(in: library, at: origin.addingTimeInterval(1_200))?.id == a.id)
    #expect(RotationSchedule.milestone(in: library, at: origin.addingTimeInterval(-1))?.id == c.id)
    let dates = RotationSchedule.dates(in: library, startingAt: origin.addingTimeInterval(42), hours: 1)
    #expect(dates[1] == origin.addingTimeInterval(600))
    #expect(zip(dates.dropFirst(), dates.dropFirst(2)).allSatisfy { $1.timeIntervalSince($0) == 600 })
}

@Test func largeLibraryPersistenceAndFailedSavePreservePriorData() throws {
    let directory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        .appendingPathComponent(".build/CoreTestData/\(UUID().uuidString)", isDirectory: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    let store = LibraryFileStore(directory: directory)
    #expect(try store.load().milestones.isEmpty)
    let items = (0..<200).map { sample("Milestone \($0)", visible: $0 < 3) }
    let library = MilestoneLibrary(milestones: items, rotationAnchor: origin)
    try store.save(library)
    #expect(try store.load() == library)
    var invalid = library
    invalid.milestones[4].isVisibleInWidget = true
    #expect(throws: MilestoneError.selectionFull) { try store.save(invalid) }
    #expect(try store.load() == library)
    let previousData = try Data(contentsOf: store.metadataURL)
    try Data("corrupt".utf8).write(to: store.metadataURL)
    #expect(throws: (any Error).self) { try store.load() }
    #expect(try Data(contentsOf: store.metadataURL) != previousData)
}

@Test func invalidSnapshotsAndPhotoPathsAreRejected() throws {
    let item = sample()
    let duplicate = MilestoneLibrary(milestones: [item, item])
    #expect(throws: MilestoneError.invalidSnapshot) { try duplicate.validate() }
    var invalid = item
    invalid.photoFilename = "../outside.jpg"
    #expect(throws: MilestoneError.invalidPhotoReference) { try invalid.validate() }
    invalid.photoFilename = "\(UUID().uuidString).jpg"
    try invalid.validate()
    var future = MilestoneLibrary()
    future.schemaVersion = 100
    #expect(throws: MilestoneError.unsupportedVersion) { try future.validate() }
}
