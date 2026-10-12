import SwiftUI

struct AvalancheWarningSnippetView: View {
    let warning: AvalancheWarningSimple?
    let error: String?
    var downloadedAt: Date? = nil
    var isCached = false

    var body: some View {
        if let warning = warning {
#if os(watchOS)
            VStack(spacing: 4) {
                DangerIcon(dangerLevel: warning.DangerLevel)
                    .frame(width: 36, height: 36)

                Text(warning.RegionName)
                    .font(.footnote.bold())
                    .multilineTextAlignment(.center)

                Text(LocalizedStringKey(warning.DangerLevelName))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(warning.ValidFrom, style: .date).font(.caption2)
                if isCached { Text("Saved forecast").font(.caption2) }
            }
            .padding(.vertical, 8)
#else
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
                    if isCached { Text("Saved forecast").font(.caption2) }
                    if let downloadedAt {
                        Text(downloadedAt, format: .dateTime.day().month(.abbreviated).hour().minute())
                            .font(.caption2)
                    }
                }

                Spacer()
            }
            .padding()
#endif
        } else if let error = error {
            HStack {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundStyle(.orange)
                Text(error)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
    }
}
