//
//  ProgressView.swift
//  leetcode
//
//  Created by Aviral Saxena on 8/29/25.
//


// ProgressView.swift
import SwiftUI
import Charts

struct UserProgressView: View {
    @StateObject private var viewModel = ProgressViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGray6)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Custom Navigation Title
                    HStack {
                        Text("Progress")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 4)
                    .background(Color(.systemGray6))
                    
                    ScrollView {
                        VStack(spacing: 20) {
                            if viewModel.isLoading && viewModel.userProfile == nil {
                            loadingView
                        } else if let error = viewModel.error {
                            errorView(error)
                        } else {
                            // Streak Section
                            streakSection
                            
                            // Monthly Calendar
                            monthlyCalendarSection
                            
                            // Weak Topics
                            weakTopicsSection
                        }
                    }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 20)
                    }
                    .refreshable {
                        viewModel.fetchProgress()
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            viewModel.fetchProgress()
        }
    }
    
    // MARK: - Streak Section
    private var streakSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
                    .font(.title2)
                
                Text("Current Streak")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            HStack(spacing: 20) {
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                            .font(.title)
                        
                        Text("\(viewModel.currentStreak)")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }
                    
                    Text("current streak")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    VStack(spacing: 4) {
                        Text("Best Streak")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("\(viewModel.bestStreak)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                        
                        Text("days")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                        .frame(width: 60)
                    
                    VStack(spacing: 4) {
                        Text("Active Days")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("\(viewModel.totalActiveDays)")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                        
                        Text("total")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(.systemBackground))
            .cornerRadius(16)
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(20)
    }
    
    // MARK: - Monthly Calendar Section
    private var monthlyCalendarSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "calendar.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
                
                Text("Submission Calendar")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            if viewModel.calendar.isEmpty {
                emptyCalendarView
            } else {
                // Month Selector
                monthSelector
                
                // Calendar Grid
                calendarGrid
                
                // Legend
                calendarLegend
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(20)
    }
    
    // MARK: - Month Selector
    private var monthSelector: some View {
        HStack {
            Button(action: { viewModel.previousMonth() }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.blue)
                    .font(.title3)
            }
            
            Spacer()
            
            Text(viewModel.currentMonthDisplay)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Spacer()
            
            Button(action: { viewModel.nextMonth() }) {
                Image(systemName: "chevron.right")
                    .foregroundColor(.blue)
                    .font(.title3)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Calendar Grid
    private var calendarGrid: some View {
        VStack(spacing: 8) {
            // Day headers
            HStack(spacing: 8) {
                ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Calendar days
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 4) {
                ForEach(viewModel.currentMonthDays, id: \.self) { date in
                    if let date = date {
                        let submissionCount = viewModel.calendar[normalizedDate(date)] ?? 0
                        let color = submissionColor(submissionCount)
                        let textColor = submissionCount > 0 ? Color.white : Color.primary
                        
                        VStack {
                            Text("\(Calendar.current.component(.day, from: date))")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(textColor)
                        }
                        .frame(width: 32, height: 32)
                        .background(color)
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
                        )
                    } else {
                        Color.clear
                            .frame(width: 32, height: 32)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    // MARK: - Calendar Legend
    private var calendarLegend: some View {
        VStack(spacing: 8) {
            Text("Less")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            HStack(spacing: 4) {
                ForEach(0..<5) { level in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(submissionColor(level == 0 ? 0 : (level == 1 ? 1 : (level == 2 ? 3 : (level == 3 ? 7 : 10)))))
                        .frame(width: 12, height: 12)
                }
            }
            
            Text("More")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Weak Topics Section
    private var weakTopicsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .font(.title2)
                
                Text("Areas for Improvement")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            if viewModel.weakTopics.isEmpty {
                Text("Great job! No weak topics identified.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
            } else {
                VStack(spacing: 12) {
                    ForEach(Array(viewModel.weakTopics.enumerated()), id: \.offset) { index, topic in
                        HStack {
                            Text("\(index + 1)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(width: 24, height: 24)
                                .background(Color.orange)
                                .clipShape(Circle())
                            
                            Text(topic)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Button("Practice") {
                                // Navigate to problems with this tag
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(20)
    }
    
    // MARK: - Empty Calendar View
    private var emptyCalendarView: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            Text("No submission data")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Start solving problems to see your progress!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
            
            Text("Loading progress...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
    
    // MARK: - Error View
    private func errorView(_ error: Error) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("Failed to load progress")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(error.localizedDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Retry") {
                viewModel.fetchProgress()
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.blue)
            .cornerRadius(12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
    
    // MARK: - Helper Functions
    private func submissionColor(_ count: Int) -> Color {
        switch count {
        case 0:
            return Color(.systemGray5)
        case 1:
            return Color.green.opacity(0.3)
        case 2...4:
            return Color.green.opacity(0.6)
        case 5...9:
            return Color.green.opacity(0.8)
        default:
            return Color.green
        }
    }
    
    private func normalizedDate(_ date: Date) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return calendar.date(from: components) ?? date
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd"
        return formatter.string(from: date)
    }
    

}

#Preview {
    UserProgressView()
}