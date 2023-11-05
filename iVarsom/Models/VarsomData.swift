import Foundation
import SwiftUI

class VarsomData: ObservableObject {
    @Published var regions = [RegionSummary]()
    @Published var warnings = [AvalancheWarningSimple]()
    @Published var days = [String]()

    var language: VarsomApiClient.Language {
        return Locale.current.identifier == "nb" ? .norwegian : .english
    }
    
    private let apiClient = VarsomApiClient()
    
    init(regions: [RegionSummary] = []) {
        self.regions = regions
    }
    
    func loadRegions() async throws {
        let regions = try await apiClient.loadRegions(lang: language)
        
        if (regions.count > 0) {
            let dayFormatter = DateFormatter()
            dayFormatter.locale = Locale.current
            dayFormatter.dateFormat = "EEE"
            let days = regions[0].AvalancheWarningList.map {
                dayFormatter.string(from: $0.ValidFrom)
            }
            
            DispatchQueue.main.async {
                self.days = days
            }
        }
                    
        let aRegions = regions.filter { reg in
            reg.TypeName == "A"
        }
        
        DispatchQueue.main.async {
            self.regions = aRegions
        }
    }
    
    func loadWarnings(id: Int) async throws {
        let from = Date.now()
        let to = Calendar.current.date(byAdding: .day, value: 2, to: from)!
        
        let warnings = try await apiClient.loadWarnings(
            lang: language,
            regionId: id,
            from: from,
            to: to)
        DispatchQueue.main.async {
            self.warnings = warnings
        }
    }
}

let testRegions: [RegionSummary] = load("RegionSummary.json")
let testARegions = testRegions.filter { sum in
    sum.TypeName == "A"
}

let testVarsomData = VarsomData(regions: testARegions)

let testWarning = testARegions[0].AvalancheWarningList[0]

let testWarningLevel0 = AvalancheWarningSimple(
    RegId: 1,
    RegionId: 3020,
    RegionName: "Sør Trøndelag",
    RegionTypeName: "B",
    ValidFrom: Date.now(),
    ValidTo: Date.now(),
    NextWarningTime: Date.now(),
    PublishTime: Date.now(),
    DangerLevel: .unknown,
    MainText: "No Rating",
    LangKey: 2)

let testWarningLevel1 = (testARegions.filter { reg in
    reg.Id == 3035
})[0].AvalancheWarningList[2]

let testWarningLevel2 = (testARegions.filter { reg in
    reg.Id == 3003
})[0].AvalancheWarningList[0]

let testWarningLevel3 = (testARegions.filter { reg in
    reg.Id == 3007
})[0].AvalancheWarningList[0]

let testWarningLevel4 = (testARegions.filter { reg in
    reg.Id == 3015
})[0].AvalancheWarningList[0]

func createTestWarnings() -> [AvalancheWarningSimple] {
    let startDate = Calendar.current.date(byAdding: .day, value: -1, to: Date.now())!
    
    var warnings: [AvalancheWarningSimple] = []
    let levels: [DangerLevel] = [.level2, .level3, .level4, .level3, .level2]
    for i in 0...4 {
        let warningDate = Calendar.current.date(byAdding: .day, value: i, to: startDate)!

        print(warningDate)
        let warning = AvalancheWarningSimple(
            RegId: i,
            RegionId: 1,
            RegionName: "Vest-Finnmark",
            RegionTypeName: "A",
            ValidFrom: warningDate,
            ValidTo: warningDate,
            NextWarningTime: warningDate,
            PublishTime: warningDate,
            DangerLevel: levels[i],
            MainText: "No Rating",
            LangKey: 2)
        warnings.append(warning)
    }
    return warnings
}
