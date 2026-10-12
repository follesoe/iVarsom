import SwiftUI

struct WarningDayPicker: View {
    let warnings: [AvalancheWarningDetailed]
    @Binding var selectedWarningID: Int?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(warnings) { warning in
                        Button {
                            selectedWarningID = warning.id
                        } label: {
                            DayCell(
                                dangerLevel: warning.DangerLevel, date: warning.ValidFrom,
                                isSelected: selectedWarningID == warning.id,
                                hasEmergencyWarning: warning.hasActiveEmergencyWarning,
                                regionID: warning.RegionId,
                                showsDayLabel: true
                            )
                            .fixedSize()
                            .padding(.top, 5)
                        }
                        .id(warning.id)
                        .buttonStyle(.plain)
                        .speechLocale(for: warning.RegionId)
                    }
                }
            }
            .onChange(of: selectedWarningID, initial: true) { _, id in
                if let id {
                    withAnimation(reduceMotion ? nil : .default) { proxy.scrollTo(id, anchor: .center) }
                }
            }
        }
    }
}
