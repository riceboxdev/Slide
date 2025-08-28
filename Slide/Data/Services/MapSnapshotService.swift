//
//  MapSnapshotService.swift
//  Slide
//
//  Created by Nick Rogers on 7/29/25.
//


import MapKit
import SwiftUI

// MARK: - Services
class MapSnapshotService {
    enum ColorScheme {
        case automatic
        case light
        case dark
    }

    func generateSnapshot(
        coordinate: CLLocationCoordinate2D,
        width: CGFloat,
        height: CGFloat,
        colorScheme: ColorScheme = .automatic
    ) async -> UIImage? {
        return await withCheckedContinuation { continuation in
            let region = MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(
                    latitudeDelta: 0.003,
                    longitudeDelta: 0.003
                )
            )

            let mapOptions = MKMapSnapshotter.Options()
            mapOptions.region = region
            mapOptions.size = CGSize(width: width, height: height)
            mapOptions.showsBuildings = true

            // Set the color scheme
            switch colorScheme {
            case .automatic:

                mapOptions.traitCollection = UITraitCollection.current

            case .light:

                mapOptions.traitCollection = UITraitCollection(
                    userInterfaceStyle: .light
                )

            case .dark:

                mapOptions.traitCollection = UITraitCollection(
                    userInterfaceStyle: .dark
                )

            }

            let snapshotter = MKMapSnapshotter(options: mapOptions)
            snapshotter.start { (snapshotOrNil, errorOrNil) in
                if let error = errorOrNil {
                    print("Map snapshot error: \(error)")
                    continuation.resume(returning: nil)
                    return
                }

                if let snapshot = snapshotOrNil {
                    let imageWithMarker = self.addMarkerToSnapshot(
                        snapshot: snapshot,
                        coordinate: coordinate
                    )
                    continuation.resume(returning: imageWithMarker)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    private func addMarkerToSnapshot(
        snapshot: MKMapSnapshotter.Snapshot,
        coordinate: CLLocationCoordinate2D
    ) -> UIImage {
        let image = snapshot.image
        let markerPoint = snapshot.point(for: coordinate)

        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        image.draw(at: CGPoint.zero)
        drawSystemMarker(at: markerPoint)

        let finalImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return finalImage ?? image
    }

    private func drawSystemMarker(at point: CGPoint) {
        let markerImage = UIImage(systemName: "mappin.circle.fill")?
            .withConfiguration(
                UIImage.SymbolConfiguration(pointSize: 24, weight: .regular)
            )
            .withTintColor(.red, renderingMode: .alwaysOriginal)

        if let marker = markerImage {
            let markerRect = CGRect(
                x: point.x - marker.size.width / 2,
                y: point.y - marker.size.height,
                width: marker.size.width,
                height: marker.size.height
            )
            marker.draw(in: markerRect)
        }
    }
}
