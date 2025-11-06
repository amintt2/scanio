//
//  Date.swift
//  Aidoku
//
//  Created by Skitty on 6/17/22.
//

import Foundation

extension Date {
    func dateString(format: String) -> String? {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: self)
    }
}

// for komga extension
extension Date {
    //    var year: Int {
    //        Calendar.current.component(.year, from: self)
    //    }

    static func firstOf(year: Int) -> Date? {
        Calendar.current.date(from: DateComponents(year: year, month: 1, day: 1))
    }

    static func lastOf(year: Int) -> Date? {
        if let firstOfNextYear = Calendar.current.date(from: DateComponents(year: year + 1, month: 1, day: 1)) {
            return Calendar.current.date(byAdding: .day, value: -1, to: firstOfNextYear)
        }
        return nil
    }
}

extension Date {
    static func makeRelativeDate(days: Int) -> String {
        let now = Date()
        let date = now.addingTimeInterval(-86400 * Double(days))
        let difference = Calendar.autoupdatingCurrent.dateComponents(Set([Calendar.Component.day]), from: date, to: now)

        // today or yesterday
        if days <= 1 {
            let formatter = DateFormatter()
            formatter.locale = Locale.autoupdatingCurrent
            formatter.dateStyle = .medium
            formatter.doesRelativeDateFormatting = true
            return formatter.string(from: date)
        } else if days <= 7 { // n days ago
            let formatter = DateComponentsFormatter()
            formatter.unitsStyle = .short
            formatter.allowedUnits = .day
            guard let timePhrase = formatter.string(from: difference) else { return "" }
            return String(format: NSLocalizedString("%@_AGO", comment: ""), timePhrase)
        } else { // mm/dd/yy
            let formatter = DateFormatter()
            formatter.locale = Locale.autoupdatingCurrent
            formatter.dateStyle = .short
            return formatter.string(from: date)
        }
    }
}

extension Date {
    static func endOfDay() -> Date {
        let calendar = Calendar.autoupdatingCurrent
        let start = calendar.startOfDay(for: Date())
        return calendar.date(byAdding: .day, value: 1, to: start)!
    }

    static func startOfDay() -> Date {
        let calendar = Calendar.autoupdatingCurrent
        return calendar.startOfDay(for: Date())
    }
}

// MARK: - Supabase Date Decoding
extension JSONDecoder.DateDecodingStrategy {
    /// Custom date decoding strategy for Supabase PostgreSQL timestamps
    /// Supports formats like: "2024-01-15T10:30:00+00:00", "2024-01-15T10:30:00Z", "2024-01-15T10:30:00.123456+00:00"
    static var supabase: JSONDecoder.DateDecodingStrategy {
        return .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)

            // Try multiple formatters for different Supabase date formats
            let formatters: [ISO8601DateFormatter] = [
                // Format with fractional seconds and timezone
                {
                    let formatter = ISO8601DateFormatter()
                    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                    return formatter
                }(),
                // Format with timezone but no fractional seconds
                {
                    let formatter = ISO8601DateFormatter()
                    formatter.formatOptions = [.withInternetDateTime]
                    return formatter
                }(),
                // Format with Z timezone
                {
                    let formatter = ISO8601DateFormatter()
                    formatter.formatOptions = [.withInternetDateTime, .withTimeZone]
                    return formatter
                }()
            ]

            for formatter in formatters {
                if let date = formatter.date(from: dateString) {
                    return date
                }
            }

            // If all formatters fail, throw an error
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Expected date string to be ISO8601-formatted with timezone. Got: \(dateString)"
            )
        }
    }
}
