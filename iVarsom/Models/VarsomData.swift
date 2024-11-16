import Foundation
import SwiftUI

@MainActor
let testRegions: [RegionSummary] = load("RegionSummary.json")

@MainActor
let testARegions = testRegions.filter { region in
    region.TypeName == "A"
}

@MainActor
let testWarning = testARegions[0].AvalancheWarningList[0]

@MainActor
let testWarningLevel0 = AvalancheWarningSimple(
    RegId: 1,
    RegionId: 3020,
    RegionName: "Sør Trøndelag",
    RegionTypeName: "B",
    ValidFrom: Date.current,
    ValidTo: Date.current,
    NextWarningTime: Date.current,
    PublishTime: Date.current,
    DangerLevel: .unknown,
    MainText: "No Rating",
    LangKey: 2)

@MainActor
let testWarningLevel1 = (testARegions.filter { reg in
    reg.Id == 3035
})[0].AvalancheWarningList[2]

@MainActor
let testWarningLevel2 = (testARegions.filter { reg in
    reg.Id == 3003
})[0].AvalancheWarningList[0]

@MainActor
let testWarningLevel3 = (testARegions.filter { reg in
    reg.Id == 3007
})[0].AvalancheWarningList[0]

@MainActor
let testWarningLevel4 = (testARegions.filter { reg in
    reg.Id == 3015
})[0].AvalancheWarningList[0]

func createTestWarnings() -> [AvalancheWarningSimple] {
    let startDate = Calendar.current.date(byAdding: .day, value: -1, to: Date.current)!
    
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
