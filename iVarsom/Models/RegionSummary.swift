import Foundation
import SwiftUI

struct RegionSummary: Sendable {
    var Id: Int
    var Name: String
    var TypeName: String
    var AvalancheWarningList: [AvalancheWarningSimple]
}

extension RegionSummary: Identifiable, Codable, Hashable {
    var id: Int { return Id }

    static func == (lhs: RegionSummary, rhs: RegionSummary) -> Bool {
        return lhs.Id == rhs.Id && lhs.Name == rhs.Name && lhs.TypeName == rhs.TypeName
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(Id)
        hasher.combine(Name)
        hasher.combine(TypeName)
    }
}

// MARK: - Danger Trend

enum DangerTrend: Sendable {
    case rising(color: Color)
    case stable(color: Color)
    case falling(color: Color)

    var symbolName: String {
        switch self {
        case .rising: return "arrow.up.right"
        case .stable: return "arrow.right"
        case .falling: return "arrow.down.right"
        }
    }

    var color: Color {
        switch self {
        case .rising(let color), .stable(let color), .falling(let color):
            return color
        }
    }

    var localizedDescription: String {
        switch self {
        case .rising: return String(localized: "Danger rising")
        case .stable: return String(localized: "Danger stable")
        case .falling: return String(localized: "Danger falling")
        }
    }
}

extension RegionSummary {
    var dangerTrend: DangerTrend? {
        guard AvalancheWarningList.count >= 2 else { return nil }
        let today = AvalancheWarningList[0].DangerLevel
        let tomorrow = AvalancheWarningList[1].DangerLevel
        guard today != .unknown, tomorrow != .unknown else { return nil }

        // Use the furthest-out day for color if known, otherwise fall back to tomorrow
        let furthest: DangerLevel
        if AvalancheWarningList.count >= 3, AvalancheWarningList[2].DangerLevel != .unknown {
            furthest = AvalancheWarningList[2].DangerLevel
        } else {
            furthest = tomorrow
        }
        let trendColor = max(today, max(tomorrow, furthest)).color

        if tomorrow > today {
            return .rising(color: trendColor)
        } else if tomorrow < today {
            return .falling(color: trendColor)
        } else {
            return .stable(color: trendColor)
        }
    }
}

struct DangerTrendIndicator: View {
    let trend: DangerTrend

    var body: some View {
        Image(systemName: trend.symbolName)
            .foregroundStyle(trend.color)
            .font(.caption.weight(.heavy))
            .accessibilityHidden(true)
    }
}
