import Foundation
import Photos
import UIKit

// MARK: - Video Share Service
@MainActor
class VideoShareService: ObservableObject {
    static let shared = VideoShareService()

    @Published var isSaving = false
    @Published var saveError: Error?
    @Published var saveSuccess = false

    private init() {}

    // MARK: - Save to Photo Library

    func saveToPhotoLibrary(videoURL: URL) async -> Bool {
        isSaving = true
        saveError = nil
        saveSuccess = false

        // Check authorization
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)

        guard status == .authorized || status == .limited else {
            saveError = VideoShareError.photoLibraryAccessDenied
            isSaving = false
            return false
        }

        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL)
            }
            saveSuccess = true
            isSaving = false
            return true
        } catch {
            saveError = error
            isSaving = false
            return false
        }
    }

    // MARK: - Share to Instagram Stories

    func shareToInstagramStories(videoURL: URL) -> Bool {
        guard let instagramURL = URL(string: "instagram-stories://share") else {
            return false
        }

        // Check if Instagram is installed
        guard UIApplication.shared.canOpenURL(instagramURL) else {
            return false
        }

        // Read video data
        guard let videoData = try? Data(contentsOf: videoURL) else {
            return false
        }

        // Copy video to pasteboard for Instagram
        let pasteboardItems: [[String: Any]] = [
            ["com.instagram.sharedSticker.backgroundVideo": videoData]
        ]

        let pasteboardOptions: [UIPasteboard.OptionsKey: Any] = [
            .expirationDate: Date().addingTimeInterval(60 * 5) // 5 minutes
        ]

        UIPasteboard.general.setItems(pasteboardItems, options: pasteboardOptions)

        // Open Instagram Stories
        UIApplication.shared.open(instagramURL)
        return true
    }

    // MARK: - Share to Instagram Feed/Reels

    func shareToInstagram(videoURL: URL) -> Bool {
        // Instagram doesn't have direct API for feed posts
        // We'll use the document interaction controller approach
        guard let instagramURL = URL(string: "instagram://app") else {
            return false
        }

        guard UIApplication.shared.canOpenURL(instagramURL) else {
            return false
        }

        // For feed sharing, we need to save to photo library first
        // then user can share from Instagram
        return true
    }

    // MARK: - Check Instagram Availability

    var isInstagramInstalled: Bool {
        guard let instagramURL = URL(string: "instagram://app") else {
            return false
        }
        return UIApplication.shared.canOpenURL(instagramURL)
    }

    var isInstagramStoriesAvailable: Bool {
        guard let storiesURL = URL(string: "instagram-stories://share") else {
            return false
        }
        return UIApplication.shared.canOpenURL(storiesURL)
    }

    // MARK: - General Share Sheet

    func shareVideo(videoURL: URL, from viewController: UIViewController? = nil) {
        let activityViewController = UIActivityViewController(
            activityItems: [videoURL],
            applicationActivities: nil
        )

        // Exclude certain activity types if needed
        activityViewController.excludedActivityTypes = [
            .assignToContact,
            .addToReadingList
        ]

        // Get the top view controller
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            var topController = rootViewController
            while let presented = topController.presentedViewController {
                topController = presented
            }

            // For iPad, set popover presentation
            if let popover = activityViewController.popoverPresentationController {
                popover.sourceView = topController.view
                popover.sourceRect = CGRect(
                    x: topController.view.bounds.midX,
                    y: topController.view.bounds.midY,
                    width: 0,
                    height: 0
                )
                popover.permittedArrowDirections = []
            }

            topController.present(activityViewController, animated: true)
        }
    }
}

// MARK: - Video Share Error
enum VideoShareError: LocalizedError {
    case photoLibraryAccessDenied
    case instagramNotInstalled
    case videoNotFound
    case saveFailed

    var errorDescription: String? {
        switch self {
        case .photoLibraryAccessDenied:
            return "Photo library access was denied. Please enable it in Settings."
        case .instagramNotInstalled:
            return "Instagram is not installed on this device."
        case .videoNotFound:
            return "The video file could not be found."
        case .saveFailed:
            return "Failed to save the video. Please try again."
        }
    }
}

// MARK: - Share Result
enum ShareResult {
    case success
    case cancelled
    case failed(Error)
}
