//
//  FirebaseStorageService.swift
//  simpleApp
//
//  Firebase implementation of StorageServiceProtocol
//

import Foundation
import UIKit
import FirebaseStorage

@MainActor
class FirebaseStorageService: StorageServiceProtocol {
    static let shared = FirebaseStorageService()
    private let storage = Storage.storage()

    private init() {
        print("📸 FirebaseStorageService: Initialized")
    }

    // MARK: - Photo Upload
    func uploadPhoto(_ image: UIImage, userId: String, progressHandler: ((Double) -> Void)? = nil) async throws -> String {
        print("📸 FirebaseStorageService.uploadPhoto: Starting upload")
        print("  userId: \(userId)")

        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            print("❌ FirebaseStorageService.uploadPhoto: Failed to convert image to JPEG data")
            throw StorageError.invalidImage
        }

        print("  Image data size: \(imageData.count) bytes")

        let filename = "\(UUID().uuidString).jpg"
        let path = "photos/\(userId)/\(filename)"
        let ref = storage.reference().child(path)

        print("  Upload path: \(path)")
        print("  Storage reference: \(ref.fullPath)")

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        // Upload with progress tracking
        return try await withCheckedThrowingContinuation { continuation in
            print("  Starting Firebase Storage upload task...")
            let uploadTask = ref.putData(imageData, metadata: metadata)

            uploadTask.observe(.progress) { snapshot in
                if let progress = snapshot.progress {
                    let percentComplete = Double(progress.completedUnitCount) / Double(progress.totalUnitCount)
                    print("  Upload progress: \(Int(percentComplete * 100))%")
                    progressHandler?(percentComplete)
                }
            }

            uploadTask.observe(.success) { snapshot in
                print("✅ FirebaseStorageService.uploadPhoto: Upload successful, fetching download URL...")
                ref.downloadURL { url, error in
                    if let error = error {
                        print("❌ FirebaseStorageService.uploadPhoto: Failed to get download URL")
                        print("  Error: \(error.localizedDescription)")
                        print("  Error details: \(error)")
                        continuation.resume(throwing: error)
                    } else if let url = url {
                        print("✅ FirebaseStorageService.uploadPhoto: Got download URL: \(url.absoluteString)")
                        continuation.resume(returning: url.absoluteString)
                    } else {
                        print("❌ FirebaseStorageService.uploadPhoto: No error but also no URL")
                        continuation.resume(throwing: StorageError.uploadFailed)
                    }
                }
            }

            uploadTask.observe(.failure) { snapshot in
                print("❌ FirebaseStorageService.uploadPhoto: Upload failed")
                if let error = snapshot.error {
                    print("  Error: \(error.localizedDescription)")
                    print("  Error details: \(error)")
                    continuation.resume(throwing: error)
                } else {
                    print("  Unknown error")
                    continuation.resume(throwing: StorageError.uploadFailed)
                }
            }
        }
    }

    // MARK: - Audio Upload
    func uploadAudio(_ audioURL: URL, userId: String, progressHandler: ((Double) -> Void)? = nil) async throws -> String {
        print("🎤 FirebaseStorageService.uploadAudio: Starting upload")
        print("  userId: \(userId)")

        let filename = "\(UUID().uuidString).m4a"
        let path = "audio/\(userId)/\(filename)"
        let ref = storage.reference().child(path)

        print("  Upload path: \(path)")

        let metadata = StorageMetadata()
        metadata.contentType = "audio/m4a"

        return try await withCheckedThrowingContinuation { continuation in
            let uploadTask = ref.putFile(from: audioURL, metadata: metadata)

            uploadTask.observe(.progress) { snapshot in
                if let progress = snapshot.progress {
                    let percentComplete = Double(progress.completedUnitCount) / Double(progress.totalUnitCount)
                    print("  Audio upload progress: \(Int(percentComplete * 100))%")
                    progressHandler?(percentComplete)
                }
            }

            uploadTask.observe(.success) { snapshot in
                print("✅ FirebaseStorageService.uploadAudio: Upload successful, fetching download URL...")
                ref.downloadURL { url, error in
                    if let error = error {
                        print("❌ FirebaseStorageService.uploadAudio: Failed to get download URL")
                        continuation.resume(throwing: error)
                    } else if let url = url {
                        print("✅ FirebaseStorageService.uploadAudio: Got download URL: \(url.absoluteString)")
                        continuation.resume(returning: url.absoluteString)
                    } else {
                        continuation.resume(throwing: StorageError.uploadFailed)
                    }
                }
            }

            uploadTask.observe(.failure) { snapshot in
                print("❌ FirebaseStorageService.uploadAudio: Upload failed")
                if let error = snapshot.error {
                    print("  Error: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(throwing: StorageError.uploadFailed)
                }
            }
        }
    }

    // MARK: - Download
    func downloadImage(from urlString: String) async throws -> UIImage {
        print("📥 FirebaseStorageService.downloadImage: Downloading from: \(urlString)")

        guard let url = URL(string: urlString) else {
            print("❌ FirebaseStorageService.downloadImage: Invalid URL")
            throw StorageError.invalidURL
        }

        do {
            // Use URLSession for downloading
            let (data, _) = try await URLSession.shared.data(from: url)

            guard let image = UIImage(data: data) else {
                print("❌ FirebaseStorageService.downloadImage: Failed to create image from data")
                throw StorageError.invalidImage
            }

            print("✅ FirebaseStorageService.downloadImage: Image downloaded successfully")
            return image
        } catch {
            print("❌ FirebaseStorageService.downloadImage: Download failed: \(error.localizedDescription)")
            throw StorageError.downloadFailed
        }
    }

    // MARK: - Delete
    func deleteFile(at urlString: String) async throws {
        print("🗑️ FirebaseStorageService.deleteFile: Deleting file at: \(urlString)")

        do {
            let ref = storage.reference(forURL: urlString)
            try await ref.delete()
            print("✅ FirebaseStorageService.deleteFile: File deleted successfully")
        } catch {
            print("❌ FirebaseStorageService.deleteFile: Failed to delete file: \(error.localizedDescription)")
            throw error
        }
    }

    // MARK: - Compression Helpers
    func compressImage(_ image: UIImage, maxSizeKB: Int = 500) -> UIImage? {
        print("🗜️ FirebaseStorageService.compressImage: Compressing image (max: \(maxSizeKB)KB)")

        var compression: CGFloat = 1.0
        var imageData = image.jpegData(compressionQuality: compression)

        while let data = imageData, data.count > maxSizeKB * 1024 && compression > 0.1 {
            compression -= 0.1
            imageData = image.jpegData(compressionQuality: compression)
        }

        guard let finalData = imageData else {
            print("❌ FirebaseStorageService.compressImage: Failed to compress image")
            return nil
        }

        let compressedImage = UIImage(data: finalData)
        print("✅ FirebaseStorageService.compressImage: Image compressed to \(finalData.count) bytes")
        return compressedImage
    }
}

// MARK: - Storage Errors
enum StorageError: LocalizedError {
    case invalidImage
    case invalidURL
    case uploadFailed
    case downloadFailed

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid image data"
        case .invalidURL:
            return "Invalid URL"
        case .uploadFailed:
            return "Failed to upload file"
        case .downloadFailed:
            return "Failed to download file"
        }
    }
}
