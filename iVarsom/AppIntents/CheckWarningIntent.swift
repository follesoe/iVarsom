import AppIntents
import SwiftUI

struct CheckWarningIntent: AppIntent {
    static let title: LocalizedStringResource = "Check Avalanche Warning"
    
    @Parameter(title: "Date")
    var date: Date?
    
    @Parameter(title: "Region")
    var region: RegionOption?
    
    func perform() async throws -> some ReturnsValue & ProvidesDialog & ShowsSnippetView {
        let locationManager = LocationManager()
        let client = VarsomApiClient()
        
        let date = date ?? Date()
        
        if region == nil && locationManager.isAuthorized {
            region = RegionOption.currentPositionOption
        }
                
        guard let region = region else {
            throw $region.needsValueError("Which region would you like look up?")
        }
        
        var warnings: [AvalancheWarningSimple]
        if region.id == RegionOption.currentPositionOption.id {
            let location = try await locationManager.updateLocation()
            warnings = try await client.loadWarnings(lang: Language.fromLocale(), coordinate: location, from: date, to: date)
        } else {
            warnings = try await client.loadWarnings(lang: Language.fromLocale(), regionId: region.id, from: date, to: date)
        }
        
        var warning: AvalancheWarningSimple = testWarningLevel3
        warning.ValidFrom = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        
        if warnings.count > 0 {
            warning = warnings[0]
        } else {
            warning = testWarningLevel3
        }
        
        return .result(
            value: warning.DangerLevelName,
            dialog: createDialog(warning: warning),
            view: WarningSummary(warning: warning))
    }
    
    func createDialog(warning: AvalancheWarningSimple) -> IntentDialog {
        let relativeFormatter = DateFormatter()
        relativeFormatter.timeStyle = .none
        relativeFormatter.dateStyle = .short
        relativeFormatter.doesRelativeDateFormatting = true
        
        let warningDate = relativeFormatter.string(from: warning.ValidFrom).lowercased()
        let dangerLevel = Int(warning.DangerLevelNumeric)
        
        if Language.fromLocale() == .norwegian {
            return "\(warning.RegionName) har \(warningDate) \(warning.DangerLevelName.lowercased()) skredfare, faregrad \(dangerLevel). \(warning.MainText)"
        } else {
            return "\(warning.RegionName) has danger level \(dangerLevel) \(warning.DangerLevelName.lowercased()) \(warningDate). \(warning.MainText)"
        }
    }
    
    static var parameterSummary: some ParameterSummary {
        Summary("Show avalanche warning on \(\.$date) for region \(\.$region).")
    }
}
