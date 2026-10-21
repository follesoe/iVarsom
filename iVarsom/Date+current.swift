import Foundation

extension Date {
    /// Forecast clock. Tests inject clocks; a Debug launch can preview a past
    /// season with SKREDVARSEL_PREVIEW_DATE=2026-02-21T12:00:00Z.
    static var current: Date {
        #if DEBUG
            if let previewDate { return previewDate }
        #endif
        return Date()
    }

    #if DEBUG
        static var previewDate: Date? {
            // Shared preferences let a simulator capture use the same historical
            // clock in the app and its separately launched widget extension.
            guard let value = ProcessInfo.processInfo.environment["SKREDVARSEL_PREVIEW_DATE"]
                ?? UserDefaults(suiteName: "group.no.follesoe.iVarsom")?.string(forKey: "SKREDVARSEL_PREVIEW_DATE")
            else { return nil }
            return ISO8601DateFormatter().date(from: value)
        }
    #endif
}
