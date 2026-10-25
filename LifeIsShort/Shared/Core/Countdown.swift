import Foundation

public struct CountdownParts: Equatable, Sendable {
    public var days: Int
    public var hours: Int
    public var minutes: Int
    public var seconds: Int

    public init(target: Date, now: Date) {
        let remaining = max(0, target.timeIntervalSince(now))
        let total = Int(min(ceil(remaining), Double(Int.max / 2)))
        days = total / 86_400
        hours = (total % 86_400) / 3_600
        minutes = (total % 3_600) / 60
        seconds = total % 60
    }

    public var clock: String {
        String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

public struct CountdownLexicon: Codable, Hashable, Sendable {
    public var day: String
    public var days: String
    public var week: String
    public var weeks: String
    public var hour: String
    public var hours: String
    public var lessThan: String
    public var separator: String

    public init(day: String = "day", days: String = "days", week: String = "week", weeks: String = "weeks",
                hour: String = "hour", hours: String = "hours", lessThan: String = "<1", separator: String = " ") {
        self.day = day; self.days = days; self.week = week; self.weeks = weeks
        self.hour = hour; self.hours = hours; self.lessThan = lessThan; self.separator = separator
    }

    public func label(for unit: CountdownUnit, count: Int) -> String {
        switch unit {
        case .days: count == 1 ? day : days
        case .weeks: count == 1 ? week : weeks
        case .hours: count == 1 ? hour : hours
        }
    }
}

public struct CountdownFormatStyle: DiscreteFormatStyle, Sendable {
    public enum Component: String, Codable, Sendable { case full, value, unit, days, clock }
    public var target: Date
    public var mode: CountdownMode
    public var unit: CountdownUnit
    public var component: Component
    public var localeIdentifier: String
    public var lexicon: CountdownLexicon

    public init(target: Date, mode: CountdownMode = .units, unit: CountdownUnit = .days,
                component: Component = .full, localeIdentifier: String = "en",
                lexicon: CountdownLexicon = .init()) {
        self.target = target; self.mode = mode; self.unit = unit
        self.component = component; self.localeIdentifier = localeIdentifier; self.lexicon = lexicon
    }

    public func format(_ value: Date) -> String {
        let remaining = max(0, target.timeIntervalSince(value))
        if mode == .clock {
            let parts = CountdownParts(target: target, now: value)
            let days = number(parts.days) + lexicon.separator + lexicon.label(for: .days, count: parts.days)
            switch component {
            case .clock: return parts.clock
            case .days: return days
            default: return days + " " + parts.clock
            }
        }
        let count = Int(min(floor(remaining / unit.seconds), Double(Int.max / 2)))
        let short = remaining > 0 && count == 0
        let amount = short ? lexicon.lessThan : number(count)
        let label = lexicon.label(for: unit, count: short ? 1 : count)
        switch component {
        case .value: return amount
        case .unit: return label
        default: return amount + lexicon.separator + label
        }
    }

    private func number(_ value: Int) -> String {
        value.formatted(.number.locale(Locale(identifier: localeIdentifier)))
    }

    public func discreteInput(after input: Date) -> Date? {
        let remaining = target.timeIntervalSince(input)
        guard remaining > 0 else { return nil }
        if mode == .clock {
            if component == .days {
                let days = CountdownParts(target: target, now: input).days
                return days > 0 ? target.addingTimeInterval(-Double(days * 86_400 - 1)) : nil
            }
            return target.addingTimeInterval(-max(0, ceil(remaining) - 1))
        }
        if component == .unit {
            guard lexicon.label(for: unit, count: 1) != lexicon.label(for: unit, count: 2) else { return nil }
            return remaining >= 2 * unit.seconds
                ? target.addingTimeInterval(-2 * unit.seconds + 0.001) : target
        }
        let count = floor(remaining / unit.seconds)
        if count == 0 { return target }
        return target.addingTimeInterval(-count * unit.seconds).addingTimeInterval(0.001)
    }

    public func discreteInput(before input: Date) -> Date? {
        let remaining = target.timeIntervalSince(input)
        if mode == .clock && component == .days {
            let days = CountdownParts(target: target, now: input).days
            return target.addingTimeInterval(-Double((days + 1) * 86_400 - 1) - 0.001)
        }
        if mode == .units && component == .unit {
            guard lexicon.label(for: unit, count: 1) != lexicon.label(for: unit, count: 2) else { return nil }
            if remaining <= 0 { return target.addingTimeInterval(-0.001) }
            return remaining < 2 * unit.seconds ? target.addingTimeInterval(-2 * unit.seconds) : nil
        }
        if remaining <= 0 { return target.addingTimeInterval(-0.001) }
        if mode == .clock { return target.addingTimeInterval(-ceil(remaining) - 0.001) }
        return target.addingTimeInterval(-(floor(remaining / unit.seconds) + 1) * unit.seconds - 0.001)
    }
}
