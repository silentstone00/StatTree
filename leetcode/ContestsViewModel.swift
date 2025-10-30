// ContestsViewModel.swift
import Foundation
import UserNotifications
import SwiftUI

class ContestsViewModel: ObservableObject {
    @Published var upcomingContests: [Contest] = []
    @Published var contestHistory: ContestHistory?
    @Published var isLoading = false
    @Published var error: Error?
    
    @AppStorage("Username") var username: String = ""
    
    func fetchContests() {
        isLoading = true
        CodeAPI.shared.fetchContests { result in
            DispatchQueue.main.async {
                if case .success(let contests) = result {
                    self.upcomingContests = contests.filter { Date(timeIntervalSince1970: Double($0.startTime)) > Date() }
                    // Schedule notifications for upcoming
                    for contest in self.upcomingContests {
                        self.scheduleContestNotification(contest: contest)
                    }
                }
            }
        }
        CodeAPI.shared.fetchContestHistory(username: username) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                if case .success(let history) = result {
                    self.contestHistory = history
                } else if case .failure(let err) = result {
                    self.error = err
                }
            }
        }
    }
    
    @MainActor
    func fetchContestsAsync() async {
        isLoading = true
        
        do {
            let contests = try await withCheckedThrowingContinuation { continuation in
                CodeAPI.shared.fetchContests { result in
                    continuation.resume(with: result)
                }
            }
            
            self.upcomingContests = contests.filter { Date(timeIntervalSince1970: Double($0.startTime)) > Date() }
            
            // Schedule notifications for upcoming contests
            for contest in self.upcomingContests {
                self.scheduleContestNotification(contest: contest)
            }
            
            let history = try await withCheckedThrowingContinuation { continuation in
                CodeAPI.shared.fetchContestHistory(username: username) { result in
                    continuation.resume(with: result)
                }
            }
            
            self.contestHistory = history
            self.error = nil
            
        } catch {
            self.error = error
        }
        
        self.isLoading = false
    }
    
    private func scheduleContestNotification(contest: Contest) {
        let content = UNMutableNotificationContent()
        content.title = "Contest"
        content.body = "\(contest.title) starts soon!"
        content.sound = UNNotificationSound.default
        
        let startDate = Date(timeIntervalSince1970: Double(contest.startTime)) - 1800 // 30 min before
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: startDate.timeIntervalSinceNow, repeats: false)
        let request = UNNotificationRequest(identifier: contest.titleSlug, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
}
