import Foundation

@MainActor
class ReviewPromptService {
    private let defaults: UserDefaults
    private let sessionCountKey = "reviewSessionCount"
    private let distinctRegionsKey = "reviewDistinctRegions"
    private let lastPromptDateKey = "reviewLastPromptDate"

    private let requiredSessions = 5
    private let requiredDistinctRegions = 3
    private let promptCooldownDays = 120

    init(defaults: UserDefaults = FavoritesService.sharedDefaults) {
        self.defaults = defaults
    }

    func recordSession() {
        let count = defaults.integer(forKey: sessionCountKey)
        defaults.set(count + 1, forKey: sessionCountKey)
    }

    func recordRegionView(regionId: Int) {
        var regions = defaults.object(forKey: distinctRegionsKey) as? [Int] ?? []
        if !regions.contains(regionId) {
            regions.append(regionId)
            defaults.set(regions, forKey: distinctRegionsKey)
        }
    }

    func shouldPrompt(favoriteCount: Int, locationAuthorized: Bool) -> Bool {
        let sessionCount = defaults.integer(forKey: sessionCountKey)
        guard sessionCount >= requiredSessions else { return false }

        let distinctRegions = (defaults.object(forKey: distinctRegionsKey) as? [Int])?.count ?? 0
        let hasEngagement = favoriteCount >= 1 || locationAuthorized || distinctRegions >= requiredDistinctRegions
        guard hasEngagement else { return false }

        if let lastPrompt = defaults.object(forKey: lastPromptDateKey) as? Date {
            let daysSince = Calendar.current.dateComponents([.day], from: lastPrompt, to: Date()).day ?? 0
            guard daysSince >= promptCooldownDays else { return false }
        }

        return true
    }

    func recordPrompt() {
        defaults.set(Date(), forKey: lastPromptDateKey)
    }
}
