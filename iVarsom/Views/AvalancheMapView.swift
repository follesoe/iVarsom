import SwiftUI
import MapKit
import CoreLocation

struct AvalancheMapView<ViewModelType: RegionListViewModelProtocol>: View {
    @Bindable var vm: ViewModelType
    @State private var geoData: RegionGeoData?
    @State private var selectedRegion: RegionSummary?
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 65, longitude: 14),
            span: MKCoordinateSpan(latitudeDelta: 15, longitudeDelta: 15)
        )
    )

    var body: some View {
        NavigationStack {
            MapReader { proxy in
                Map(position: $cameraPosition) {
                    if let geoData = geoData {
                        ForEach(allRegions, id: \.Id) { region in
                            if let feature = geoData.features.first(where: { $0.id == region.Id }) {
                                let dangerLevel = todaysDangerLevel(for: region)
                                let matches = matchesSearch(region)
                                let fillOpacity = matches ? 0.4 : 0.1
                                let strokeOpacity = matches ? 1.0 : 0.2
                                ForEach(Array(feature.polygons.enumerated()), id: \.offset) { _, polygon in
                                    MapPolygon(coordinates: polygon)
                                        .foregroundStyle(dangerLevel.color.opacity(fillOpacity))
                                        .stroke(dangerLevel.color.opacity(strokeOpacity), lineWidth: 1.5)
                                }
                                if matches {
                                    Annotation("", coordinate: centroid(of: feature.polygons)) {
                                        RegionAnnotationLabel(
                                            name: region.Name,
                                            dangerLevel: dangerLevel
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
                .mapStyle(.standard(
                    elevation: .flat,
                    emphasis: .muted,
                    pointsOfInterest: .excludingAll,
                    showsTraffic: false
                ))
                .mapControls {
                    MapScaleView()
                    MapCompass()
                    MapPitchToggle()
                }
                .onTapGesture { screenPoint in
                    guard let geoData = geoData,
                          let coordinate = proxy.convert(screenPoint, from: .local) else {
                        return
                    }
                    if let tappedRegion = findRegion(at: coordinate, in: geoData) {
                        selectedRegion = tappedRegion
                        vm.selectedRegion = tappedRegion
                        Task {
                            await vm.loadWarnings(from: WarningDateRange.defaultDaysBefore, to: WarningDateRange.defaultDaysAfter)
                        }
                    }
                }
            }
            .navigationTitle("Map")
            .navigationDestination(item: $selectedRegion) { _ in
                RegionDetailContainer<ViewModelType>(vm: vm)
            }
        }
        .task {
            geoData = RegionGeoData.load()
        }
    }

    private var allRegions: [RegionSummary] {
        vm.regions + vm.swedenRegions
    }

    private func matchesSearch(_ region: RegionSummary) -> Bool {
        vm.searchTerm.isEmpty || region.Name.localizedCaseInsensitiveContains(vm.searchTerm)
    }

    private func todaysDangerLevel(for region: RegionSummary) -> DangerLevel {
        let today = Date.current
        if let warning = region.AvalancheWarningList.first(where: {
            Calendar.current.isDate($0.ValidFrom, equalTo: today, toGranularity: .day)
        }) {
            return warning.DangerLevel
        }
        return .unknown
    }

    private func centroid(of polygons: [[CLLocationCoordinate2D]]) -> CLLocationCoordinate2D {
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

    private func findRegion(at coordinate: CLLocationCoordinate2D, in geoData: RegionGeoData) -> RegionSummary? {
        for feature in geoData.features {
            for polygon in feature.polygons {
                if pointInPolygon(point: coordinate, polygon: polygon) {
                    return allRegions.first { $0.Id == feature.id }
                }
            }
        }
        return nil
    }

    private func pointInPolygon(point: CLLocationCoordinate2D, polygon: [CLLocationCoordinate2D]) -> Bool {
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
}

private struct RegionAnnotationLabel: View {
    let name: String
    let dangerLevel: DangerLevel

    var body: some View {
        VStack(spacing: 2) {
            DangerIcon(dangerLevel: dangerLevel)
                .frame(width: 24, height: 24)
            Text(name)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
                .background(
                    RoundedRectangle(cornerRadius: 3)
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(.white.opacity(0.7), lineWidth: 0.5)
                )
        }
        .fixedSize()
    }
}
