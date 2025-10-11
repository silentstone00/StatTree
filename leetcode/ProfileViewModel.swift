// ProfileViewModel.swift
import Foundation
import SwiftUI

class ProfileViewModel: ObservableObject {
    @Published var profile: UserProfile?
    @Published var isLoading = false
    @Published var error: Error?
    
    @AppStorage("leetcodeUsername") var username: String = ""
    
    func fetchProfile() {
        guard !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            DispatchQueue.main.async {
                self.error = NSError(domain: "InvalidUsername", code: 400, userInfo: [NSLocalizedDescriptionKey: "Username not set"]) 
            }
            return
        }
        isLoading = true
        LeetCodeAPI.shared.fetchUserProfile(username: username) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let prof):
                    self.profile = prof
                case .failure(let err):
                    self.error = err
                    if (err as NSError).domain == "UserNotFound" {
                        self.username = ""
                    }
                }
            }
        }
    }
    
    @MainActor
    func fetchProfileAsync() async {
        guard !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            self.error = NSError(domain: "InvalidUsername", code: 400, userInfo: [NSLocalizedDescriptionKey: "Username not set"])
            return
        }
        
        isLoading = true
        
        do {
            let prof = try await withCheckedThrowingContinuation { continuation in
                LeetCodeAPI.shared.fetchUserProfile(username: username) { result in
                    continuation.resume(with: result)
                }
            }
            self.profile = prof
            self.error = nil
        } catch {
            self.error = error
            if (error as NSError).domain == "UserNotFound" {
                self.username = ""
            }
        }
        
        self.isLoading = false
    }
}
