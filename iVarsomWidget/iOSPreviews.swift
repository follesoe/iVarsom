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

#Preview("Rectangular", as: .accessoryRectangular) {
    iVarsomWidget()
} timeline: {
    createEntry(currentWarning: testWarnings[0],
                allWarnings: testWarnings)
}

#Preview("Error State Small", as: .systemSmall) {
    iVarsomWidget()
} timeline: {
    errorEntry
}

#Preview("Level 2 Small", as: .systemSmall) {
    iVarsomWidget()
} timeline: {
    createEntry(currentWarning: testWarningLevel2,
                allWarnings: [testWarningLevel2])
}

#Preview("Level 3 Small", as: .systemSmall) {
    iVarsomWidget()
} timeline: {
    createEntry(currentWarning: testWarningLevel3,
                allWarnings: [testWarningLevel3])
}

#Preview("Level 4 Medium", as: .systemMedium) {
    iVarsomWidget()
} timeline: {
    createEntry(currentWarning: testWarningLevel4,
                allWarnings: [testWarningLevel4])
}

#Preview("Level 0 Medium", as: .systemMedium) {
    iVarsomWidget()
} timeline: {
    createEntry(currentWarning: testWarningLevel0,
                allWarnings: [testWarningLevel0])
}

#Preview("Large", as: .systemLarge) {
    iVarsomWidget()
} timeline: {
    createEntry(currentWarning: testWarnings[0],
                allWarnings: testWarnings)
}
