import Foundation

enum Country {
    case norway
    case sweden

    private static let swedenOffset = 100000

    static let swedishAreaSlugs: [Int: String] = [
        1: "vastra_vindelfjallen",
        2: "abisko_riksgransfjallen",
        3: "sodra_jamtlandsfjallen",
        7: "vastra_harjedalsfjallen",
        8: "kebnekaisefjallen",
        9: "sodra_lapplandsfjallen"
    ]

    static func from(regionId: Int) -> Country {
        return regionId >= swedenOffset ? .sweden : .norway
    }

    static func swedishAreaId(from regionId: Int) -> Int {
        return regionId - swedenOffset
    }

    static func syntheticId(from areaId: Int) -> Int {
        return areaId + swedenOffset
    }

    static func swedishSlug(for regionId: Int) -> String? {
        return swedishAreaSlugs[swedishAreaId(from: regionId)]
    }
}
