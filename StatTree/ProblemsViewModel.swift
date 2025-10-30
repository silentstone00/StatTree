//
//  ProblemsViewModel.swift
//
//  Created by Aviral Saxena on 8/29/25.
//


// ProblemsViewModel.swift
import Foundation
import SwiftUI

class ProblemsViewModel: ObservableObject {
    @Published var problems: [Problem] = []
    @Published var bookmarked: Set<String> = UserDefaults.standard.object(forKey: "bookmarked") as? Set<String> ?? []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var error: Error?
    @Published var solvedSlugs: Set<String> = []
    @Published var query: String = ""
    @Published var selectedTag: String? = nil
    @Published var selectedDifficulty: String? = nil
    @Published var totalProblemsCount: Int = 0
    @Published var hasMoreProblems = true
    
    private var currentSkip = 0
    private let pageSize = 50
    private var lastSearchQuery = ""
    private var lastDifficulty: String? = nil
    private var lastTag: String? = nil
    
    @AppStorage("Username") var username: String = ""
    
    func fetchProblems(difficulty: String? = nil, tag: String? = nil, reset: Bool = true) {
        // Check if this is a new search/filter - if so, reset pagination
        let isNewSearch = reset || 
                         query != lastSearchQuery || 
                         difficulty != lastDifficulty || 
                         tag != lastTag
        
        if isNewSearch {
            currentSkip = 0
            hasMoreProblems = true
            if reset {
                problems = []
            }
        }
        
        // Don't fetch if we're already loading or no more problems
        guard !isLoading && hasMoreProblems else { return }
        
        isLoading = true
        
        var filters: [String: Any] = [:]
        if let difficulty = difficulty {
            filters["difficulty"] = difficulty.uppercased()
        }
        if let tag = tag {
            filters["tags"] = [tag]
        }
        if !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            filters["searchKeywords"] = query
        }
        
        // Store current search parameters
        lastSearchQuery = query
        lastDifficulty = difficulty
        lastTag = tag
        
        CodeAPI.shared.fetchProblems(
            limit: pageSize,
            skip: currentSkip,
            filters: filters
        ) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let newProblems):
                    if isNewSearch && reset {
                        self.problems = newProblems
                    } else {
                        // Append new problems, avoiding duplicates
                        let existingSlugs = Set(self.problems.map { $0.titleSlug })
                        let uniqueNewProblems = newProblems.filter { !existingSlugs.contains($0.titleSlug) }
                        self.problems.append(contentsOf: uniqueNewProblems)
                    }
                    
                    // Update pagination state
                    self.currentSkip += newProblems.count
                    self.hasMoreProblems = newProblems.count == self.pageSize
                    
                case .failure(let err):
                    self.error = err
                }
            }
        }
    }
    
    func fetchSolved() {
        guard !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        CodeAPI.shared.fetchUserSolvedProblems(username: username) { result in
            DispatchQueue.main.async {
                if case .success(let slugs) = result {
                    self.solvedSlugs = Set(slugs)
                }
            }
        }
    }
    
    func toggleBookmark(for problem: Problem) {
        if bookmarked.contains(problem.titleSlug) {
            bookmarked.remove(problem.titleSlug)
        } else {
            bookmarked.insert(problem.titleSlug)
        }
        UserDefaults.standard.set(Array(bookmarked), forKey: "bookmarked")
    }
    
    // MARK: - Load More Problems
    func loadMoreProblems() {
        guard !isLoading && hasMoreProblems else { return }
        fetchProblems(difficulty: selectedDifficulty, tag: selectedTag, reset: false)
    }
    
    // MARK: - Search and Filter
    func searchProblems() {
        fetchProblems(difficulty: selectedDifficulty, tag: selectedTag, reset: true)
    }
    
    func filterByDifficulty(_ difficulty: String?) {
        selectedDifficulty = difficulty
        fetchProblems(difficulty: difficulty, tag: selectedTag, reset: true)
    }
    
    func filterByTag(_ tag: String?) {
        selectedTag = tag
        fetchProblems(difficulty: selectedDifficulty, tag: tag, reset: true)
    }
    
    // MARK: - Check if should load more
    func shouldLoadMore(for problem: Problem) -> Bool {
        guard let index = problems.firstIndex(where: { $0.titleSlug == problem.titleSlug }) else {
            return false
        }
        return index >= problems.count - 5 // Load more when 5 items from the end
    }
}
