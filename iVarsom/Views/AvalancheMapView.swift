import SwiftUI
import MapKit
import CoreLocation

struct AvalancheMapView<ViewModelType: RegionListViewModelProtocol>: View {
    @Bindable var vm: ViewModelType
    var onRegionSelected: ((RegionSummary) -> Void)?
    @State private var geoData: RegionGeoData?
    @Binding var cameraPosition: MapCameraPosition
    @State private var showAnnotations = false
    @State private var zoomedIn = false
    private let annotationThreshold: Double = 16
    private let zoomedInThreshold: Double = 12

    static var overviewPosition: MapCameraPosition {
        .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 65, longitude: 14),
            span: MKCoordinateSpan(latitudeDelta: 15, longitudeDelta: 15)
        ))
    }

    static func userPosition(_ location: Location2D) -> MapCameraPosition {
        .region(MKCoordinateRegion(
            center: location,
            span: MKCoordinateSpan(latitudeDelta: 4, longitudeDelta: 4)
        ))
    }

    var body: some View {
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
                            if matches && showAnnotations {
                                Annotation("", coordinate: RegionGeoData.centroid(of: feature.polygons)) {
                                    RegionAnnotationLabel(
                                        name: region.Name,
                                        dangerLevel: dangerLevel,
                                        compact: !zoomedIn
                                    )
                                }
                            }
                        }
                    }
                }
                UserAnnotation()
            }
            .onMapCameraChange { context in
                let delta = context.region.span.latitudeDelta
                withAnimation(.easeInOut(duration: 0.25)) {
                    showAnnotations = delta < annotationThreshold
                    zoomedIn = delta < zoomedInThreshold
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
                    onRegionSelected?(tappedRegion)
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task {
                        await vm.requestLocationForMap()
                        if let location = vm.userLocation {
                            withAnimation {
                                cameraPosition = Self.userPosition(location)
                            }
                        }
                    }
                } label: {
                    Image(systemName: "location")
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    withAnimation {
                        cameraPosition = Self.overviewPosition
                    }
                } label: {
                    Image(systemName: "globe.europe.africa")
                }
            }
        }
        .task {
            geoData = RegionGeoData.load()
        }
    }

    func zoomToRegion(_ region: RegionSummary) {
        if let geoData = geoData,
           let feature = geoData.features.first(where: { $0.id == region.Id }) {
            let centroid = RegionGeoData.centroid(of: feature.polygons)
            withAnimation {
                cameraPosition = .region(
                    MKCoordinateRegion(
                        center: centroid,
                        span: MKCoordinateSpan(latitudeDelta: 3, longitudeDelta: 3)
                    )
                )
            }
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

    private func findRegion(at coordinate: CLLocationCoordinate2D, in geoData: RegionGeoData) -> RegionSummary? {
        for feature in geoData.features {
            for polygon in feature.polygons {
                if RegionGeoData.pointInPolygon(point: coordinate, polygon: polygon) {
                    return allRegions.first { $0.Id == feature.id }
                }
            }
        }
        return nil
    }
}

private struct RegionAnnotationLabel: View {
    let name: String
    let dangerLevel: DangerLevel
    var compact: Bool = false

    private var iconSize: CGFloat { compact ? 16 : 30 }
    private var font: Font { compact ? .system(size: 8, weight: .semibold) : .caption.weight(.semibold) }

    var body: some View {
        VStack(spacing: compact ? 1 : 2) {
            DangerIcon(dangerLevel: dangerLevel)
                .frame(width: iconSize, height: iconSize)
            Text(name)
                .font(font)
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .padding(.horizontal, compact ? 2 : 4)
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
