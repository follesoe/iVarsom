import CoreLocation
import MapKit
import SwiftUI

struct AvalancheWatchMapView: View {
    let regions: [RegionSummary]
    var selectRegion: (RegionSummary) -> Void
    var locate: () async -> Location2D?
    @State private var geoData: RegionGeoData?
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 65, longitude: 14),
            span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10)
        )
    )
    @State private var showAnnotations = false
    @State private var zoomedIn = false
    private let annotationThreshold: Double = 8
    private let zoomedInThreshold: Double = 5

    var body: some View {
        MapReader { proxy in
            Map(position: $cameraPosition) {
                if let geoData = geoData {
                    ForEach(regions, id: \.Id) { region in
                        if let feature = geoData.features.first(where: { $0.id == region.Id }) {
                            let dangerLevel = todaysDangerLevel(for: region)
                            ForEach(Array(feature.polygons.enumerated()), id: \.offset) { _, polygon in
                                MapPolygon(coordinates: polygon)
                                    .foregroundStyle(dangerLevel.color.opacity(0.4))
                                    .stroke(dangerLevel.color, lineWidth: 1.5)
                            }
                            if showAnnotations {
                                Annotation("", coordinate: RegionGeoData.centroid(of: feature.polygons)) {
                                    VStack(spacing: 1) {
                                        DangerIcon(dangerLevel: dangerLevel)
                                            .frame(width: 24, height: 24)
                                        if zoomedIn {
                                            Text(region.Name)
                                                .font(.system(size: 8, weight: .semibold))
                                                .foregroundStyle(.primary)
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.5)
                                                .padding(.horizontal, 2)
                                                .padding(.vertical, 1)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 3)
                                                        .fill(.ultraThinMaterial)
                                                )
                                        }
                                    }
                                    .fixedSize()
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
            .mapStyle(
                .standard(
                    elevation: .flat,
                    emphasis: .muted,
                    pointsOfInterest: .excludingAll,
                    showsTraffic: false
                )
            )
            .mapControls {
                MapCompass()
            }
            .onTapGesture { screenPoint in
                guard let geoData = geoData,
                    let coordinate = proxy.convert(screenPoint, from: .local)
                else {
                    return
                }
                if let tappedRegion = findRegion(at: coordinate, in: geoData) {
                    selectRegion(tappedRegion)
                }
            }
        }
        .task {
            geoData = RegionGeoData.load()
            if let location = await locate() {
                withAnimation {
                    cameraPosition = .region(
                        MKCoordinateRegion(
                            center: location,
                            span: MKCoordinateSpan(latitudeDelta: 1.5, longitudeDelta: 1.5)
                        )
                    )
                }
            }
        }
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
