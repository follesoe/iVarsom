import AppIntents

struct AppShortcuts: AppShortcutsProvider {
    @AppShortcutsBuilder
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CheckWarningIntent(),
            phrases: [
                "Sjekk \(.applicationName)",
                "Sjekk \(.applicationName) for \(\.$region)",
                "Sjekk \(.applicationName) for \(\.$region) i \(\.$date)",
                "Hva er \(.applicationName)?",
                "Hva er \(.applicationName) i \(\.$region)?",
                "Vis \(.applicationName) for \(\.$region)",
                "\(.applicationName)"
            ]
        )
    }
}
