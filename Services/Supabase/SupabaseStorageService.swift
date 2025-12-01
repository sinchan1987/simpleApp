//
//  SupabaseStorageService.swift
//  simpleApp
//
//  Supabase implementation of StorageServiceProtocol
//

import Foundation
import UIKit
import Supabase
import Storage

@MainActor
class SupabaseStorageService: StorageServiceProtocol {
    static let shared = SupabaseStorageService()

    private let client: SupabaseClient
    private let photosBucket = "photos"
    private let audioBucket = "audio"
    private let supabaseKey: String
    private let supabaseURL = "https://tktculmbwyonhmgsctch.supabase.co"

    private init() {
        print("🔵 SupabaseStorageService: Initialized")
        self.client = SupabaseConfig.shared.client
        self.supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRrdGN1bG1id3lvbmhtZ3NjdGNoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjMwMTUzNjEsImV4cCI6MjA3ODU5MTM2MX0.zT-aYyG0GMqRsEqNeopGGF-BNnvdNmi08BTARDb4geM"
    }

    // MARK: - Photo Upload

    func uploadPhoto(_ image: UIImage, userId: String, progressHandler: ((Double) -> Void)? = nil) async throws -> String {
        print("🔵 SupabaseStorageService.uploadPhoto: Starting upload")
        print("  userId: \(userId)")

        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            print("❌ SupabaseStorageService.uploadPhoto: Failed to convert image to JPEG")
            throw StorageError.invalidImage
        }

        print("  Image data size: \(imageData.count) bytes")

        do {
            let filename = "\(UUID().uuidString).jpg"
            let path = "\(userId)/\(filename)"

            print("  Upload path: \(path)")

            // NOTE: HTTP/3 upload issues in iOS Simulator - works fine on real devices
            // Upload using Supabase SDK with Data
            _ = try await client.storage
                .from(photosBucket)
                .upload(
                    path: path,
                    file: imageData,
                    options: FileOptions(
                        cacheControl: "3600",
                        contentType: "image/jpeg",
                        upsert: false
                    )
                )

            print("✅ SupabaseStorageService.uploadPhoto: Upload successful")

            // Get public URL
            let publicURL = try client.storage
                .from(photosBucket)
                .getPublicURL(path: path)

            print("✅ SupabaseStorageService.uploadPhoto: Public URL: \(publicURL)")
            return publicURL.absoluteString

        } catch {
            print("❌ SupabaseStorageService.uploadPhoto: Upload failed - \(error.localizedDescription)")
            print("❌ Full error: \(error)")
            throw StorageError.uploadFailed
        }

    }

    // MARK: - Audio Upload

    func uploadAudio(_ audioURL: URL, userId: String, progressHandler: ((Double) -> Void)? = nil) async throws -> String {
        print("🔵 SupabaseStorageService.uploadAudio: Starting upload")
        print("  userId: \(userId)")

        do {
            let audioData = try Data(contentsOf: audioURL)
            let filename = "\(UUID().uuidString).m4a"
            let path = "\(userId)/\(filename)"

            print("  Upload path: \(path)")
            print("  Audio data size: \(audioData.count) bytes")

            // Upload using Supabase SDK with Data
            _ = try await client.storage
                .from(audioBucket)
                .upload(
                    path: path,
                    file: audioData,
                    options: FileOptions(
                        cacheControl: "3600",
                        contentType: "audio/x-m4a",
                        upsert: false
                    )
                )

            print("✅ SupabaseStorageService.uploadAudio: Upload successful")

            // Get public URL
            let publicURL = try client.storage
                .from(audioBucket)
                .getPublicURL(path: path)

            print("✅ SupabaseStorageService.uploadAudio: Public URL: \(publicURL)")
            return publicURL.absoluteString

        } catch {
            print("❌ SupabaseStorageService.uploadAudio: Upload failed - \(error.localizedDescription)")
            print("❌ Full error: \(error)")
            throw StorageError.uploadFailed
        }

    }

    // MARK: - Download

    func downloadImage(from urlString: String) async throws -> UIImage {
        print("🔵 SupabaseStorageService.downloadImage: Downloading from: \(urlString)")

        guard let url = URL(string: urlString) else {
            print("❌ SupabaseStorageService.downloadImage: Invalid URL")
            throw StorageError.invalidURL
        }

        do {
            // Use URLSession for downloading public URLs
            let (data, _) = try await URLSession.shared.data(from: url)

            guard let image = UIImage(data: data) else {
                print("❌ SupabaseStorageService.downloadImage: Failed to create image")
                throw StorageError.invalidImage
            }

            print("✅ SupabaseStorageService.downloadImage: Image downloaded successfully")
            return image
        } catch {
            print("❌ SupabaseStorageService.downloadImage: Download failed - \(error.localizedDescription)")
            throw StorageError.downloadFailed
        }
    }

    // MARK: - Delete

    func deleteFile(at urlString: String) async throws {
        print("🔵 SupabaseStorageService.deleteFile: Deleting file at: \(urlString)")

        // Extract bucket and path from URL
        guard let url = URL(string: urlString) else {
            print("❌ SupabaseStorageService.deleteFile: Invalid URL")
            throw StorageError.invalidURL
        }

        do {
            // Parse URL to extract bucket and path
            // Supabase storage URLs are in format: https://project.supabase.co/storage/v1/object/public/bucket/path
            let pathComponents = url.pathComponents
            guard pathComponents.count >= 6,
                  let bucketIndex = pathComponents.firstIndex(where: { $0 == "public" }),
                  bucketIndex + 2 < pathComponents.count else {
                print("❌ SupabaseStorageService.deleteFile: Could not parse URL")
                throw StorageError.invalidURL
            }

            let bucket = pathComponents[bucketIndex + 1]
            let filePath = pathComponents[(bucketIndex + 2)...].joined(separator: "/")

            print("  Bucket: \(bucket), Path: \(filePath)")

            try await client.storage
                .from(bucket)
                .remove(paths: [filePath])

            print("✅ SupabaseStorageService.deleteFile: File deleted successfully")
        } catch {
            print("❌ SupabaseStorageService.deleteFile: Delete failed - \(error.localizedDescription)")
            throw StorageError.uploadFailed
        }

    }

    // MARK: - Compression Helpers

    func compressImage(_ image: UIImage, maxSizeKB: Int = 500) -> UIImage? {
        print("🔵 SupabaseStorageService.compressImage: Compressing image (max: \(maxSizeKB)KB)")

        var compression: CGFloat = 1.0
        var imageData = image.jpegData(compressionQuality: compression)

        while let data = imageData, data.count > maxSizeKB * 1024 && compression > 0.1 {
            compression -= 0.1
            imageData = image.jpegData(compressionQuality: compression)
        }

        guard let finalData = imageData else {
            print("❌ SupabaseStorageService.compressImage: Failed to compress image")
            return nil
        }

        let compressedImage = UIImage(data: finalData)
        print("✅ SupabaseStorageService.compressImage: Image compressed to \(finalData.count) bytes")
        return compressedImage
    }
}
