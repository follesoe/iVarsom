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
            shortTitle: LocalizedStringResource("Avalanche Warning"),
            systemImageName: "mountain.2"
        )
    }
}
