// ProblemsView.swift
import SwiftUI
import WebKit

struct ProblemsView: View {
    @StateObject private var viewModel = ProblemsViewModel()
    @State private var showingFilters = false
    @State private var isSearchBarVisible = true
    @State private var lastScrollOffset: CGFloat = 0
    @FocusState private var isSearchFocused: Bool
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Clean background
                Color(.systemGray6)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Custom Navigation Title (always visible)
                    if isSearchBarVisible {
                        HStack {
                            Text("Problems")
                                .font(.system(size: 34, weight: .bold))
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 10)
                        .background(Color(.systemGray6))
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    // Modern Search and Filter Bar
                    if isSearchBarVisible {
                        VStack(spacing: 16) {
                            HStack(spacing: 12) {
                                // Search bar with icon
                                HStack(spacing: 10) {
                                    Image(systemName: "magnifyingglass")
                                        .foregroundColor(.secondary)
                                        .font(.system(size: 16, weight: .medium))
                                    
                                    TextField("Search problems...", text: $viewModel.query)
                                        .focused($isSearchFocused)
                                        .submitLabel(.search)
                                        .onSubmit {
                                            isSearchFocused = false
                                            viewModel.searchProblems()
                                        }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color(.systemBackground))
                                )
                                
                                // Filter button or Cancel
                                if isSearchFocused {
                                    Button("Cancel") {
                                        isSearchFocused = false
                                        viewModel.query = ""
                                        viewModel.fetchProblems(reset: true)
                                    }
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.blue)
                                    .transition(.move(edge: .trailing).combined(with: .opacity))
                                } else {
                                    Button(action: { 
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            showingFilters.toggle()
                                        }
                                    }) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 14)
                                                .fill(hasActiveFilters ? Color.blue : Color(.systemBackground))
                                            
                                            Image(systemName: showingFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                                                .foregroundColor(hasActiveFilters ? .white : .primary)
                                                .font(.system(size: 20, weight: .medium))
                                        }
                                        .frame(width: 48, height: 48)
                                    }
                                    .transition(.move(edge: .trailing).combined(with: .opacity))
                                }
                            }
                            
                            // Elegant Filter Chips
                            if showingFilters {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        FilterChip(title: "All", isSelected: viewModel.selectedDifficulty == nil) {
                                            viewModel.filterByDifficulty(nil)
                                        }
                                        FilterChip(title: "Easy", isSelected: viewModel.selectedDifficulty == "Easy") {
                                            viewModel.filterByDifficulty("Easy")
                                        }
                                        FilterChip(title: "Medium", isSelected: viewModel.selectedDifficulty == "Medium") {
                                            viewModel.filterByDifficulty("Medium")
                                        }
                                        FilterChip(title: "Hard", isSelected: viewModel.selectedDifficulty == "Hard") {
                                            viewModel.filterByDifficulty("Hard")
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                }
                                .transition(.move(edge: .top).combined(with: .opacity))
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 0)
                        .padding(.bottom, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    // Premium Problems List
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.problems) { problem in
                                NavigationLink(destination: ProblemDetailView(titleSlug: problem.titleSlug)) {
                                    ProblemCardView(problem: problem, viewModel: viewModel)
                                }
                                .buttonStyle(ProblemCardButtonStyle())
                                .onAppear {
                                    if viewModel.shouldLoadMore(for: problem) {
                                        viewModel.loadMoreProblems()
                                    }
                                }
                            }
                            
                            // Loading indicator
                            if viewModel.isLoading && !viewModel.problems.isEmpty {
                                HStack(spacing: 12) {
                                    ProgressView()
                                        .tint(.blue)
                                    Text("Loading more...")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 24)
                            }
                            
                            // End indicator
                            if !viewModel.hasMoreProblems && !viewModel.problems.isEmpty {
                                VStack(spacing: 8) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.green)
                                    Text("All problems loaded")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 24)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 20)
                    }
                    .refreshable {
                        viewModel.fetchProblems(reset: true)
                    }
                    .background(
                        GeometryReader { geometry in
                            Color.clear
                                .preference(key: ScrollOffsetPreferenceKey.self, value: geometry.frame(in: .global).minY)
                        }
                    )
                    .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                        handleScrollOffset(value)
                    }
                    .onTapGesture {
                        if isSearchFocused {
                            isSearchFocused = false
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isSearchBarVisible)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSearchFocused)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showingFilters)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        isSearchFocused = false
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            if viewModel.problems.isEmpty {
                viewModel.fetchSolved()
                viewModel.fetchProblems()
            }
        }
        .onChange(of: viewModel.query) { _, newValue in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if viewModel.query == newValue {
                    viewModel.searchProblems()
                }
            }
        }
    }
    
    private func handleScrollOffset(_ offset: CGFloat) {
        let threshold: CGFloat = 20
        let scrollDelta = offset - lastScrollOffset
        
        // Dismiss keyboard when scrolling
        if isSearchFocused && abs(scrollDelta) > 5 {
            isSearchFocused = false
        }
        
        // Only update if there's significant movement
        if abs(scrollDelta) > threshold {
            withAnimation(.easeInOut(duration: 0.25)) {
                if scrollDelta < 0 && isSearchBarVisible {
                    // Scrolling up (content moving down) - hide search bar
                    isSearchBarVisible = false
                } else if scrollDelta > 0 && !isSearchBarVisible {
                    // Scrolling down (content moving up) - show search bar
                    isSearchBarVisible = true
                }
            }
            lastScrollOffset = offset
        }
    }
    
    private var hasActiveFilters: Bool {
        viewModel.selectedDifficulty != nil || viewModel.selectedTag != nil
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
            return .secondary
        }
    }
}

// MARK: - Helper Views
struct ProblemCardView: View {
    let problem: Problem
    let viewModel: ProblemsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with title and status
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(problem.title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    // Difficulty and acceptance rate
                    HStack(spacing: 10) {
                        // Difficulty badge with gradient
                        HStack(spacing: 4) {
                            Circle()
                                .fill(difficultyColor(problem.difficulty))
                                .frame(width: 6, height: 6)
                            
                            Text(problem.difficulty)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(difficultyColor(problem.difficulty))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(difficultyColor(problem.difficulty).opacity(0.12))
                        )
                        
                        // Acceptance rate
                        HStack(spacing: 4) {
                            Image(systemName: "chart.bar.fill")
                                .font(.system(size: 10))
                            Text("\(String(format: "%.1f", problem.acRate))%")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Status indicators
                VStack(spacing: 8) {
                    if viewModel.solvedSlugs.contains(problem.titleSlug) {
                        ZStack {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    
                    if viewModel.bookmarked.contains(problem.titleSlug) {
                        ZStack {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: "bookmark.fill")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 16)
            .padding(.bottom, 12)
            
            // Topic tags
            if !problem.topicTags.isEmpty {
                Divider()
                    .padding(.horizontal, 18)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(problem.topicTags.prefix(3)), id: \.slug) { tag in
                            Text(tag.name)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(
                                    Capsule()
                                        .fill(Color(.systemGray6))
                                )
                        }
                        
                        if problem.topicTags.count > 3 {
                            Text("+\(problem.topicTags.count - 3)")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.blue)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(
                                    Capsule()
                                        .fill(Color.blue.opacity(0.1))
                                )
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                }
            } else {
                Spacer()
                    .frame(height: 12)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    viewModel.solvedSlugs.contains(problem.titleSlug) ? 
                        Color.green.opacity(0.3) : Color.clear,
                    lineWidth: 2
                )
        )
        .contextMenu {
            Button(action: {
                viewModel.toggleBookmark(for: problem)
            }) {
                Label(
                    viewModel.bookmarked.contains(problem.titleSlug) ? "Remove Bookmark" : "Add Bookmark",
                    systemImage: viewModel.bookmarked.contains(problem.titleSlug) ? "bookmark.slash" : "bookmark"
                )
            }
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
            return .secondary
        }
    }
}

// Custom button style for cards
struct ProblemCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                }
                
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Group {
                    if isSelected {
                        Capsule()
                            .fill(difficultyColor(title))
                    } else {
                        Capsule()
                            .fill(Color(.systemBackground))
                    }
                }
            )
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
    
    private func difficultyColor(_ title: String) -> Color {
        switch title.lowercased() {
        case "easy":
            return .green
        case "medium":
            return .orange
        case "hard":
            return .red
        default:
            return .blue
        }
    }
}

struct ProblemDetailView: View {
    let titleSlug: String
    @State private var detail: ProblemDetail?
    @State private var isLoading = true
    @State private var error: Error?

    var body: some View {
        NavigationStack {
            if isLoading {
                ProgressView()
            } else if let detail = detail {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Title and difficulty
                        VStack(alignment: .leading, spacing: 8) {
                            Text(detail.title)
                                .font(.title2)
                                .bold()
                            if let difficulty = detail.difficulty {
                                Text(difficulty)
                                    .font(.subheadline)
                                    .foregroundColor(difficultyColor(difficulty))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(difficultyColor(difficulty).opacity(0.1))
                                    .cornerRadius(4)
                            }
                        }
                        
                        // Problem description
                        if let html = detail.content {
                            HTMLWebView(htmlContent: html)
                                .frame(maxWidth: .infinity, minHeight: 600)
                        }
                    }
                    .padding()
                }
            } else if let error = error {
                VStack {
                    Text("Error loading problem")
                        .font(.headline)
                    Text(error.localizedDescription)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
        }
        .navigationTitle(detail?.title ?? "Problem")
        .onAppear {
            CodeAPI.shared.fetchProblemDetail(titleSlug: titleSlug) { result in
                DispatchQueue.main.async {
                    self.isLoading = false
                    switch result {
                    case .success(let d):
                        self.detail = d
                    case .failure(let e):
                        self.error = e
                    }
                }
            }
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
            return .secondary
        }
    }
    

}

struct HTMLWebView: UIViewRepresentable {
    let htmlContent: String
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.isOpaque = false
        webView.backgroundColor = UIColor.systemBackground
        webView.scrollView.isScrollEnabled = true
        webView.scrollView.bounces = true
        webView.scrollView.showsVerticalScrollIndicator = true
        webView.scrollView.showsHorizontalScrollIndicator = false
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        // Create HTML with proper styling for dark mode support
        let htmlString = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                    font-size: 16px;
                    line-height: 1.5;
                    margin: 0;
                    padding: 16px;
                    color: #000000;
                    background-color: #ffffff;
                }
                @media (prefers-color-scheme: dark) {
                    body {
                        color: #ffffff;
                        background-color: #000000;
                    }
                }
                pre {
                    background-color: #f6f8fa;
                    border-radius: 6px;
                    padding: 16px;
                    overflow-x: auto;
                    font-family: 'SF Mono', Monaco, 'Cascadia Code', 'Roboto Mono', Consolas, 'Courier New', monospace;
                    font-size: 14px;
                    line-height: 1.45;
                }
                @media (prefers-color-scheme: dark) {
                    pre {
                        background-color: #2d3748;
                    }
                }
                code {
                    background-color: #f6f8fa;
                    padding: 2px 4px;
                    border-radius: 3px;
                    font-family: 'SF Mono', Monaco, 'Cascadia Code', 'Roboto Mono', Consolas, 'Courier New', monospace;
                    font-size: 14px;
                }
                @media (prefers-color-scheme: dark) {
                    code {
                        background-color: #2d3748;
                    }
                }
                p {
                    margin: 0 0 16px 0;
                }
                ul, ol {
                    margin: 0 0 16px 0;
                    padding-left: 20px;
                }
                li {
                    margin: 0 0 8px 0;
                }
                h1, h2, h3, h4, h5, h6 {
                    margin: 24px 0 16px 0;
                    font-weight: 600;
                }
                blockquote {
                    margin: 0 0 16px 0;
                    padding: 0 16px;
                    border-left: 4px solid #dfe2e5;
                    color: #6a737d;
                }
                @media (prefers-color-scheme: dark) {
                    blockquote {
                        border-left-color: #4a5568;
                        color: #a0aec0;
                    }
                }
                table {
                    border-collapse: collapse;
                    width: 100%;
                    margin: 16px 0;
                }
                th, td {
                    border: 1px solid #dfe2e5;
                    padding: 8px 12px;
                    text-align: left;
                }
                @media (prefers-color-scheme: dark) {
                    th, td {
                        border-color: #4a5568;
                    }
                }
                th {
                    background-color: #f6f8fa;
                    font-weight: 600;
                }
                @media (prefers-color-scheme: dark) {
                    th {
                        background-color: #2d3748;
                    }
                }
            </style>
        </head>
        <body>
            \(htmlContent)
        </body>
        </html>
        """
        
        webView.loadHTMLString(htmlString, baseURL: nil)
    }
}

// MARK: - Scroll Detection
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
