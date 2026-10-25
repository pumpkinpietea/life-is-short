import Foundation

/// Prepares changes of layout or whole units; seconds are rendered by the system timer.
public enum PresentationSchedule {
    public static func dates(in library: MilestoneLibrary, startingAt now: Date, hours: Int = 24) -> [Date] {
        let horizon = now.addingTimeInterval(Double(max(1, hours)) * 3_600)
        var dates = RotationSchedule.dates(in: library, startingAt: now, hours: hours)
        func append(_ date: Date) {
            if date > now && date <= horizon { dates.append(date) }
        }
        for item in library.selected {
            append(item.targetDate)
            if item.countdownMode == .units {
                let count = floor(max(0, item.targetDate.timeIntervalSince(now)) / item.unit.seconds)
                let steps = min(Int(count), max(1, hours) + 1)
                for step in 0..<steps {
                    append(item.targetDate.addingTimeInterval(-(count - Double(step)) * item.unit.seconds + 0.001))
                }
            } else {
                let days = CountdownParts(target: item.targetDate, now: now).days
                for day in max(0, days - max(1, hours) / 24 - 2)...days {
                    let end = item.targetDate.addingTimeInterval(-Double(day) * 86_400)
                    // The system timer drops leading zero fields at these boundaries.
                    for remaining in [36_000.0, 3_600.0, 600.0] {
                        append(end.addingTimeInterval(-remaining + 1))
                    }
                    if day > 0 { append(end.addingTimeInterval(1)) }
                }
            }
        }
        return Array(Set(dates)).sorted()
    }

    public static func clockEnd(for milestone: Milestone, at date: Date) -> Date {
        milestone.targetDate.addingTimeInterval(-Double(CountdownParts(target: milestone.targetDate, now: date).days) * 86_400)
    }

    public static func clockPrefix(for milestone: Milestone, at date: Date) -> String {
        let parts = CountdownParts(target: milestone.targetDate, now: date)
        if parts.hours >= 10 { return "" }
        if parts.hours > 0 { return "0" }
        return parts.minutes >= 10 ? "00:" : "00:0"
    }
}
