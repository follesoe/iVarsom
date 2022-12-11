import WidgetKit
import SwiftUI
import Intents
import CoreLocation
import DynamicColor

struct iVarsomWidget_watchOS_Previews: PreviewProvider {
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
                .previewDevice("Apple Watch Series 8 (45mm)")
                .previewDisplayName("Circle Watch")
                .previewContext(WidgetPreviewContext(family: .accessoryCircular))
        }
    }
}
