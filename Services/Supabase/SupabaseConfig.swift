//
//  SupabaseConfig.swift
//  simpleApp
//
//  Supabase configuration and client initialization
//

import Foundation
import Supabase

@MainActor
class SupabaseConfig {
    static let shared = SupabaseConfig()

    // MARK: - Configuration
    // Supabase project credentials
    // Get these from: https://app.supabase.com/project/YOUR_PROJECT/settings/api

    private let supabaseURL = "https://tktculmbwyonhmgsctch.supabase.co"
    private let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRrdGN1bG1id3lvbmhtZ3NjdGNoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjMwMTUzNjEsImV4cCI6MjA3ODU5MTM2MX0.zT-aYyG0GMqRsEqNeopGGF-BNnvdNmi08BTARDb4geM"

    // Supabase client instance
    var client: SupabaseClient

    private init() {
        // Initialize Supabase client
        guard let url = URL(string: supabaseURL) else {
            fatalError("Invalid Supabase URL")
        }

        // Create custom URLSession configuration to disable HTTP/3 (fixes upload issues in simulator)
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = [
            "User-Agent": "simpleApp/1.0"
        ]
        // Attempt to force HTTP/2 or HTTP/1.1 (HTTP/3 causes issues in simulator)
        configuration.multipathServiceType = .none
        configuration.waitsForConnectivity = false
        configuration.timeoutIntervalForRequest = 60
        configuration.timeoutIntervalForResource = 300

        let session = URLSession(configuration: configuration)

        client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: supabaseAnonKey,
            options: SupabaseClientOptions(
                global: .init(
                    session: session
                )
            )
        )
        print("✅ SupabaseConfig: Client initialized successfully with custom URLSession")
    }

    // MARK: - Validation

    func isConfigured() -> Bool {
        return !supabaseURL.contains("YOUR_PROJECT_ID") &&
               !supabaseAnonKey.contains("YOUR_ANON_KEY")
    }

    func validateConfiguration() throws {
        guard isConfigured() else {
            throw SupabaseConfigError.notConfigured
        }

        guard let url = URL(string: supabaseURL), url.scheme == "https" else {
            throw SupabaseConfigError.invalidURL
        }
    }
}

// MARK: - Configuration Errors
enum SupabaseConfigError: LocalizedError {
    case notConfigured
    case invalidURL
    case initializationFailed

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Supabase credentials not configured. Update SupabaseConfig.swift with your project credentials."
        case .invalidURL:
            return "Invalid Supabase URL format"
        case .initializationFailed:
            return "Failed to initialize Supabase client"
        }
    }
}
