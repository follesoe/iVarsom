import Foundation
import SwiftUI

let testRegions: [RegionSummary] = load("RegionSummary.json")
let testARegions = testRegions.filter { sum in
    sum.TypeName == "A"
}

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
