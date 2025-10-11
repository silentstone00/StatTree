// DailyChallengeViewModel.swift
import Foundation

class DailyChallengeViewModel: ObservableObject {
    @Published var challenge: DailyChallenge?
    @Published var problemDetail: ProblemDetail?
    @Published var isLoading = false
    @Published var isLoadingDetail = false
    @Published var error: Error?
    
    // Cache for problem details
    private var problemDetailCache: [String: ProblemDetail] = [:]
    private var lastFetchDate: Date?
    
    func fetchDailyChallenge() {
        isLoading = true
        isLoadingDetail = true
        
        LeetCodeAPI.shared.fetchDailyChallenge { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let ch):
                    self.challenge = ch
                    // Immediately fetch problem detail in parallel
                    self.fetchProblemDetail()
                case .failure(let err):
                    self.error = err
                    self.isLoadingDetail = false
                }
            }
        }
    }
    
    @MainActor
    func fetchDailyChallengeAsync() async {
        isLoading = true
        isLoadingDetail = true
        
        do {
            // Fetch both challenge and problem detail in parallel
            async let challengeTask = withCheckedThrowingContinuation { continuation in
                LeetCodeAPI.shared.fetchDailyChallenge { result in
                    continuation.resume(with: result)
                }
            }
            
            let ch = try await challengeTask
            self.challenge = ch
            self.isLoading = false
            self.error = nil
            
            // Now fetch problem detail
            await fetchProblemDetailAsync()
            
        } catch {
            self.error = error
            self.isLoading = false
            self.isLoadingDetail = false
        }
    }
    
    private func fetchProblemDetail() {
        guard let challenge = challenge else { return }
        
        let titleSlug = challenge.question.titleSlug
        
        // Check cache first
        if let cachedDetail = problemDetailCache[titleSlug] {
            self.problemDetail = cachedDetail
            self.isLoadingDetail = false
            return
        }
        
        isLoadingDetail = true
        LeetCodeAPI.shared.fetchProblemDetail(titleSlug: titleSlug) { result in
            DispatchQueue.main.async {
                self.isLoadingDetail = false
                switch result {
                case .success(let detail):
                    self.problemDetail = detail
                    // Cache the result
                    self.problemDetailCache[titleSlug] = detail
                case .failure(let err):
                    print("Error fetching problem detail: \(err)")
                }
            }
        }
    }
    
    @MainActor
    private func fetchProblemDetailAsync() async {
        guard let challenge = challenge else { return }
        
        let titleSlug = challenge.question.titleSlug
        
        // Check cache first
        if let cachedDetail = problemDetailCache[titleSlug] {
            self.problemDetail = cachedDetail
            self.isLoadingDetail = false
            return
        }
        
        isLoadingDetail = true
        
        do {
            let detail = try await withCheckedThrowingContinuation { continuation in
                LeetCodeAPI.shared.fetchProblemDetail(titleSlug: titleSlug) { result in
                    continuation.resume(with: result)
                }
            }
            
            self.problemDetail = detail
            // Cache the result
            self.problemDetailCache[titleSlug] = detail
            
        } catch {
            print("Error fetching problem detail: \(error)")
        }
        
        self.isLoadingDetail = false
    }
}
