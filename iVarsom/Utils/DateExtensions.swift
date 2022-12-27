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
}
