import Foundation

/// Wire formats are kept separate from the application's warning models.
enum LavinprognoserResponse {
    struct OverviewResponse: Codable {
        let content: OverviewContent
    }

    struct OverviewContent: Codable {
        let areaPageLinksArea: AreaPageLinksArea
    }

    struct AreaPageLinksArea: Codable {
        let areaPageLinks: [AreaPageLink]
    }

    struct AreaPageLink: Codable {
        let areaName: String
        let areaId: Int
        let risk: Int
        let url: String
        let riskText: String?
    }

    struct DetailResponse: Codable {
        let content: DetailContent
    }

    struct DetailContent: Codable {
        /// Null for a day without a bulletin, such as before the archive starts.
        let forecast: LavinForecast?

        init(from decoder: any Decoder) throws {
            // The key must be present, so a changed response isn't mistaken
            // for a day without a bulletin.
            let container = try decoder.container(keyedBy: CodingKeys.self)
            forecast = try container.decode(LavinForecast?.self, forKey: .forecast)
        }
    }

    struct LavinForecast: Codable {
        let id: Int
        let risk: Int
        let riskLabel: String?
        let areaId: Int
        let validTo: String
        let validFrom: String
        let changeDate: String?
        let publishedDate: String
        let location: String
        let recommendation: String?
        let assessmentContent: String?
        let avalancheProblem: LavinAvalancheProblemContainer?
    }

    struct LavinAvalancheProblemContainer: Codable {
        let problems: [LavinProblem]?
    }

    struct LavinProblem: Codable {
        let index: Int
        let problemId: Int
        let direction: LavinDirection
        let altitude: LavinAltitude
        let spread: LavinSpread?
        let description: LavinProblemDescription?
        let position: LavinPosition?
        let information: [LavinInformation]?
    }

    struct LavinDirection: Codable {
        let northPanel: LavinPanel
        let northEastPanel: LavinPanel
        let eastPanel: LavinPanel
        let southEastPanel: LavinPanel
        let southPanel: LavinPanel
        let southWestPanel: LavinPanel
        let westPanel: LavinPanel
        let northWestPanel: LavinPanel
    }

    struct LavinPanel: Codable {
        let state: Bool
    }

    struct LavinAltitude: Codable {
        let altitudeMeterAboveTreeline: LavinAltitudeLevel
        let altitudeMeterTreeline: LavinAltitudeLevel
        let altitudeMeterBelowTreeline: LavinAltitudeLevel
    }

    struct LavinAltitudeLevel: Codable {
        let state: Bool
    }

    struct LavinSpread: Codable {
        let spreadId: Int?
        let sensitivityId: Int?
        let sizeMeterValue: Int?
        let spread: String?
        let sensitivity: String?
    }

    struct LavinProblemDescription: Codable {
        let title: String?
    }

    struct LavinPosition: Codable {
        let content: String?
    }

    struct LavinInformation: Codable {
        let text: String?
        let description: String?
    }
}
