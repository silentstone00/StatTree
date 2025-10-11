//
//  ProgressViewModel.swift
//  leetcode
//
//  Created by Aviral Saxena on 8/29/25.
//


// ProgressViewModel.swift
import Foundation
import SwiftUI

class ProgressViewModel: ObservableObject {
    @Published var calendar: [Date: Int] = [:]
    @Published var weakTopics: [String] = []
    @Published var isLoading = false
    @Published var currentMonth = Date()
    @Published var userProfile: UserProfile?
    @Published var error: Error?
    @Published var tagProblemCounts: TagProblemCounts?
    
    @AppStorage("leetcodeUsername") var username: String = ""
    
    var currentStreak: Int {
        // Calculate current streak from calendar data
        let today = Calendar.current.startOfDay(for: Date())
        var streak = 0
        var currentDate = today
        
        // Check if user has submission today or yesterday (to account for timezone differences)
        let todayCount = calendar[currentDate] ?? 0
        let yesterdayCount = calendar[Calendar.current.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate] ?? 0
        
        // If no submission today or yesterday, streak is 0
        if todayCount == 0 && yesterdayCount == 0 {
            return 0
        }
        
        // Start from yesterday if no submission today
        if todayCount == 0 {
            currentDate = Calendar.current.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
        }
        
        // Count consecutive days with submissions
        while let submissionCount = calendar[currentDate], submissionCount > 0 {
            streak += 1
            currentDate = Calendar.current.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
        }
        
        return streak
    }
    
    var bestStreak: Int {
        // Calculate best streak from calendar data
        let sortedDates = calendar.keys.sorted()
        var bestStreak = 0
        var currentStreak = 0
        var previousDate: Date?
        
        for date in sortedDates {
            if let submissionCount = calendar[date], submissionCount > 0 {
                if let prev = previousDate {
                    let daysBetween = Calendar.current.dateComponents([.day], from: prev, to: date).day ?? 0
                    if daysBetween == 1 {
                        currentStreak += 1
                    } else {
                        currentStreak = 1
                    }
                } else {
                    currentStreak = 1
                }
                bestStreak = max(bestStreak, currentStreak)
            } else {
                currentStreak = 0
            }
            previousDate = date
        }
        
        return bestStreak
    }
    
    var totalActiveDays: Int {
        return userProfile?.userCalendar?.totalActiveDays ?? calendar.keys.count
    }
    
    var currentMonthDisplay: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }
    
    var currentMonthDays: [Date?] {
        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: currentMonth)?.start ?? currentMonth
        let firstWeekday = calendar.component(.weekday, from: startOfMonth)
        let daysInMonth = calendar.range(of: .day, in: .month, for: currentMonth)?.count ?? 0
        
        var days: [Date?] = []
        
        // Add empty days for padding
        for _ in 1..<firstWeekday {
            days.append(nil)
        }
        
        // Add days of the month
        for day in 1...daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                days.append(date)
            }
        }
        
        return days
    }
    
    func fetchProgress() {
        guard !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            error = NSError(domain: "InvalidUsername", code: 400, userInfo: [NSLocalizedDescriptionKey: "Username not set"])
            return
        }
        
        isLoading = true
        error = nil
        
        // Fetch user profile with submission calendar
        LeetCodeAPI.shared.fetchUserProfile(username: username) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let profile):
                    self.userProfile = profile
                    self.parseSubmissionCalendar(profile.submissionCalendar)
                    self.fetchTagProblemCounts()
                case .failure(let err):
                    self.error = err
                    self.isLoading = false
                }
            }
        }
    }
    
    private func fetchTagProblemCounts() {
        LeetCodeAPI.shared.fetchTagProblemCounts(username: username) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let tagCounts):
                    self.tagProblemCounts = tagCounts
                    self.identifyWeakTopics(tagCounts)
                case .failure(let err):
                    print("Failed to fetch tag counts: \(err)")
                    // Don't set error here as main profile data is more important
                }
            }
        }
    }
    
    private func parseSubmissionCalendar(_ calendarString: String?) {
        guard let calendarString = calendarString else {
            print("No submission calendar data")
            return
        }
        
        print("Raw submission calendar: \(calendarString)")
        
        guard let data = calendarString.data(using: .utf8) else {
            print("Failed to convert calendar string to data")
            return
        }
        
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                print("Parsed JSON keys: \(Array(json.keys).prefix(5))")
                var parsedCalendar: [Date: Int] = [:]
                
                for (key, value) in json {
                    let count = value as? Int ?? 0
                    
                    // Try different date formats
                    if let timestamp = TimeInterval(key) {
                        // Handle timestamp format (seconds since epoch)
                        let date = Date(timeIntervalSince1970: timestamp)
                        let normalizedDate = Calendar.current.startOfDay(for: date)
                        parsedCalendar[normalizedDate] = count
                    } else {
                        // Try various date string formats
                        let formatters = [
                            "yyyy-MM-dd",
                            "MM/dd/yyyy",
                            "yyyy/MM/dd"
                        ]
                        
                        for format in formatters {
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = format
                            dateFormatter.timeZone = TimeZone.current
                            
                            if let date = dateFormatter.date(from: key) {
                                let normalizedDate = Calendar.current.startOfDay(for: date)
                                parsedCalendar[normalizedDate] = count
                                break
                            }
                        }
                    }
                }
                
                self.calendar = parsedCalendar
                print("Parsed \(parsedCalendar.count) calendar entries")
                
                // Debug: Print recent entries
                let recentEntries = parsedCalendar.filter { entry in
                    let daysDiff = Calendar.current.dateComponents([.day], from: entry.key, to: Date()).day ?? 0
                    return daysDiff >= 0 && daysDiff <= 7
                }
                print("Recent entries (last 7 days): \(recentEntries)")
                
            } else {
                print("Failed to parse JSON as dictionary")
            }
        } catch {
            print("JSON parsing error: \(error)")
        }
    }
    
    private func identifyWeakTopics(_ tagCounts: TagProblemCounts) {
        var allTopics: [(String, Int)] = []
        
        // Combine all difficulty levels
        allTopics.append(contentsOf: tagCounts.fundamental.map { ($0.tagName, $0.problemsSolved) })
        allTopics.append(contentsOf: tagCounts.intermediate.map { ($0.tagName, $0.problemsSolved) })
        allTopics.append(contentsOf: tagCounts.advanced.map { ($0.tagName, $0.problemsSolved) })
        
        // Sort by problems solved (ascending) and take topics with fewer solved problems
        let sortedTopics = allTopics.sorted { $0.1 < $1.1 }
        
        // Consider topics with 0-2 solved problems as weak
        self.weakTopics = sortedTopics
            .filter { $0.1 <= 2 }
            .prefix(5)
            .map { $0.0 }
    }
    
    func previousMonth() {
        if let newDate = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) {
            currentMonth = newDate
        }
    }
    
    func nextMonth() {
        if let newDate = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) {
            currentMonth = newDate
        }
    }
}
