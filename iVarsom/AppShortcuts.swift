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
        AppShortcut(
            intent: OpenRegionIntent(region: RegionConfigOptionAppEntity(RegionOption.currentPositionOption)),
            phrases: ["Open my local forecast in \(.applicationName)"],
            shortTitle: "Open local forecast",
            systemImageName: "location.circle")
    }
}
