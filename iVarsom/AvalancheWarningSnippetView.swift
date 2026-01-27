import SwiftUI

struct AvalancheWarningSnippetView: View {
    let warning: AvalancheWarningSimple?
    let error: String?

    var body: some View {
        if let warning = warning {
            HStack(spacing: 16) {
                DangerIcon(dangerLevel: warning.DangerLevel)
                    .frame(width: 60, height: 60)

                VStack(alignment: .leading, spacing: 4) {
                    Text(warning.RegionName)
                        .font(.headline)

                    Text(LocalizedStringKey(warning.DangerLevelName))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(warning.ValidFrom, style: .date)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

                Spacer()
            }
            .padding()
        } else if let error = error {
            HStack {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundStyle(.orange)
                Text(error)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
    }
}
