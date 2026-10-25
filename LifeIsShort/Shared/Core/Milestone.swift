import Foundation

public enum TargetMode: String, Codable, CaseIterable, Sendable {
    case date, age
}

public enum CountdownMode: String, Codable, CaseIterable, Sendable {
    case units, clock
}

public enum CountdownUnit: String, Codable, CaseIterable, Sendable {
    case days, weeks, hours

    public var seconds: TimeInterval {
        switch self {
        case .days: 86_400
        case .weeks: 604_800
        case .hours: 3_600
        }
    }
}

public struct CivilDate: Codable, Hashable, Sendable {
    public var year: Int
    public var month: Int
    public var day: Int

    public init(year: Int, month: Int, day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }

    public init(_ date: Date, timeZone: TimeZone) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        year = parts.year ?? 2000
        month = parts.month ?? 1
        day = parts.day ?? 1
    }
}

public enum MilestoneError: Error, Equatable, Sendable {
    case emptyTitle, invalidDate, invalidAge, invalidTimeZone
    case selectionFull, missingMilestone, invalidReplacement
    case invalidSnapshot, unsupportedVersion, invalidPhotoReference
}

public enum TargetResolver {
    public static func resolve(
        day: CivilDate,
        hour: Int? = nil,
        minute: Int = 0,
        timeZoneID: String
    ) throws -> Date {
        guard let zone = TimeZone(identifier: timeZoneID) else { throw MilestoneError.invalidTimeZone }
        guard (1...12).contains(day.month), (1...31).contains(day.day),
              (0...23).contains(hour ?? 0), (0...59).contains(minute) else {
            throw MilestoneError.invalidDate
        }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = zone
        guard let noon = calendar.date(from: DateComponents(
            year: day.year, month: day.month, day: day.day, hour: 12
        )), CivilDate(noon, timeZone: zone) == day else { throw MilestoneError.invalidDate }
        let start = calendar.startOfDay(for: noon)
        guard let hour else { return start }
        guard let resolved = calendar.date(
            bySettingHour: hour, minute: minute, second: 0, of: start,
            matchingPolicy: .nextTime, repeatedTimePolicy: .first, direction: .forward
        ), CivilDate(resolved, timeZone: zone) == day else { throw MilestoneError.invalidDate }
        return resolved
    }

    public static func birthday(
        birthDate: CivilDate, targetAge: Int, hour: Int? = nil,
        minute: Int = 0, timeZoneID: String
    ) throws -> Date {
        guard targetAge >= 0, targetAge <= 10_000 else { throw MilestoneError.invalidAge }
        _ = try resolve(day: birthDate, timeZoneID: timeZoneID)
        let year = birthDate.year.addingReportingOverflow(targetAge)
        guard !year.overflow else { throw MilestoneError.invalidAge }
        var target = CivilDate(year: year.partialValue, month: birthDate.month, day: birthDate.day)
        if target.month == 2 && target.day == 29 {
            let leap = target.year.isMultiple(of: 400) || (target.year.isMultiple(of: 4) && !target.year.isMultiple(of: 100))
            if !leap { target.day = 28 }
        }
        return try resolve(day: target, hour: hour, minute: minute, timeZoneID: timeZoneID)
    }
}

public struct Milestone: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var title: String
    public var targetDate: Date
    public var timeZoneID: String
    public var targetMode: TargetMode
    public var birthDate: CivilDate?
    public var targetAge: Int?
    public var includesTime: Bool
    public var photoFilename: String?
    public var countdownMode: CountdownMode
    public var unit: CountdownUnit
    public var isVisibleInWidget: Bool

    public init(
        id: UUID = UUID(), title: String, targetDate: Date,
        timeZoneID: String = TimeZone.current.identifier,
        targetMode: TargetMode = .date, birthDate: CivilDate? = nil,
        targetAge: Int? = nil, includesTime: Bool = false,
        photoFilename: String? = nil, countdownMode: CountdownMode = .units,
        unit: CountdownUnit = .days, isVisibleInWidget: Bool = false
    ) {
        self.id = id
        self.title = title
        self.targetDate = targetDate
        self.timeZoneID = timeZoneID
        self.targetMode = targetMode
        self.birthDate = birthDate
        self.targetAge = targetAge
        self.includesTime = includesTime
        self.photoFilename = photoFilename
        self.countdownMode = countdownMode
        self.unit = unit
        self.isVisibleInWidget = isVisibleInWidget
    }

    public func validate() throws {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw MilestoneError.emptyTitle }
        guard targetDate.timeIntervalSince1970.isFinite else { throw MilestoneError.invalidDate }
        guard TimeZone(identifier: timeZoneID) != nil else { throw MilestoneError.invalidTimeZone }
        if targetMode == .age {
            guard let birthDate, let targetAge else { throw MilestoneError.invalidAge }
            _ = try TargetResolver.birthday(birthDate: birthDate, targetAge: targetAge, timeZoneID: timeZoneID)
        }
        if let photoFilename {
            guard photoFilename == (photoFilename as NSString).lastPathComponent,
                  photoFilename.hasSuffix(".jpg"),
                  UUID(uuidString: String(photoFilename.dropLast(4))) != nil else {
                throw MilestoneError.invalidPhotoReference
            }
        }
    }
}
