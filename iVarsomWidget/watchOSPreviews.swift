import WidgetKit
import SwiftUI
import Intents
import CoreLocation
import DynamicColor

struct iVarsomWidget_watchOS_Previews: PreviewProvider {
    static var previews: some View {
        let level3 = WarningEntry(
            date: Date(),
            currentWarning: testWarningLevel3,
            warnings: [testWarningLevel3],
            configuration: SelectRegionIntent(),
            relevance: TimelineEntryRelevance(score: 1.0))
        
        let testWarnings = createTestWarnings()
        let fullWarning = WarningEntry(
                date: Date(),
                currentWarning: testWarnings[1],
                warnings: testWarnings,
                configuration: SelectRegionIntent(),
                relevance: TimelineEntryRelevance(score: 1.0))
        
        Group {
            WarningWidgetView(entry: level3)
            .previewDisplayName("Inline")
            .previewContext(WidgetPreviewContext(family: .accessoryInline))
            
            WarningWidgetView(entry: level3)
                .previewDisplayName("Circular")
                .previewContext(WidgetPreviewContext(family: .accessoryCircular))
            
            WarningWidgetView(entry: level3)
                .previewDisplayName("Corner")
                .previewContext(WidgetPreviewContext(family: .accessoryCorner))
            
            WarningWidgetView(entry: fullWarning)
                .previewDisplayName("Rectangular")
                .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
        }
    }
}
