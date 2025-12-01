//
//  MediaItem.swift
//  simpleApp
//
//  Created by Sinchan Roychowdhury on 11/5/25.
//

import Foundation
import SwiftUI

struct MediaItem: Identifiable, Codable {
    var id: UUID = UUID()
    var type: MediaType
    var localURL: URL?
    var remoteURL: String?
    var thumbnailURL: String?
    var uploadProgress: Double = 0
    var uploadStatus: UploadStatus = .pending
    var fileSize: Int64? // in bytes

    enum CodingKeys: String, CodingKey {
        case id, type, remoteURL, thumbnailURL, uploadStatus, fileSize
    }

    var isUploaded: Bool {
        return uploadStatus == .completed && remoteURL != nil
    }

    var progressPercentage: Int {
        return Int(uploadProgress * 100)
    }
}

enum MediaType: String, Codable {
    case photo
    case audio

    var icon: String {
        switch self {
        case .photo:
            return "photo.fill"
        case .audio:
            return "waveform"
        }
    }

    var maxFileSize: Int64 {
        switch self {
        case .photo:
            return 10 * 1024 * 1024 // 10MB
        case .audio:
            return 25 * 1024 * 1024 // 25MB
        }
    }
}

enum UploadStatus: String, Codable {
    case pending
    case uploading
    case completed
    case failed

    var displayText: String {
        switch self {
        case .pending:
            return "Waiting to upload"
        case .uploading:
            return "Uploading..."
        case .completed:
            return "Uploaded"
        case .failed:
            return "Upload failed"
        }
    }
}
