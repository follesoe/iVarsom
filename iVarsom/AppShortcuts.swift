import AppIntents

struct SkredvarselShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: GetAvalancheWarningIntent(),
            phrases: [
                "Get avalanche warning in \(.applicationName)",
                "Avalanche warning from \(.applicationName)",
                "Get avalanche warning for \(\.$region) in \(.applicationName)",
                "What is the avalanche danger in \(\.$region) with \(.applicationName)"
            ],
            shortTitle: LocalizedStringResource("Check warning"),
            systemImageName: "mountain.2"
        )
        // One parameter per phrase, and only regions or enums: Siri phrases can't
        // contain dates. Shortcuts offers the date intent's full date parameter.
        AppShortcut(
            intent: GetAvalancheWarningIntent(day: .tomorrow),
            phrases: ["What is the avalanche danger tomorrow in \(\.$region) with \(.applicationName)"],
            shortTitle: "Tomorrow's Forecast",
            systemImageName: "calendar"
        )
        AppShortcut(
            intent: GetFavoriteForecastsIntent(),
            phrases: [
                "Get avalanche warnings for my favorites in \(.applicationName)",
                "What is the avalanche danger in my favorites with \(.applicationName)",
            ],
            shortTitle: "Favorite Forecasts",
            systemImageName: "star"
        )
        AppShortcut(
            intent: GetAvalancheWarningForDateIntent(pastDay: .yesterday),
            phrases: ["What was the avalanche danger in \(\.$region) yesterday with \(.applicationName)"],
            shortTitle: "Yesterday's Forecast",
            systemImageName: "clock.arrow.circlepath"
        )
        AppShortcut(
            intent: GetAvalancheWarningForDateIntent(),
            phrases: [
                "What was the avalanche danger \(\.$pastDay) with \(.applicationName)",
                "Get an earlier avalanche warning for \(\.$region) in \(.applicationName)",
            ],
            shortTitle: "Earlier Forecast",
            systemImageName: "calendar.badge.clock"
        )
        AppShortcut(
            intent: OpenRegionIntent(region: RegionConfigOptionAppEntity(RegionOption.currentPositionOption)),
            phrases: ["Open my local forecast in \(.applicationName)"],
            shortTitle: "Open local forecast",
            systemImageName: "location.circle")
    }
}
