import SwiftUI

struct WarningDayPicker: View {
    let warnings: [AvalancheWarningDetailed]
    @Binding var selectedWarningID: Int?

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(warnings) { warning in
                        Button {
                            withAnimation { selectedWarningID = warning.id }
                        } label: {
                            DayCell(
                                dangerLevel: warning.DangerLevel, date: warning.ValidFrom,
                                isSelected: selectedWarningID == warning.id,
                                hasEmergencyWarning: warning.hasActiveEmergencyWarning,
                                regionID: warning.RegionId
                            )
                            .padding(.top, 5)
                        }
                        .id(warning.id)
                        .buttonStyle(.plain)
                        .speechLocale(for: warning.RegionId)
                    }
                }
            }
            .onChange(of: selectedWarningID, initial: true) { _, id in
                if let id { withAnimation { proxy.scrollTo(id) } }
            }
        }
    }
}
