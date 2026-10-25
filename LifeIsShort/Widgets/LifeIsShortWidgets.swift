import SwiftUI
import WidgetKit

struct MilestoneEntry: TimelineEntry {
    var date: Date
    var milestone: Milestone?
}

struct MilestoneProvider: TimelineProvider {
    func placeholder(in context: Context) -> MilestoneEntry {
        MilestoneEntry(date: .now, milestone: Milestone(
            title: Localized.text("A moment to look forward to"), targetDate: .now.addingTimeInterval(86_400 * 365)
        ))
    }

    func getSnapshot(in context: Context, completion: @escaping (MilestoneEntry) -> Void) {
        let library = (try? SharedStorage.store().load()) ?? MilestoneLibrary()
        completion(MilestoneEntry(date: .now, milestone: RotationSchedule.milestone(in: library, at: .now)))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MilestoneEntry>) -> Void) {
        let now = Date.now
        let library = (try? SharedStorage.store().load()) ?? MilestoneLibrary()
        let entries = PresentationSchedule.dates(in: library, startingAt: now).map {
            MilestoneEntry(date: $0, milestone: RotationSchedule.milestone(in: library, at: $0))
        }
        completion(Timeline(entries: entries, policy: .after(now.addingTimeInterval(86_400))))
    }
}

struct MilestoneWidgetView: View {
    let entry: MilestoneEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        MilestoneCardContent(milestone: entry.milestone, compact: family == .systemSmall, presentationDate: entry.date)
            .containerBackground(for: .widget) { MilestoneBackground(milestone: entry.milestone) }
            .widgetURL(SharedStorage.appURL)
    }
}

@main
struct LifeIsShortWidgets: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: SharedStorage.widgetKind, provider: MilestoneProvider()) { entry in
            MilestoneWidgetView(entry: entry)
        }
        .configurationDisplayName("Life Is Short")
        .description("Your photos. Your milestones. Make today count.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
