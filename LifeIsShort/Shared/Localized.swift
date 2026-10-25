import Foundation

enum Localized {
    static func text(_ key: String, locale: Locale = .current) -> String {
        String(localized: String.LocalizationValue(key), bundle: .main, locale: locale)
    }

    static func lexicon(locale: Locale) -> CountdownLexicon {
        CountdownLexicon(
            day: text("day", locale: locale), days: text("days", locale: locale),
            week: text("week", locale: locale), weeks: text("weeks", locale: locale),
            hour: text("hour", locale: locale), hours: text("hours", locale: locale),
            lessThan: "<1", separator: locale.language.languageCode?.identifier == "ja" ? "" : " "
        )
    }

    static func error(_ error: Error) -> String {
        switch error as? MilestoneError {
        case .emptyTitle: text("Enter a title for this milestone.")
        case .invalidAge: text("Enter a valid target age.")
        case .invalidDate: text("Choose a valid date and time.")
        case .invalidTimeZone: text("This time zone is unavailable. Please choose the target again.")
        case .selectionFull: text("Choose a milestone to replace in your widget.")
        default: text("Your changes could not be saved. Please try again.")
        }
    }
}
