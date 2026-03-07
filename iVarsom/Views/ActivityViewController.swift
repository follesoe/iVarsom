#if os(iOS)
import UIKit
import SwiftUI

@MainActor
enum ActivityViewPresenter {
    static func present(image: UIImage, filename: String) {
        guard let pngData = image.pngData() else { return }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try? pngData.write(to: url)

        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        activityVC.completionWithItemsHandler = { _, _, _, _ in
            try? FileManager.default.removeItem(at: url)
        }

        guard let presenter = Self.topViewController() else { return }
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = presenter.view
            popover.sourceRect = CGRect(x: presenter.view.bounds.midX, y: 0, width: 0, height: 0)
            popover.permittedArrowDirections = .up
        }
        presenter.present(activityVC, animated: true)
    }

    static func topViewController() -> UIViewController? {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = scene.keyWindow?.rootViewController else { return nil }
        var presenter = rootVC
        while let presented = presenter.presentedViewController {
            presenter = presented
        }
        return presenter
    }
}

@MainActor
enum SharePreviewPresenter {
    static func present(image: UIImage, filename: String) {
        let previewView = SharePreviewView(image: image, filename: filename)
        let hostingController = UIHostingController(rootView: previewView)
        hostingController.modalPresentationStyle = .pageSheet

        if let sheet = hostingController.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
        }

        guard let presenter = ActivityViewPresenter.topViewController() else { return }
        presenter.present(hostingController, animated: true)
    }
}

private struct SharePreviewView: View {
    let image: UIImage
    let filename: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding()
                    .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(NSLocalizedString("Share preview", comment: "Title for share preview sheet"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        ActivityViewPresenter.present(image: image, filename: filename)
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
    }
}
#endif
