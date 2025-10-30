// Models.swift
import Foundation

struct UserProfile: Codable {
    let username: String
    let profile: Profile?
    let submitStats: SubmitStats?
    let badges: [Badge]?
    let contestBadge: ContestBadge?
    let activeBadge: Badge?
    let submissionCalendar: String?
    var userCalendar: UserCalendar?
}

struct Profile: Codable {
    let ranking: Int?
    let userAvatar: String?
    let realName: String?
    let aboutMe: String?
    let school: String?
    let countryName: String?
}

struct SubmitStats: Codable {
    let acSubmissionNum: [SubmissionCount]?
}

struct SubmissionCount: Codable {
    let difficulty: String?
    let count: Int?
}

struct Badge: Codable {
    let id: String?
    let name: String?
    let displayName: String?
    let icon: String?
    let creationDate: Int?
}

struct ContestBadge: Codable {
    let name: String?
    let hoverText: String?
    let expired: Bool?
}

struct UserCalendar: Codable {
    let streak: Int
    let totalActiveDays: Int
    let submissionCalendar: String
}

struct DailyChallenge: Codable {
    let date: String
    let link: String
    let question: Problem
}

struct Problem: Codable, Identifiable, Hashable {
    let id = UUID()
    let title: String
    let titleSlug: String
    let difficulty: String
    let acRate: Double
    let topicTags: [TopicTag]
    
    enum CodingKeys: String, CodingKey {
        case title, titleSlug, difficulty, acRate, topicTags
    }
}

struct TopicTag: Codable, Hashable {
    let name: String
    let slug: String
}

struct Contest: Codable, Identifiable {
    var id: String { titleSlug }   // use titleSlug as unique ID
    let title: String
    let titleSlug: String
    let startTime: Int
    let duration: Int
}
struct ContestHistory: Codable {
    let rating: Double
    let globalRanking: Int
    let topPercentage: Double
    let history: [ContestEntry]
}

struct ContestEntry: Codable, Identifiable {
    var id: String { contest.title }   // contest title is unique enough for history
    let attended: Bool
    let rating: Double
    let ranking: Int
    let problemsSolved: Int
    let contest: ContestInfo
}
struct ContestInfo: Codable, Identifiable {
    var id: String { title }
    let title: String
    let startTime: Int
}
struct TagProblemCounts: Codable {
    let advanced: [TagCount]
    let intermediate: [TagCount]
    let fundamental: [TagCount]
}

struct TagCount: Codable {
    let tagName: String
    let problemsSolved: Int
}

struct ProblemDetail: Codable {
    let title: String
    let titleSlug: String
    let difficulty: String?
    let content: String?
    let topicTags: [TopicTag]?
    let exampleTestcases: String?
    let sampleTestCase: String?
    let hints: [String]?
    let similarQuestions: String?
    let codeSnippets: [CodeSnippet]?
}

struct CodeSnippet: Codable {
    let lang: String
    let langSlug: String
    let code: String
}
