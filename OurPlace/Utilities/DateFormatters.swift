import Foundation

/// Shared date formatters to avoid creating multiple instances
struct DateFormatters {

    /// Standard date format: "dd.MM.yyyy" (e.g., "25.12.2024")
    static let standard: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter
    }()

    /// Short date format: "dd.MM.yy" (e.g., "25.12.24")
    static let short: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yy"
        return formatter
    }()

    /// Month and year format: "MMMM yyyy" (e.g., "December 2024")
    static let monthYear: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()

    /// Event format with time: "dd.MM.yyyy • hh:mma" (e.g., "25.12.2024 • 03:30PM")
    static let eventDateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy • hh:mma"
        return formatter
    }()

    /// Relative date format using default style
    static let relative: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    /// ISO format for data storage
    static let iso: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        return formatter
    }()

    /// Time only format: "3:30 PM"
    static let timeOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()

    /// Full date format: "Monday, January 1, 2024"
    static let fullDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter
    }()

    /// Time range format (no date): "3:30 PM"
    static let timeRange: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
}