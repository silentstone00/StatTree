// LeetCodeAPI.swift
import Foundation

class CodeAPI {
    static let shared = CodeAPI()
    
    private let baseURL = URL(string: "https://leetcode.com/graphql")!
    
    func fetchUserProfile(username: String, completion: @escaping (Result<UserProfile, Error>) -> Void) {
        guard !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            completion(.failure(NSError(domain: "InvalidUsername", code: 400, userInfo: [NSLocalizedDescriptionKey: "Username is empty"])) )
            return
        }
        let query = """
query {
  matchedUser(username: "\(username)") {
    username
    profile {
      ranking
      userAvatar
      realName
    }
    submitStats {
      acSubmissionNum {
        difficulty
        count
      }
    }
    submissionCalendar
  }
}
"""
        let requestBody = ["query": query, "variables": [:]] as [String : Any]
        
        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("https://leetcode.com", forHTTPHeaderField: "Origin")
        request.setValue("https://leetcode.com/contest/", forHTTPHeaderField: "Referer")
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148", forHTTPHeaderField: "User-Agent")
        request.setValue("https://leetcode.com", forHTTPHeaderField: "Origin")
        request.setValue("https://leetcode.com/problemset/", forHTTPHeaderField: "Referer")
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148", forHTTPHeaderField: "User-Agent")
        request.setValue("https://leetcode.com", forHTTPHeaderField: "Origin")
        request.setValue("https://leetcode.com", forHTTPHeaderField: "Referer")
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148", forHTTPHeaderField: "User-Agent")
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            #if DEBUG
            if let http = response as? HTTPURLResponse {
                print("[Profile] HTTP \(http.statusCode)")
            }
            #endif
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(NSError(domain: "No data", code: 0)))
                return
            }
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                #if DEBUG
                if let errors = json?["errors"] as? [[String: Any]] {
                    print("[Profile] GraphQL errors: \(errors)")
                }
                if let dataDictLog = json?["data"] as? [String: Any] {
                    print("[Profile] data keys: \(Array(dataDictLog.keys))")
                }
                #endif
                let dataDict = json?["data"] as? [String: Any]
                guard let matchedUser = dataDict?["matchedUser"] as? [String: Any] else {
                    completion(.failure(NSError(domain: "UserNotFound", code: 404, userInfo: [NSLocalizedDescriptionKey: "User not found"])) )
                    return
                }
                let profileData = try JSONSerialization.data(withJSONObject: matchedUser, options: [])
                var profile = try JSONDecoder().decode(UserProfile.self, from: profileData)
                if profile.userCalendar == nil {
                    let calString = profile.submissionCalendar ?? "{}"
                    let (streak, totalDays) = self.parseSubmissionCalendar(calString)
                    profile.userCalendar = UserCalendar(streak: streak, totalActiveDays: totalDays, submissionCalendar: calString)
                }
                completion(.success(profile))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    func fetchDailyChallenge(completion: @escaping (Result<DailyChallenge, Error>) -> Void) {
        let query = """
query questionOfToday {
  activeDailyCodingChallengeQuestion {
    date
    link
    question {
      title
      titleSlug
      difficulty
      acRate
      topicTags {
        name
        slug
      }
    }
  }
}
"""
        let requestBody = ["query": query, "variables": [:]] as [String : Any]
        
        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // No per-problem headers here; those are set in fetchProblemDetail
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            #if DEBUG
            if let http = response as? HTTPURLResponse {
                print("[DailyChallenge] HTTP \(http.statusCode)")
            }
            #endif
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(NSError(domain: "No data", code: 0)))
                return
            }
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                #if DEBUG
                if let errors = json?["errors"] as? [[String: Any]] {
                    print("[DailyChallenge] GraphQL errors: \(errors)")
                }
                #endif
                let dataDict = json?["data"] as? [String: Any]
                let active = dataDict?["activeDailyCodingChallengeQuestion"] as? [String: Any]
                let challengeData = try JSONSerialization.data(withJSONObject: active ?? [:], options: [])
                let challenge = try JSONDecoder().decode(DailyChallenge.self, from: challengeData)
                completion(.success(challenge))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    func fetchProblems(limit: Int = 50, skip: Int = 0, filters: [String: Any] = [:], completion: @escaping (Result<[Problem], Error>) -> Void) {
        let query = """
query problemsetQuestionList($categorySlug: String, $limit: Int, $skip: Int, $filters: QuestionListFilterInput) {
  problemsetQuestionList: questionList(
    categorySlug: $categorySlug
    limit: $limit
    skip: $skip
    filters: $filters
  ) {
    questions: data {
      title
      titleSlug
      difficulty
      acRate
      topicTags { name slug }
    }
  }
}
"""
        let variables = ["categorySlug": "", "limit": limit, "skip": skip, "filters": filters] as [String : Any]
        let requestBody = ["query": query, "variables": variables] as [String : Any]
        
        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            #if DEBUG
            if let http = response as? HTTPURLResponse {
                print("[Problems] HTTP \(http.statusCode)")
            }
            #endif
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(NSError(domain: "No data", code: 0)))
                return
            }
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                #if DEBUG
                if let errors = json?["errors"] as? [[String: Any]] {
                    print("[Problems] GraphQL errors: \(errors)")
                }
                #endif
                let dataDict = json?["data"] as? [String: Any]
                let problemset = dataDict?["problemsetQuestionList"] as? [String: Any]
                let questions = problemset?["questions"] as? [[String: Any]]
                let problemsData = try JSONSerialization.data(withJSONObject: questions ?? [], options: [])
                let problems = try JSONDecoder().decode([Problem].self, from: problemsData)
                completion(.success(problems))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    func fetchUserSolvedProblems(username: String, completion: @escaping (Result<[String], Error>) -> Void) {
        let query = """
query {
  matchedUser(username: "\(username)") {
    solvedProblems {
      titleSlug
    }
  }
}
"""
        let requestBody = ["query": query, "variables": [:]] as [String : Any]
        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error { completion(.failure(error)); return }
            guard let data = data else { completion(.failure(NSError(domain: "No data", code: 0))); return }
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                let dataDict = json?["data"] as? [String: Any]
                let matched = dataDict?["matchedUser"] as? [String: Any]
                let list = matched?["solvedProblems"] as? [[String: Any]] ?? []
                let slugs = list.compactMap { $0["titleSlug"] as? String }
                completion(.success(slugs))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    func fetchProblemDetail(titleSlug: String, completion: @escaping (Result<ProblemDetail, Error>) -> Void) {
        let query = """
query questionData($titleSlug: String!) {
  question(titleSlug: $titleSlug) {
    title
    titleSlug
    difficulty
    content
    topicTags {
      name
      slug
    }
    exampleTestcases
    sampleTestCase
    hints
    similarQuestions
    codeSnippets {
      lang
      langSlug
      code
    }
  }
}
"""
        let variables = ["titleSlug": titleSlug]
        let requestBody = ["query": query, "variables": variables] as [String : Any]
        
        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            #if DEBUG
            if let http = response as? HTTPURLResponse {
                print("[ProblemDetail] HTTP \(http.statusCode)")
            }
            #endif
            
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "No data", code: 0)))
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                #if DEBUG
                if let errors = json?["errors"] as? [[String: Any]] {
                    print("[ProblemDetail] GraphQL errors: \(errors)")
                }
                #endif
                
                let dataDict = json?["data"] as? [String: Any]
                guard let question = dataDict?["question"] as? [String: Any] else {
                    completion(.failure(NSError(domain: "QuestionNotFound", code: 404, userInfo: [NSLocalizedDescriptionKey: "Question not found"])))
                    return
                }
                
                let questionData = try JSONSerialization.data(withJSONObject: question, options: [])
                let detail = try JSONDecoder().decode(ProblemDetail.self, from: questionData)
                
                #if DEBUG
                print("[ProblemDetail] Successfully fetched: \(detail.title)")
                if let content = detail.content {
                    print("[ProblemDetail] Content length: \(content.utf8.count)")
                }
                #endif
                
                completion(.success(detail))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    

    
    func fetchTagProblemCounts(username: String, completion: @escaping (Result<TagProblemCounts, Error>) -> Void) {
        let query = """
query {
  matchedUser(username: "\(username)") {
    tagProblemCounts {
      advanced {
        tagName
        problemsSolved
      }
      intermediate {
        tagName
        problemsSolved
      }
      fundamental {
        tagName
        problemsSolved
      }
    }
  }
}
"""
        let requestBody = ["query": query, "variables": [:]] as [String : Any]
        
        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(NSError(domain: "No data", code: 0)))
                return
            }
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                let dataDict = json?["data"] as? [String: Any]
                let matchedUser = dataDict?["matchedUser"] as? [String: Any]
                let tagCounts = matchedUser?["tagProblemCounts"] as? [String: Any]
                let tagData = try JSONSerialization.data(withJSONObject: tagCounts ?? [:], options: [])
                let tags = try JSONDecoder().decode(TagProblemCounts.self, from: tagData)
                completion(.success(tags))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    func fetchContests(completion: @escaping (Result<[Contest], Error>) -> Void) {
        let query = """
query {
  allContests {
    title
    titleSlug
    startTime
    duration
  }
}
"""
        let requestBody = ["query": query, "variables": [:]] as [String : Any]
        
        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(NSError(domain: "No data", code: 0)))
                return
            }
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                let dataDict = json?["data"] as? [String: Any]
                let allContests = dataDict?["allContests"] as? [[String: Any]]
                let contestsData = try JSONSerialization.data(withJSONObject: allContests ?? [], options: [])
                let contests = try JSONDecoder().decode([Contest].self, from: contestsData)
                completion(.success(contests))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    func fetchContestHistory(username: String, completion: @escaping (Result<ContestHistory, Error>) -> Void) {
        let query = """
query {
  userContestRanking(username: "\(username)") {
    rating
    globalRanking
    topPercentage
  }
  userContestRankingHistory(username: "\(username)") {
    attended
    rating
    ranking
    problemsSolved
    contest {
      title
      startTime
    }
  }
}
"""
        let requestBody = ["query": query, "variables": [:]] as [String : Any]
        
        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(NSError(domain: "No data", code: 0)))
                return
            }
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                let dataDict = json?["data"] as? [String: Any]
                let ranking = dataDict?["userContestRanking"] as? [String: Any] ?? [:]
                let history = dataDict?["userContestRankingHistory"] as? [[String: Any]] ?? []
                
                let historyData = try JSONSerialization.data(withJSONObject: history, options: [])
                let entries = try JSONDecoder().decode([ContestEntry].self, from: historyData)
                
                let contestHistory = ContestHistory(
                    rating: ranking["rating"] as? Double ?? 0.0,
                    globalRanking: ranking["globalRanking"] as? Int ?? 0,
                    topPercentage: ranking["topPercentage"] as? Double ?? 0.0,
                    history: entries
                )
                completion(.success(contestHistory))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    // MARK: - Fetch All Problems
    func fetchAllProblems(batchSize: Int = 100, progressCallback: ((Int, Int) -> Void)? = nil, completion: @escaping (Result<[Problem], Error>) -> Void) {
        var allProblems: [Problem] = []
        var currentSkip = 0
        let limit = batchSize
        
        func fetchBatch() {
            fetchProblems(limit: limit, skip: currentSkip) { result in
                switch result {
                case .success(let problems):
                    allProblems.append(contentsOf: problems)
                    
                    // Update progress
                    progressCallback?(allProblems.count, -1) // -1 means total unknown
                    
                    // If we got fewer problems than requested, we've reached the end
                    if problems.count < limit {
                        completion(.success(allProblems))
                        return
                    }
                    
                    // Continue fetching next batch
                    currentSkip += limit
                    fetchBatch()
                    
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
        
        fetchBatch()
    }
    
    // MARK: - Get Total Problem Count
    func getTotalProblemCount(completion: @escaping (Result<Int, Error>) -> Void) {
        let query = """
query {
  problemsetQuestionList: questionList(
    categorySlug: ""
    limit: 1
    skip: 0
    filters: {}
  ) {
    total
  }
}
"""
        let variables = ["categorySlug": "", "limit": 1, "skip": 0, "filters": [:]] as [String : Any]
        let requestBody = ["query": query, "variables": variables] as [String : Any]
        
        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(NSError(domain: "No data", code: 0)))
                return
            }
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                let dataDict = json?["data"] as? [String: Any]
                let problemset = dataDict?["problemsetQuestionList"] as? [String: Any]
                let total = problemset?["total"] as? Int ?? 0
                completion(.success(total))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    // MARK: - Helper Functions
    private func parseSubmissionCalendar(_ calendarString: String) -> (streak: Int, totalDays: Int) {
        guard let data = calendarString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Int] else {
            return (0, 0)
        }
        
        let totalDays = json.values.filter { $0 > 0 }.count
        
        // Calculate current streak
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var currentStreak = 0
        var checkDate = today
        
        // Check if there's a submission today or yesterday (to handle timezone differences)
        let todayTimestamp = Int(today.timeIntervalSince1970)
        let yesterdayTimestamp = Int(calendar.date(byAdding: .day, value: -1, to: today)!.timeIntervalSince1970)
        
        let hasSubmissionToday = json[String(todayTimestamp)] != nil && json[String(todayTimestamp)]! > 0
        let hasSubmissionYesterday = json[String(yesterdayTimestamp)] != nil && json[String(yesterdayTimestamp)]! > 0
        
        // Start from yesterday if no submission today, otherwise start from today
        if hasSubmissionToday {
            checkDate = today
        } else if hasSubmissionYesterday {
            checkDate = calendar.date(byAdding: .day, value: -1, to: today)!
        } else {
            return (0, totalDays) // No recent submissions, streak is 0
        }
        
        // Count consecutive days backwards
        while true {
            let timestamp = String(Int(checkDate.timeIntervalSince1970))
            if let submissions = json[timestamp], submissions > 0 {
                currentStreak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else {
                break
            }
        }
        
        return (currentStreak, totalDays)
    }
}
