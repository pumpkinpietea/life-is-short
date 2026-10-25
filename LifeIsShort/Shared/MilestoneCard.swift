import SwiftUI

struct MilestoneBackground: View {
    var milestone: Milestone?
    var maximumPhotoPixelSize = 1_280
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width.isFinite ? max(0, geometry.size.width) : 0
            let height = geometry.size.height.isFinite ? max(0, geometry.size.height) : 0
            ZStack {
                LinearGradient(colors: [Color(red: 0.10, green: 0.29, blue: 0.31), Color(red: 0.04, green: 0.11, blue: 0.19)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                if let url = SharedStorage.photoURL(milestone?.photoFilename),
                   let image = PhotoAssets.thumbnail(at: url, maximumPixelSize: maximumPhotoPixelSize) {
                    Image(decorative: image, scale: 1).resizable().scaledToFill()
                        .frame(width: width, height: height).clipped()
                } else {
                    Circle().fill(.white.opacity(0.045))
                        .frame(width: width * 0.95)
                        .offset(x: width * 0.45, y: -height * 0.28)
                }
                LinearGradient(colors: [.black.opacity(0.12), .black.opacity(0.68)], startPoint: .top, endPoint: .bottom)
            }
        }
    }
}

struct CountdownLabel: View {
    var milestone: Milestone
    var presentationDate: Date? = nil
    var compact = false
    @Environment(\.locale) private var locale

    private func style(_ component: CountdownFormatStyle.Component) -> CountdownFormatStyle {
        CountdownFormatStyle(target: milestone.targetDate, mode: milestone.countdownMode,
                             unit: milestone.unit, component: component,
                             localeIdentifier: locale.identifier, lexicon: Localized.lexicon(locale: locale))
    }

    private var dayText: Text {
        if let presentationDate { return Text(verbatim: style(.days).format(presentationDate)) }
        return Text(.currentDate, format: style(.days))
    }

    private var clockText: Text {
        guard let presentationDate else { return Text(.currentDate, format: style(.clock)) }
        let end = PresentationSchedule.clockEnd(for: milestone, at: presentationDate)
        let start = min(presentationDate, end.addingTimeInterval(-1))
        let prefix = PresentationSchedule.clockPrefix(for: milestone, at: presentationDate)
        // Only Apple-defined format types can be decoded in the widget renderer.
        return Text("\(prefix)\(Text(.currentDate, format: .timer(countingDownIn: start..<end)))")
    }

    private func unitText(_ component: CountdownFormatStyle.Component) -> Text {
        if let presentationDate { return Text(verbatim: style(component).format(presentationDate)) }
        return Text(.currentDate, format: style(component))
    }

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width.isFinite ? max(0, geometry.size.width) : 0
            if milestone.countdownMode == .clock {
                VStack(alignment: .leading, spacing: 3) {
                    dayText
                        .font(.system(size: compact ? 27 : 35, weight: .medium, design: .rounded))
                        .frame(width: width, alignment: .leading)
                        .minimumScaleFactor(0.55).lineLimit(1)
                    clockText
                        .font(.system(size: compact ? 21 : 27, weight: .regular, design: .rounded))
                        .frame(width: width, alignment: .leading)
                        .foregroundStyle(.white.opacity(0.85)).lineLimit(1).minimumScaleFactor(0.6)
                }.monospacedDigit()
            } else {
                let amount = unitText(.value)
                let label = unitText(.unit)
                    .font(.system(size: compact ? 14 : 18, weight: .medium))
                    .foregroundStyle(.white.opacity(0.85))
                Text("\(amount) \(label)")
                    .font(.system(size: compact ? 45 : 58, weight: .medium, design: .rounded))
                    .frame(width: width, alignment: .leading)
                    .minimumScaleFactor(0.35).lineLimit(1).monospacedDigit()
            }
        }
        .frame(height: milestone.countdownMode == .clock ? (compact ? 59 : 74) : (compact ? 55 : 70))
    }
}

struct MilestoneCardContent: View {
    var milestone: Milestone?
    var compact = false
    var presentationDate: Date? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 8 : 10) {
            HStack(spacing: 5) {
                Image(systemName: "hourglass")
                Text("Life Is Short")
            }
            .font(.system(size: 10, weight: .semibold)).tracking(1.1)
            .foregroundStyle(.white.opacity(0.78))
            Spacer(minLength: 3)
            if let milestone {
                Text(verbatim: milestone.title)
                    .font(.system(size: compact ? 15 : 20, weight: .semibold))
                    .lineLimit(2).minimumScaleFactor(0.75)
                CountdownLabel(milestone: milestone, presentationDate: presentationDate, compact: compact)
            } else {
                Image(systemName: "sparkles").font(.title2)
                Text("Make today count.").font(compact ? .subheadline.weight(.semibold) : .headline)
                    .lineLimit(2).minimumScaleFactor(0.8)
                Text("Choose milestones in the app.")
                    .font(.caption).foregroundStyle(.white.opacity(0.8)).lineLimit(3).minimumScaleFactor(0.8)
            }
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

struct MilestoneCard: View {
    var milestone: Milestone?
    var compact = false

    var body: some View {
        MilestoneCardContent(milestone: milestone, compact: compact)
            .padding(compact ? 16 : 22)
            .background { MilestoneBackground(milestone: milestone) }
            .clipShape(.rect(cornerRadius: 24))
    }
}
