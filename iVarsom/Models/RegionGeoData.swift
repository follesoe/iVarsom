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

    /// Find the A-region containing the coordinate, or the nearest one by polygon edge distance.
    func findNearestRegion(at coordinate: CLLocationCoordinate2D) -> Feature? {
        // First: exact polygon hit
        for feature in features {
            for polygon in feature.polygons {
                if RegionGeoData.pointInPolygon(point: coordinate, polygon: polygon) {
                    return feature
                }
            }
        }

        // Fallback: nearest region by distance to polygon edge
        var bestFeature: Feature?
        var bestDistance: CLLocationDistance = .greatestFiniteMagnitude

        for feature in features {
            for polygon in feature.polygons {
                let dist = RegionGeoData.minimumDistanceToEdge(from: coordinate, polygon: polygon)
                if dist < bestDistance {
                    bestDistance = dist
                    bestFeature = feature
                }
            }
        }

        return bestFeature
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

    /// Minimum distance in meters from a point to the nearest edge of a polygon.
    static func minimumDistanceToEdge(from point: CLLocationCoordinate2D, polygon: [CLLocationCoordinate2D]) -> CLLocationDistance {
        let n = polygon.count
        guard n >= 2 else { return .greatestFiniteMagnitude }

        let pointLocation = CLLocation(latitude: point.latitude, longitude: point.longitude)
        var minDistance: CLLocationDistance = .greatestFiniteMagnitude

        for i in 0..<n {
            let j = (i + 1) % n
            let closest = closestPointOnSegment(point: point, a: polygon[i], b: polygon[j])
            let dist = pointLocation.distance(from: CLLocation(latitude: closest.latitude, longitude: closest.longitude))
            if dist < minDistance {
                minDistance = dist
            }
        }

        return minDistance
    }

    /// Closest point on line segment AB to the given point, using cos(lat) longitude correction.
    private static func closestPointOnSegment(
        point: CLLocationCoordinate2D,
        a: CLLocationCoordinate2D,
        b: CLLocationCoordinate2D
    ) -> CLLocationCoordinate2D {
        let cosLat = cos(point.latitude * .pi / 180)
        let px = (point.longitude - a.longitude) * cosLat
        let py = point.latitude - a.latitude
        let dx = (b.longitude - a.longitude) * cosLat
        let dy = b.latitude - a.latitude

        let lenSq = dx * dx + dy * dy
        guard lenSq > 0 else { return a }

        let t = max(0, min(1, (px * dx + py * dy) / lenSq))
        return CLLocationCoordinate2D(
            latitude: a.latitude + t * (b.latitude - a.latitude),
            longitude: a.longitude + t * (b.longitude - a.longitude))
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
