import WidgetKit
import SwiftUI
import Intents
import CoreLocation
import DynamicColor

struct iVarsomWidget_iOS_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            WarningWidgetView(entry: WarningEntry(
                date: Date(),
                currentWarning: testWarningLevel3,
                warnings: [testWarningLevel3],
                configuration: SelectRegionIntent(),
                relevance: TimelineEntryRelevance(score: 1.0)))
            .previewDisplayName("Inline")
            .previewContext(WidgetPreviewContext(family: .accessoryInline))
            
            WarningWidgetView(entry: Provider().errorEntry())
                .previewDisplayName("Circle")
                .previewContext(WidgetPreviewContext(family: .accessoryCircular))
            
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
            
            WarningWidgetView(entry: WarningEntry(
                    date: Date(),
                    currentWarning: testWarningLevel2,
                    warnings: [
                        testWarningLevel0,
                        testWarningLevel1,
                        testWarningLevel2,
                        testWarningLevel3,
                        testWarningLevel4],
                    configuration: SelectRegionIntent(),
                    relevance: TimelineEntryRelevance(score: 1.0)))
                .previewDisplayName("Large")
                .previewContext(WidgetPreviewContext(family: .systemLarge))
        }
    }
}
