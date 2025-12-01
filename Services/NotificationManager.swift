//
//  NotificationManager.swift
//  simpleApp
//
//  Manages local notifications for goal reminders
//

import Foundation
import UserNotifications
import Combine

@MainActor
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private init() {
        print("🔔 NotificationManager: Initialized")
        Task {
            await checkAuthorizationStatus()
        }
    }

    // MARK: - Permission Management

    func requestAuthorization() async -> Bool {
        print("🔔 NotificationManager: Requesting notification authorization")

        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            print("🔔 NotificationManager: Authorization \(granted ? "granted" : "denied")")
            await checkAuthorizationStatus()
            return granted
        } catch {
            print("❌ NotificationManager: Authorization request failed - \(error.localizedDescription)")
            return false
        }
    }

    func checkAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authorizationStatus = settings.authorizationStatus
        print("🔔 NotificationManager: Current authorization status = \(settings.authorizationStatus.rawValue)")
    }

    // MARK: - Schedule Notifications

    func scheduleReminder(for entry: WeekEntry, at date: Date) async throws -> String {
        print("🔔 NotificationManager: Scheduling reminder for '\(entry.title)' at \(date)")

        // Check authorization
        await checkAuthorizationStatus()
        guard authorizationStatus == .authorized else {
            print("❌ NotificationManager: Not authorized to send notifications")
            throw NotificationError.notAuthorized
        }

        // Cancel existing notification if any
        if let existingId = entry.notificationId {
            cancelNotification(withId: existingId)
        }

        // Create unique notification ID
        let notificationId = "\(entry.id.uuidString)-reminder"

        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Goal Reminder"
        content.body = entry.title
        if let description = entry.description, !description.isEmpty {
            content.subtitle = description
        }
        content.sound = .default
        content.badge = 1
        content.userInfo = [
            "entryId": entry.id.uuidString,
            "entryType": entry.entryType.rawValue
        ]

        // Create trigger
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        // Create request
        let request = UNNotificationRequest(identifier: notificationId, content: content, trigger: trigger)

        // Schedule notification
        try await UNUserNotificationCenter.current().add(request)
        print("✅ NotificationManager: Reminder scheduled successfully with ID: \(notificationId)")

        return notificationId
    }

    // MARK: - Cancel Notifications

    func cancelNotification(withId id: String) {
        print("🔔 NotificationManager: Canceling notification with ID: \(id)")
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }

    func cancelAllNotifications() {
        print("🔔 NotificationManager: Canceling all pending notifications")
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    // MARK: - Query Notifications

    func getPendingNotifications() async -> [UNNotificationRequest] {
        return await UNUserNotificationCenter.current().pendingNotificationRequests()
    }
}

// MARK: - Errors

enum NotificationError: LocalizedError {
    case notAuthorized
    case schedulingFailed(String)

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Notification permissions not granted. Please enable notifications in Settings."
        case .schedulingFailed(let message):
            return "Failed to schedule reminder: \(message)"
        }
    }
}
