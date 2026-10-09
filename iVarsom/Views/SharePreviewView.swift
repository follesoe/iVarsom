#if os(iOS)
    import SwiftUI
    import UIKit

    /// Owns the temporary export for as long as its preview is presented.
    @MainActor
    final class ShareImage: Identifiable {
        let id = UUID()
        let image: UIImage
        let url: URL
        private let directory: URL

        init?(image: UIImage, filename: String) {
            guard let data = image.pngData() else { return nil }
            self.image = image
            directory = URL.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
            // Region names may contain slashes (for example Abisko/Riksgränsfjällen).
            let safeFilename = filename.replacingOccurrences(of: "/", with: "-")
                .replacingOccurrences(of: "\\", with: "-")
            url = directory.appendingPathComponent(safeFilename)
            do {
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                try data.write(to: url, options: .atomic)
            } catch {
                try? FileManager.default.removeItem(at: directory)
                return nil
            }
        }

        isolated deinit { try? FileManager.default.removeItem(at: directory) }
    }

    struct SharePreviewView: View {
        let item: ShareImage
        @Environment(\.dismiss) private var dismiss

        var body: some View {
            NavigationStack {
                ScrollView {
                    Image(uiImage: item.image)
                        .resizable()
                        .scaledToFit()
                        .padding()
                        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
                }
                .background(Color(.systemGroupedBackground))
                .navigationTitle("Share preview")
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
                        ShareLink(
                            item: item.url,
                            preview: SharePreview(item.url.lastPathComponent, image: Image(uiImage: item.image))
                        ) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
    }
#endif
