import Foundation
import CoreLocation

struct RegionGeoData: Sendable {
    let features: [Feature]

    struct Feature: Sendable {
        let id: Int
        let name: String
        let country: String
        let polygons: [[CLLocationCoordinate2D]]
    }

    func polygon(for regionId: Int) -> [[CLLocationCoordinate2D]]? {
        features.first { $0.id == regionId }?.polygons
    }

    static func load() -> RegionGeoData? {
        guard let url = Bundle.main.url(forResource: "regions", withExtension: "geojson"),
              let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let features = json["features"] as? [[String: Any]] else {
            return nil
        }

        let parsed = features.compactMap { parseFeature($0) }
        return RegionGeoData(features: parsed)
    }

    private static func parseFeature(_ json: [String: Any]) -> Feature? {
        guard let properties = json["properties"] as? [String: Any],
              let id = properties["id"] as? Int,
              let geometry = json["geometry"] as? [String: Any],
              let type = geometry["type"] as? String else {
            return nil
        }

        let name = properties["name"] as? String ?? ""
        let country = properties["country"] as? String ?? ""
        let polygons: [[CLLocationCoordinate2D]]

        switch type {
        case "Polygon":
            guard let coordinates = geometry["coordinates"] as? [[[Double]]] else { return nil }
            polygons = coordinates.map { ring in
                ring.map { CLLocationCoordinate2D(latitude: $0[1], longitude: $0[0]) }
            }
        case "MultiPolygon":
            guard let coordinates = geometry["coordinates"] as? [[[[Double]]]] else { return nil }
            polygons = coordinates.flatMap { polygon in
                polygon.map { ring in
                    ring.map { CLLocationCoordinate2D(latitude: $0[1], longitude: $0[0]) }
                }
            }
        default:
            return nil
        }

        return Feature(id: id, name: name, country: country, polygons: polygons)
    }
}
