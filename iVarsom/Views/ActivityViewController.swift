#if os(iOS)
import UIKit

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

        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = scene.keyWindow?.rootViewController else { return }
        var presenter = rootVC
        while let presented = presenter.presentedViewController {
            presenter = presented
        }
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = presenter.view
            popover.sourceRect = CGRect(x: presenter.view.bounds.midX, y: 0, width: 0, height: 0)
            popover.permittedArrowDirections = .up
        }
        presenter.present(activityVC, animated: true)
    }
}
#endif
