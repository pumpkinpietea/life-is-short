import Foundation
import Testing
@testable import LifeIsShortCore
#if canImport(SwiftUI)
import SwiftUI

@Test func nativeWidgetClockMatchesRequestedRemainder() {
    let now = Date(timeIntervalSince1970: 1_700_000_000)
    for remaining in [0.0, 0.2, 1, 59, 599, 599.5, 600, 3_599, 3_599.5, 3_600, 35_999, 35_999.5, 36_000, 86_399, 86_399.5, 86_400, 86_400.5, 4_323_661] {
        let milestone = Milestone(title: "Fixture", targetDate: now.addingTimeInterval(remaining), countdownMode: .clock)
        let end = PresentationSchedule.clockEnd(for: milestone, at: now)
        let timer = SystemFormatStyle.Timer(countingDownIn: min(now, end.addingTimeInterval(-1))..<end)
        let actual = PresentationSchedule.clockPrefix(for: milestone, at: now) + String(timer.format(now).characters)
        #expect(actual == CountdownParts(target: milestone.targetDate, now: now).clock, "Remaining: \(remaining), actual: \(actual)")
    }
}
#endif

@Test func presentationTimelineIncludesUnitAndClockBoundaries() {
    let now = Date(timeIntervalSince1970: 1_700_000_000)
    let clock = Milestone(title: "Clock", targetDate: now.addingTimeInterval(90_000), countdownMode: .clock, isVisibleInWidget: true)
    let units = Milestone(title: "Hours", targetDate: now.addingTimeInterval(7_200), unit: .hours, isVisibleInWidget: true)
    let library = MilestoneLibrary(milestones: [clock, units], rotationAnchor: now)
    let dates = PresentationSchedule.dates(in: library, startingAt: now)
    #expect(dates.first == now)
    #expect(dates == dates.sorted())
    #expect(Set(dates).count == dates.count)
    #expect(dates.contains(now.addingTimeInterval(3_601)))
    #expect(dates.contains(now.addingTimeInterval(3_600.001)))
    #expect(dates.contains(units.targetDate))
    #expect(dates.count < 250)
    let hidden = MilestoneLibrary(milestones: [Milestone(title: "Hidden", targetDate: now)])
    #expect(PresentationSchedule.dates(in: hidden, startingAt: now) == [now])
}
