//
//  DailyChallengeView.swift
//  leetcode
//
//  Created by Aviral Saxena on 8/29/25.
//

import SwiftUI

struct DailyChallengeView: View {
    @StateObject private var viewModel = DailyChallengeViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGray6)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Custom Navigation Title
                    HStack {
                        Text("Daily Challenge")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(.primary)
                        Spacer()
                        
                        Button(action: {
                            Task {
                                await refreshData()
                            }
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(.blue)
                                .font(.system(size: 20, weight: .medium))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 4)
                    .background(Color(.systemGray6))
                    
                    ScrollView {
                        if viewModel.isLoading {
                        loadingView
                    } else if let challenge = viewModel.challenge {
                        VStack(spacing: 20) {
                            // Header Section
                            headerSection(challenge)
                            
                            // Problem Description Section
                            if let problemDetail = viewModel.problemDetail {
                                problemDescriptionSection(problemDetail)
                            } else if viewModel.isLoadingDetail {
                                loadingDetailView
                            }
                        }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 20)
                        } else if let error = viewModel.error {
                            errorView(error)
                        }
                    }
                    .refreshable {
                        await refreshData()
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            refreshDataOnAppear()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            refreshDataOnAppear()
        }
    }
    
    // MARK: - Data Refresh Methods
    private func refreshDataOnAppear() {
        viewModel.fetchDailyChallenge()
    }
    
    private func refreshData() async {
        await viewModel.fetchDailyChallengeAsync()
    }
    
    // MARK: - Header Section
    private func headerSection(_ challenge: DailyChallenge) -> some View {
        VStack(spacing: 20) {
            // Challenge Info
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "calendar.badge.plus")
                        .font(.title)
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Daily Challenge")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("Today's Problem")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                
                // Problem Title
                Text(challenge.question.title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            // Stats Grid - Real Data Only
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                StatCard(
                    icon: "chart.bar.fill",
                    iconColor: difficultyColor(challenge.question.difficulty),
                    title: "Difficulty",
                    value: challenge.question.difficulty,
                    subtitle: "level"
                )
                
                StatCard(
                    icon: "percent",
                    iconColor: .blue,
                    title: "Acceptance Rate",
                    value: "\(String(format: "%.1f", challenge.question.acRate))%",
                    subtitle: "success rate"
                )
                
                StatCard(
                    icon: "tag.fill",
                    iconColor: .purple,
                    title: "Topics",
                    value: "\(challenge.question.topicTags.count)",
                    subtitle: "tags"
                )
                
                StatCard(
                    icon: "calendar.badge.clock",
                    iconColor: .orange,
                    title: "Today's",
                    value: "Challenge",
                    subtitle: "problem"
                )
            }
        }
        .padding(24)
        .background(Color(.systemBackground))
        .cornerRadius(20)
    }
    
    // MARK: - Problem Description Section
    private func problemDescriptionSection(_ problemDetail: ProblemDetail) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "doc.text.fill")
                    .foregroundColor(.green)
                    .font(.title3)
                
                Text("Problem Description")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            HTMLWebView(htmlContent: problemDetail.content ?? "")
                .frame(maxWidth: .infinity, minHeight: 600)
                .background(Color(.systemBackground))
                .cornerRadius(16)
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(20)
    }
    
    // MARK: - Loading Views
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
            
            Text("Loading daily challenge...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
    
    private var loadingDetailView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .progressViewStyle(CircularProgressViewStyle(tint: .green))
            
            Text("Loading problem details...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    // MARK: - Error View
    private func errorView(_ error: Error) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("Error loading challenge")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(error.localizedDescription)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Retry") {
                refreshDataOnAppear()
            }
            .foregroundColor(.blue)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Helper Functions
    private func difficultyColor(_ difficulty: String) -> Color {
        switch difficulty.lowercased() {
        case "easy":
            return .green
        case "medium":
            return .orange
        case "hard":
            return .red
        default:
            return .gray
        }
    }
}

#Preview {
    DailyChallengeView()
}