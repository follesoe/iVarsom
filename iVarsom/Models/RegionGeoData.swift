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

    /// Find the A-region containing the coordinate, or the nearest one within `maxDistance` meters.
    func findNearestRegion(at coordinate: CLLocationCoordinate2D, maxDistance: CLLocationDistance = 100_000) -> Feature? {
        // First: exact polygon hit
        for feature in features {
            for polygon in feature.polygons {
                if RegionGeoData.pointInPolygon(point: coordinate, polygon: polygon) {
                    return feature
                }
            }
        }

        // Fallback: nearest region by centroid distance
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        var bestFeature: Feature?
        var bestDistance: CLLocationDistance = .greatestFiniteMagnitude

        for feature in features {
            let c = RegionGeoData.centroid(of: feature.polygons)
            let dist = location.distance(from: CLLocation(latitude: c.latitude, longitude: c.longitude))
            if dist < bestDistance {
                bestDistance = dist
                bestFeature = feature
            }
        }

        if bestDistance <= maxDistance {
            return bestFeature
        }
        return nil
    }

    static func pointInPolygon(point: CLLocationCoordinate2D, polygon: [CLLocationCoordinate2D]) -> Bool {
        let n = polygon.count
        guard n >= 3 else { return false }
        var inside = false
        var j = n - 1
        for i in 0..<n {
            let yi = polygon[i].latitude
            let xi = polygon[i].longitude
            let yj = polygon[j].latitude
            let xj = polygon[j].longitude
            if ((yi > point.latitude) != (yj > point.latitude)) &&
                (point.longitude < (xj - xi) * (point.latitude - yi) / (yj - yi) + xi) {
                inside.toggle()
            }
            j = i
        }
        return inside
    }

    static func centroid(of polygons: [[CLLocationCoordinate2D]]) -> CLLocationCoordinate2D {
        var totalLat = 0.0
        var totalLon = 0.0
        var count = 0
        for polygon in polygons {
            for coord in polygon {
                totalLat += coord.latitude
                totalLon += coord.longitude
                count += 1
            }
        }
        guard count > 0 else {
            return CLLocationCoordinate2D(latitude: 65, longitude: 14)
        }
        return CLLocationCoordinate2D(latitude: totalLat / Double(count), longitude: totalLon / Double(count))
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
