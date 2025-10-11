// ContentView.swift
import SwiftUI

struct ContentView: View {
    @AppStorage("leetcodeUsername") var username: String = ""
    @State private var isUsernameSet: Bool = false

    var body: some View {
        if !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            TabView {
                ProfileView()
                    .tabItem {
                        Label("Profile", systemImage: "person.circle.fill")
                    }
                DailyChallengeView()
                    .tabItem {
                        Label("Daily", systemImage: "calendar.badge.clock")
                    }
                ProblemsView()
                    .tabItem {
                        Label("Problems", systemImage: "list.bullet")
                    }
                UserProgressView()
                    .tabItem {
                        Label("Progress", systemImage: "chart.bar.fill")
                    }
                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
            }
            .onAppear {
                setupNotifications()
            }
        } else {
            UsernameInputView(username: $username)
        }
    }

    private func setupNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                scheduleDailyReminder()
            }
        }
    }

    private func scheduleDailyReminder() {
        let content = UNMutableNotificationContent()
        content.title = "LeetCode Daily Challenge"
        content.body = "Don't forget to solve today's problem!"
        content.sound = UNNotificationSound.default

        var dateComponents = DateComponents()
        dateComponents.hour = 9 // 9 AM
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "dailyReminder", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }
}

struct UsernameInputView: View {
    @Binding var username: String
    @State private var draftUsername: String = ""

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(.systemGray6), Color(.systemGray5)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // App Icon and Title
                VStack(spacing: 20) {
                    Image(systemName: "infinity.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    Text("LeetCode Tracker")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                // Input Section
                VStack(spacing: 20) {
                    Text("Enter your LeetCode username")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    HStack(spacing: 12) {
                        Image(systemName: "person.circle.fill")
                            .foregroundColor(.blue)
                            .font(.title2)
                        
                        TextField("Username", text: $draftUsername)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .submitLabel(.done)
                            .onSubmit {
                                saveUsername()
                            }
                    }
                    .padding(.horizontal, 20)
                    
                    Button(action: saveUsername) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.right.circle.fill")
                            Text("Get Started")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 15)
                        .background(
                            LinearGradient(
                                colors: [.blue, .blue.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(25)
                    }
                    .disabled(draftUsername.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity(draftUsername.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.6 : 1.0)
                }
                .padding(.horizontal, 40)
            }
        }
        .onAppear {
            draftUsername = username
        }
    }
    
    private func saveUsername() {
        let trimmed = draftUsername.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        username = trimmed
        #if canImport(UIKit)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #endif
    }
}
