import Foundation

extension Date {
    func getDayName() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.setLocalizedDateFormatFromTemplate("EEEE")
        return dateFormatter.string(from: self)
    }
    
    func getDayNameAbbr() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.setLocalizedDateFormatFromTemplate("EEE")
        return dateFormatter.string(from: self)
    }
    
    func getRelativeDayNameAbbr() -> String {
        let relativeFormatter = DateFormatter()
        relativeFormatter.timeStyle = .none
        relativeFormatter.dateStyle = .short
        relativeFormatter.doesRelativeDateFormatting = true
        return relativeFormatter.string(from: self).firstUppercased
    }
    
    init(year: Int, month: Int, day: Int, hour: Int = 0, minute: Int = 0, second: Int = 0) {
        var dateComponents = DateComponents()
        dateComponents.month = month
        dateComponents.day = day
        dateComponents.year = year
        dateComponents.hour = hour
        dateComponents.minute = minute
        dateComponents.second = second
        dateComponents.timeZone = .current
        dateComponents.calendar = .current
        self = Calendar.current.date(from: dateComponents) ?? Date()
    }
    
    public static func now() -> Date {
        // Uncomment to test with a date with allot of warnings.
        // return Date(year: 2023, month: 3, day: 3, hour: 16, minute: 0, second: 0)
        return Date()
    }
}
