import WidgetKit
import SwiftUI
import Intents
import CoreLocation

@MainActor
let testWarnings = createTestWarnings()

@MainActor
let errorEntry = Provider().errorEntry(errorMessage: "Error message")

func createEntry(currentWarning: AvalancheWarningSimple,
                 allWarnings: [AvalancheWarningSimple]) -> WarningEntry {
    return WarningEntry(
        date: Date.current,
        currentWarning: currentWarning,
        warnings: allWarnings,
        configuration: SelectRegion(),
        relevance: TimelineEntryRelevance(score: 1.0),
        hasError: false,
        errorMessage: nil);
}

#Preview("Inline", as: .accessoryInline) {
    iVarsomWidget()
} timeline: {
    createEntry(currentWarning: testWarningLevel3,
                allWarnings: [testWarningLevel3])
}

#Preview("Circular", as: .accessoryCircular) {
    iVarsomWidget()
} timeline: {
    createEntry(currentWarning: testWarningLevel3,
                allWarnings: [testWarningLevel3])
}

#Preview("Corner", as: .accessoryCorner) {
    iVarsomWidget()
} timeline: {
    createEntry(currentWarning: testWarningLevel3,
                allWarnings: [testWarningLevel3])
}

#Preview("Rectangular", as: .accessoryRectangular) {
    iVarsomWidget()
} timeline: {
    createEntry(currentWarning: testWarnings[0],
                allWarnings: testWarnings)
}

#Preview("Rectangular Error", as: .accessoryRectangular) {
    iVarsomWidget()
} timeline: {
    errorEntry
}
