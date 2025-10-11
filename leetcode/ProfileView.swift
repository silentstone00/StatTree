import SwiftUI
import Charts

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @StateObject private var contestsViewModel = ContestsViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGray6)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Custom Navigation Title
                    HStack {
                        Text("Profile")
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
                        VStack(spacing: 20) {
                            if viewModel.isLoading {
                            loadingView
                        } else if let profile = viewModel.profile {
                            // Profile Header
                            profileHeader(profile)
                            
                            // Stats Overview
                            statsOverview(profile)
                            
                            // Difficulty Breakdown
                            difficultyBreakdown(profile)
                            
                            // Contest Performance
                            contestPerformance
                            
                            // Badges
                            badgesSection(profile)
                        } else if let error = viewModel.error {
                            errorView(error)
                        }
                    }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 20)
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
        viewModel.fetchProfile()
        contestsViewModel.fetchContests()
    }
    
    private func refreshData() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await viewModel.fetchProfileAsync()
            }
            group.addTask {
                await contestsViewModel.fetchContestsAsync()
            }
        }
    }
    
    // MARK: - Profile Header
    private func profileHeader(_ profile: UserProfile) -> some View {
        VStack(spacing: 20) {
            // Avatar and Name
            HStack(spacing: 16) {
                AsyncImage(url: URL(string: profile.profile?.userAvatar ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.blue.opacity(0.3), lineWidth: 3)
                        )
                } placeholder: {
                    Circle()
                        .fill(Color(.systemGray4))
                        .frame(width: 80, height: 80)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.secondary)
                        )
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(profile.profile?.realName ?? profile.username)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("@\(profile.username)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Ranking
            if let ranking = profile.profile?.ranking {
                HStack(spacing: 12) {
                    Image(systemName: "trophy.fill")
                        .foregroundColor(.yellow)
                        .font(.title3)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Ranking")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("#\(ranking)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color(.systemBackground))
                .cornerRadius(16)
            }
        }
        .padding(24)
        .background(Color(.systemBackground))
        .cornerRadius(20)
    }
    
    // MARK: - Stats Overview
    private func statsOverview(_ profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.blue)
                    .font(.title3)
                
                Text("Overview")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                if let cal = profile.userCalendar {
                    StatCard(
                        icon: "flame.fill",
                        iconColor: .orange,
                        title: "Streak",
                        value: "\(cal.streak)",
                        subtitle: "days"
                    )
                    
                    StatCard(
                        icon: "calendar.circle.fill",
                        iconColor: .green,
                        title: "Active Days",
                        value: "\(cal.totalActiveDays)",
                        subtitle: "total"
                    )
                }
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(20)
    }
    
    // MARK: - Difficulty Breakdown
    private func difficultyBreakdown(_ profile: UserProfile) -> some View {
        PlayfulInteractiveChart(profile: profile)
    }
}

// MARK: - Floating Emoji
struct FloatingEmoji: Identifiable {
    let id = UUID()
    let emoji: String
    let x: CGFloat
    let y: CGFloat
}

struct TapLocationPreferenceKey: PreferenceKey {
    static var defaultValue: CGPoint = .zero
    static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) {
        value = nextValue()
    }
}

// MARK: - Playful Interactive Chart
struct PlayfulInteractiveChart: View {
    let profile: UserProfile
    @State private var selectedDifficulty: String? = nil
    @State private var isChartPressed = false
    @State private var rotationAngle: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var floatingEmojis: [FloatingEmoji] = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: selectedDifficulty == nil ? "chart.pie.fill" : "sparkles")
                    .foregroundColor(.purple)
                    .font(.title3)
                    .symbolEffect(.bounce, value: selectedDifficulty)
                
                Text("Problems Solved")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if selectedDifficulty != nil {
                    Button(action: {
                        let impact = UIImpactFeedbackGenerator(style: .soft)
                        impact.impactOccurred()
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                            selectedDifficulty = nil
                            rotationAngle = 0
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.caption)
                            Text("Reset")
                                .font(.caption)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.purple)
                        )
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            
            if let submitStats = profile.submitStats?.acSubmissionNum {
                let filteredStats = submitStats.filter { 
                    let diff = $0.difficulty?.lowercased() ?? ""
                    return diff == "easy" || diff == "medium" || diff == "hard"
                }
                
                let totalProblems = filteredStats.reduce(0) { $0 + ($1.count ?? 0) }
                
                VStack(spacing: 20) {
                    // Interactive Chart with Floating Emojis
                    ZStack {
                        GeometryReader { geometry in
                            ZStack{
                                Color.clear.preference(key: TapLocationPreferenceKey.self, value: .zero)
                                
                                
                                ZStack {
                                    // Outer glow ring when selected
                                    if selectedDifficulty != nil {
                                        Circle()
                                            .stroke(
                                                difficultyColor(selectedDifficulty ?? "").opacity(0.3),
                                                lineWidth: 8
                                            )
                                            .frame(height: 240)
                                            .scaleEffect(pulseScale)
                                            .onAppear {
                                                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                                                    pulseScale = 1.1
                                                }
                                            }
                                            .onDisappear {
                                                pulseScale = 1.0
                                            }
                                    }
                                    
                                    Chart {
                                        ForEach(filteredStats, id: \.difficulty) { stat in
                                            SectorMark(
                                                angle: .value("Count", stat.count ?? 0),
                                                innerRadius: .ratio(0.6),
                                                angularInset: 2
                                            )
                                            .foregroundStyle(difficultyColor(stat.difficulty ?? ""))
                                            .opacity(selectedDifficulty == nil || selectedDifficulty == stat.difficulty ? 1.0 : 0.2)
                                        }
                                    }
                                    .frame(height: 220)
                                    .rotationEffect(.degrees(rotationAngle))
                                    .scaleEffect(isChartPressed ? 0.95 : 1.0)
                                    .gesture(
                                        DragGesture(minimumDistance: 0)
                                            .onEnded { value in
                                                // Spawn emoji at tap location
                                                let emoji = randomEmoji()
                                                let newEmoji = FloatingEmoji(
                                                    emoji: emoji,
                                                    x: value.location.x,
                                                    y: value.location.y
                                                )
                                                floatingEmojis.append(newEmoji)
                                                
                                                // Remove after animation
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                                    floatingEmojis.removeAll { $0.id == newEmoji.id }
                                                }
                                                
                                                // Haptic feedback
                                                let impact = UIImpactFeedbackGenerator(style: .medium)
                                                impact.impactOccurred()
                                                
                                                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                                                    isChartPressed = true
                                                    rotationAngle += 120
                                                }
                                                
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                        isChartPressed = false
                                                    }
                                                }
                                                
                                                // Cycle through difficulties
                                                if selectedDifficulty == nil {
                                                    selectedDifficulty = "Easy"
                                                } else if selectedDifficulty == "Easy" {
                                                    selectedDifficulty = "Medium"
                                                } else if selectedDifficulty == "Medium" {
                                                    selectedDifficulty = "Hard"
                                                } else {
                                                    selectedDifficulty = nil
                                                    rotationAngle = 0
                                                }
                                            }
                                    )
                                    
                                    // Floating Emojis Overlay
                                    ForEach(floatingEmojis) { emoji in
                                        Text(emoji.emoji)
                                            .font(.system(size: 32))
                                            .position(x: emoji.x, y: emoji.y)
                                            .transition(.scale.combined(with: .opacity))
                                            .modifier(FloatingModifier())
                                    }
                                }
                                .frame(width: geometry.size.width, height: 220)
                            }
                        }
                        .frame(height: 220)
                            
                            // Center display with animations
                            VStack(spacing: 6) {
                        if let selected = selectedDifficulty,
                           let stat = filteredStats.first(where: { $0.difficulty == selected }) {
                            // Selected difficulty view
                            VStack(spacing: 4) {
                                Image(systemName: difficultyIcon(selected))
                                    .font(.system(size: 24))
                                    .foregroundColor(difficultyColor(selected))
                                    .symbolEffect(.bounce, value: selectedDifficulty)
                                
                                Text("\(stat.count ?? 0)")
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundColor(difficultyColor(selected))
                                    .contentTransition(.numericText())
                                
                                Text(selected)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(difficultyColor(selected))
                                
                                Text("\(Int(Double(stat.count ?? 0) / Double(totalProblems) * 100))%")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            // Default "All" view - no icon
                            VStack(spacing: 4) {
                                Text("\(totalProblems)")
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundColor(.primary)
                                    .contentTransition(.numericText())
                                
                                Text("All")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            }
                        }
                        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: selectedDifficulty)
                        }
                        .frame(height: 220)
                    }
                    .frame(height: 220)
                    
                    // Interactive Legend Cards
                    VStack(spacing: 10) {
                        ForEach(filteredStats, id: \.difficulty) { stat in
                            Button(action: {
                                let impact = UIImpactFeedbackGenerator(style: .light)
                                impact.impactOccurred()
                                
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    if selectedDifficulty == stat.difficulty {
                                        selectedDifficulty = nil
                                        rotationAngle = 0
                                    } else {
                                        selectedDifficulty = stat.difficulty
                                        rotationAngle = rotationForDifficulty(stat.difficulty ?? "")
                                    }
                                }
                            }) {
                                HStack(spacing: 14) {
                                    // Animated icon
                                    ZStack {
                                        Circle()
                                            .fill(difficultyColor(stat.difficulty ?? "").opacity(0.15))
                                            .frame(width: 40, height: 40)
                                        
                                        Image(systemName: difficultyIcon(stat.difficulty ?? ""))
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(difficultyColor(stat.difficulty ?? ""))
                                            .symbolEffect(.bounce, value: selectedDifficulty == stat.difficulty)
                                    }
                                    .scaleEffect(selectedDifficulty == stat.difficulty ? 1.1 : 1.0)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(stat.difficulty ?? "")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.primary)
                                        
                                        Text("\(Int(Double(stat.count ?? 0) / Double(totalProblems) * 100))% of total")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    // Count with animation
                                    Text("\(stat.count ?? 0)")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(difficultyColor(stat.difficulty ?? ""))
                                        .contentTransition(.numericText())
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .rotationEffect(.degrees(selectedDifficulty == stat.difficulty ? 90 : 0))
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(selectedDifficulty == stat.difficulty ? 
                                            difficultyColor(stat.difficulty ?? "").opacity(0.08) : 
                                            Color(.systemGray6))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .strokeBorder(
                                            selectedDifficulty == stat.difficulty ? 
                                                difficultyColor(stat.difficulty ?? "") : 
                                                Color.clear,
                                            lineWidth: 2
                                        )
                                )
                                .scaleEffect(selectedDifficulty == stat.difficulty ? 1.02 : 1.0)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .sensoryFeedback(.selection, trigger: selectedDifficulty)
                        }
                    }
                }
            }
            .padding(20)
            .background(Color(.systemBackground))
            .cornerRadius(20)
        }
    }
    
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
    
    private func difficultyIcon(_ difficulty: String) -> String {
        switch difficulty.lowercased() {
        case "easy":
            return "leaf.fill"
        case "medium":
            return "lightbulb.fill"
        case "hard":
            return "bolt.fill"
        default:
            return "star.fill"
        }
    }
    
    private func rotationForDifficulty(_ difficulty: String) -> Double {
        switch difficulty.lowercased() {
        case "easy":
            return 0
        case "medium":
            return 120
        case "hard":
            return 240
        default:
            return 0
        }
    }
    
    private func randomEmoji() -> String {
        let emojis = ["🎉", "✨", "🌟", "💫", "⭐️", "🎊", "🎈", "💥", "🔥", "⚡️", "💪", "🚀", "🎯", "👏", "🏆", "💯", "✅", "🌈", "🎨", "💝"]
        return emojis.randomElement() ?? "✨"
    }

// MARK: - Floating Animation Modifier
struct FloatingModifier: ViewModifier {
    @State private var offset: CGFloat = 0
    @State private var opacity: Double = 1.0
    @State private var scale: CGFloat = 1.0
    @State private var rotation: Double = 0
    
    func body(content: Content) -> some View {
        content
            .offset(y: offset)
            .opacity(opacity)
            .scaleEffect(scale)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                withAnimation(.easeOut(duration: 2.0)) {
                    offset = -150
                    opacity = 0
                }
                withAnimation(.easeInOut(duration: 0.3)) {
                    scale = 1.5
                }
                withAnimation(.linear(duration: 2.0)) {
                    rotation = Double.random(in: -30...30)
                }
            }
    }
}

extension ProfileView {
    
    // MARK: - Contest Performance
    private var contestPerformance: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundColor(.yellow)
                    .font(.title3)
                
                Text("Contest Performance")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            if let history = contestsViewModel.contestHistory {
                VStack(spacing: 16) {
                    HStack(spacing: 20) {
                        VStack(spacing: 8) {
                            Text("Rating")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(String(format: "%.0f", history.rating))
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                        }
                        
                        VStack(spacing: 8) {
                            Text("Rank")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("#\(history.globalRanking)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                        }
                        
                        VStack(spacing: 8) {
                            Text("Top %")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(String(format: "%.1f", history.topPercentage))
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    
                    // Recent Contests
                    if !history.history.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recent Contests")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            
                            ForEach(history.history.prefix(3), id: \.id) { entry in
                                if entry.attended {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(entry.contest.title)
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .lineLimit(1)
                                            
                                            Text("Rank: #\(entry.ranking)")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        VStack(alignment: .trailing, spacing: 4) {
                                            Text("\(entry.problemsSolved)")
                                                .font(.subheadline)
                                                .fontWeight(.bold)
                                                .foregroundColor(.green)
                                            
                                            Text("solved")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                                }
                            }
                        }
                    }
                }
            } else {
                Text("No contest data available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(20)
    }
    
    // MARK: - Badges Section
    private func badgesSection(_ profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "medal.fill")
                    .foregroundColor(.orange)
                    .font(.title3)
                
                Text("Badges")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            if let badges = profile.badges, !badges.isEmpty {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                    ForEach(badges.prefix(6), id: \.id) { badge in
                        VStack(spacing: 8) {
                            Image(systemName: "medal.fill")
                                .font(.title2)
                                .foregroundColor(.orange)
                            
                            Text(badge.displayName ?? "Badge")
                                .font(.caption)
                                .fontWeight(.medium)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }
            } else {
                Text("No badges earned yet")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(20)
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
            
            Text("Loading profile...")
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
            
            Text("Error loading profile")
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

// MARK: - Stat Card
struct StatCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(iconColor)
            
            VStack(spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}
