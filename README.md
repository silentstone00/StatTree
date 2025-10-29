# LeetCode iOS App

A comprehensive iOS app for browsing and tracking LeetCode problems, built with SwiftUI.

## Features

### ✅ Current Features
- **User Profile**: View user statistics, ranking, and submission calendar
- **Daily Challenge**: Get today's LeetCode challenge
- **Problem Browser**: Browse problems with search and filtering
- **Problem Details**: View full problem descriptions with HTML rendering
- **Progress Tracking**: Track solved problems and bookmarks
- **Contest History**: View contest participation and ratings

### 🚀 Smart Problem Loading
The app now features intelligent problem loading with lazy pagination and instant search!

#### How it works:
1. **Lazy Loading**: Loads 50 problems initially, then loads more as you scroll
2. **Infinite Scroll**: Automatically fetches next batch when you reach the bottom
3. **Smart Search**: Debounced search with instant filtering
4. **Quick Filters**: Easy difficulty and tag filtering with visual chips
5. **Pull to Refresh**: Refresh the list by pulling down

#### Key Features:
- **Fast Initial Load**: Shows problems in ~1 second instead of waiting for all 3000+
- **Smooth Scrolling**: Loads more content seamlessly as you browse
- **Search as You Type**: Real-time search with 0.5s debounce
- **Visual Indicators**: Shows loading state, solved status, and bookmarks
- **Swipe Actions**: Bookmark/unbookmark problems with swipe gestures

## API Capabilities

### Supported Endpoints
- ✅ User profile and statistics
- ✅ Daily coding challenge
- ✅ Problem list with pagination and filters
- ✅ **All problems** (new feature)
- ✅ Problem details with full content
- ✅ User solved problems
- ✅ Contest information and history
- ✅ Tag-based problem counts

### Technical Details
- **Base URL**: `https://leetcode.com/graphql`
- **Method**: GraphQL queries via POST
- **Pagination**: Supports limit/skip parameters
- **Filtering**: By difficulty, tags, and search keywords
- **Rate Limiting**: Handles API limits gracefully

## Implementation

### Key Components
- `LeetCodeAPI`: Main API client with GraphQL integration
- `ProblemsViewModel`: Manages problem data and state
- `ProblemsView`: SwiftUI interface with progress tracking
- `Model`: Data structures for all LeetCode entities

### New Methods Added
```swift
// Smart pagination with lazy loading
func fetchProblems(difficulty: String? = nil, tag: String? = nil, reset: Bool = true)

// Load more problems for infinite scroll
func loadMoreProblems()

// Search with debouncing
func searchProblems()

// Filter by difficulty/tags
func filterByDifficulty(_ difficulty: String?)
func filterByTag(_ tag: String?)

// Check if should load more (for infinite scroll)
func shouldLoadMore(for problem: Problem) -> Bool
```

## Performance Improvements

**Problem solved: No more waiting for 3000+ problems to load!**

### Before:
- ❌ 30+ seconds to load all problems
- ❌ Poor user experience
- ❌ Memory intensive
- ❌ Network heavy

### After:
- ✅ **~1 second** initial load (50 problems)
- ✅ **Infinite scroll** - loads more as needed
- ✅ **Smart search** - instant filtering
- ✅ **Memory efficient** - only loads what's visible
- ✅ **Network optimized** - paginated requests

The app now loads **50 problems initially** and fetches more as you scroll, providing a much better user experience while still giving access to all 3000+ problems when needed.
