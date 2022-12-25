import WidgetKit
import SwiftUI
import Intents
import CoreLocation
import DynamicColor

struct iVarsomWidget_iOS_Previews: PreviewProvider {
    static var previews: some View {
        let level3 = WarningEntry(
            date: Date(),
            currentWarning: testWarningLevel3,
            warnings: [testWarningLevel3],
            configuration: SelectRegionIntent(),
            relevance: TimelineEntryRelevance(score: 1.0));
        
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
            
            WarningWidgetView(entry: Provider().errorEntry())
                .previewDisplayName("Circular")
                .previewContext(WidgetPreviewContext(family: .accessoryCircular))
            
            WarningWidgetView(entry: fullWarning)
            .previewDisplayName("Rectangular")
            .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
            
            WarningWidgetView(entry: Provider().errorEntry())
                .previewDisplayName("Error State Small")
                .previewContext(WidgetPreviewContext(family: .systemSmall))
            
            WarningWidgetView(entry: WarningEntry(
                    date: Date(),
                    currentWarning: testWarningLevel2,
                    warnings: [testWarningLevel2],
                    configuration: SelectRegionIntent(),
                    relevance: TimelineEntryRelevance(score: 1.0)))
                .previewDisplayName("Level 2 Small")
                .previewContext(WidgetPreviewContext(family: .systemSmall))
            
            WarningWidgetView(entry: WarningEntry(
                    date: Date(),
                    currentWarning: testWarningLevel3,
                    warnings: [testWarningLevel3],
                    configuration: SelectRegionIntent(),
                    relevance: TimelineEntryRelevance(score: 1.0)))
                .previewDisplayName("Level 3 Small")
                .previewContext(WidgetPreviewContext(family: .systemSmall))

            WarningWidgetView(entry: WarningEntry(
                    date: Date(),
                    currentWarning: testWarningLevel4,
                    warnings: [testWarningLevel4],
                    configuration: SelectRegionIntent(),
                    relevance: TimelineEntryRelevance(score: 1.0)))
                .previewDisplayName("Level 4 Medium")
                .previewContext(WidgetPreviewContext(family: .systemMedium))
            
            WarningWidgetView(entry: WarningEntry(
                    date: Date(),
                    currentWarning: testWarningLevel0,
                    warnings: [testWarningLevel0],
                    configuration: SelectRegionIntent(),
                    relevance: TimelineEntryRelevance(score: 1.0)))
                .previewDisplayName("Level 0 Medium")
                .previewContext(WidgetPreviewContext(family: .systemMedium))
            
            WarningWidgetView(entry: fullWarning)
                .previewDisplayName("Large")
                .previewContext(WidgetPreviewContext(family: .systemLarge))
        }
    }
}
