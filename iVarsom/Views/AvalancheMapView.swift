import CoreLocation
import MapKit
import SwiftUI

struct AvalancheMapView: View {
    let regions: [RegionSummary]
    let searchTerm: String
    var locate: () async -> Location2D?
    var onRegionSelected: ((RegionSummary) -> Void)?
    @State private var geoData: RegionGeoData?
    @Binding var cameraPosition: MapCameraPosition
    @State private var showAnnotations = false
    @State private var zoomedIn = false
    private let annotationThreshold: Double = 16
    private let zoomedInThreshold: Double = 12

    static var overviewPosition: MapCameraPosition {
        .region(
            MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 65, longitude: 14),
                span: MKCoordinateSpan(latitudeDelta: 15, longitudeDelta: 15)
            ))
    }

    static func userPosition(_ location: Location2D) -> MapCameraPosition {
        .region(
            MKCoordinateRegion(
                center: location,
                span: MKCoordinateSpan(latitudeDelta: 4, longitudeDelta: 4)
            ))
    }

    var body: some View {
        MapReader { proxy in
            Map(position: $cameraPosition) {
                if let geoData = geoData {
                    ForEach(regions, id: \.Id) { region in
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
                                        regionId: region.Id,
                                        dangerLevel: dangerLevel,
                                        trend: region.dangerTrend,
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
                // A position set by panning doesn't record where the map is.
                // Store the camera so another map, such as the one shown after
                // iPhone Duo folds or unfolds, opens at the same place.
                if cameraPosition.positionedByUser {
                    cameraPosition = .camera(context.camera)
                }
            }
            .mapStyle(
                .standard(
                    elevation: .flat,
                    emphasis: .muted,
                    pointsOfInterest: .excludingAll,
                    showsTraffic: false
                )
            )
            .mapControls {
                MapScaleView()
                MapCompass()
                MapPitchToggle()
            }
            .onTapGesture { screenPoint in
                guard let geoData = geoData,
                    let coordinate = proxy.convert(screenPoint, from: .local)
                else {
                    return
                }
                if let tappedRegion = findRegion(at: coordinate, in: geoData) {
                    onRegionSelected?(tappedRegion)
                }
            }
        }
        .toolbar {
            if #available(iOS 27, *) {
                ToolbarItem(placement: .primaryAction) { locateButton }
                    .visibilityPriority(.high)
                ToolbarItem(placement: .primaryAction) { overviewButton }
                    .visibilityPriority(.low)
            } else {
                ToolbarItem(placement: .primaryAction) { locateButton }
                ToolbarItem(placement: .primaryAction) { overviewButton }
            }
        }
        .task {
            geoData = RegionGeoData.load()
        }
    }

    // Titles matter for iPhone Duo's overflow menu; vertical bars use the icons.
    private var locateButton: some View {
        Button {
            Task {
                if let location = await locate() {
                    withAnimation { cameraPosition = Self.userPosition(location) }
                }
            }
        } label: {
            Label("Show My Location", systemImage: "location")
        }
    }

    private var overviewButton: some View {
        Button {
            withAnimation {
                cameraPosition = Self.overviewPosition
            }
        } label: {
            Label("Show All Regions", systemImage: "globe.europe.africa")
        }
    }

    func zoomToRegion(_ region: RegionSummary) {
        if let geoData = geoData,
            let feature = geoData.features.first(where: { $0.id == region.Id })
        {
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

    private func matchesSearch(_ region: RegionSummary) -> Bool {
        searchTerm.isEmpty || region.Name.localizedCaseInsensitiveContains(searchTerm)
    }

    private func todaysDangerLevel(for region: RegionSummary) -> DangerLevel {
        ForecastSelection.warning(in: region.AvalancheWarningList, day: .today, at: .current)?.DangerLevel ?? .unknown
    }

    private func findRegion(at coordinate: CLLocationCoordinate2D, in geoData: RegionGeoData) -> RegionSummary? {
        for feature in geoData.features {
            for polygon in feature.polygons {
                if RegionGeoData.pointInPolygon(point: coordinate, polygon: polygon) {
                    return regions.first { $0.Id == feature.id }
                }
            }
        }
        return nil
    }
}

private struct RegionAnnotationLabel: View {
    let name: String
    let regionId: Int
    let dangerLevel: DangerLevel
    var trend: DangerTrend? = nil
    var compact: Bool = false

    private var iconSize: CGFloat { compact ? 16 : 30 }
    private var font: Font { compact ? .system(size: 8, weight: .semibold) : .caption.weight(.semibold) }
    private var trendFont: Font { compact ? .system(size: 8, weight: .heavy) : .system(size: 12, weight: .heavy) }

    var body: some View {
        VStack(spacing: compact ? 1 : 2) {
            DangerIcon(dangerLevel: dangerLevel)
                .frame(width: iconSize, height: iconSize)
            HStack(spacing: 2) {
                Text(name)
                    .font(font)
                    .speechLocale(for: regionId)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                if let trend = trend {
                    Image(systemName: trend.symbolName)
                        .font(trendFont)
                        .foregroundStyle(trend.color)
                }
            }
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
