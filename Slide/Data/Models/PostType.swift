//
//  PostType.swift
//  Slide
//
//  Created by Nick Rogers on 8/26/25.
//


import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine
import SwiftUI

// MARK: - Post Data Models

enum PostType: String, CaseIterable, Codable {
    case announcement = "announcement"
    case promotion = "promotion"
    case event = "event"
    case update = "update"
    case news = "news"
    
    var displayName: String {
        switch self {
        case .announcement: return "Announcement"
        case .promotion: return "Promotion"
        case .event: return "Event"
        case .update: return "Update"
        case .news: return "News"
        }
    }
    
    var color: Color {
        switch self {
        case .announcement: return Color.red
        case .promotion: return .yellow
        case .event: return Color.blue
        case .update: return Color.orange
        case .news: return Color.teal
        }
    }
    
    var icon: String {
        switch self {
        case .announcement: return "megaphone"
        case .promotion: return "bubble"
        case .event: return "calendar"
        case .update: return "info.circle.fill"
        case .news: return "newspaper"
        }
    }
}

enum PostStatus: String, Codable {
    case draft = "draft"
    case published = "published"
    case archived = "archived"
    case scheduled = "scheduled"
}

struct BusinessPost: Identifiable, Codable {
    var id: String? = UUID().uuidString
    let businessId: String
    let authorId: String
    var title: String
    var content: String
    var postType: PostType
    var status: PostStatus
    var tags: [String]
    var mediaUrls: [String]
    var scheduledDate: Date?
    var publishDate: Date?
    var expirationDate: Date?
    var engagement: PostEngagement
    var metadata: PostMetadata
    var createdAt: Timestamp
    var updatedAt: Timestamp
    
    init(businessId: String, authorId: String, title: String, content: String, type: PostType) {
        self.businessId = businessId
        self.authorId = authorId
        self.title = title
        self.content = content
        self.postType = type
        self.status = .draft
        self.tags = []
        self.mediaUrls = []
        self.engagement = PostEngagement()
        self.metadata = PostMetadata()
        self.createdAt = Timestamp()
        self.updatedAt = Timestamp()
    }
    
    public init(
        id: String,
        businessId: String,
        authorId: String,
        title: String,
        content: String,
        postType: PostType,
        status: PostStatus,
        tags: [String],
        mediaUrls: [String],
        scheduledDate: Date? = nil,
        publishDate: Date? = nil,
        expirationDate: Date? = nil,
        engagement: PostEngagement = PostEngagement(),
        metadata: PostMetadata = PostMetadata(),
        createdAt: Timestamp,
        updatedAt: Timestamp
    ) {
        self.id = id
        self.businessId = businessId
        self.authorId = authorId
        self.title = title
        self.content = content
        self.postType = postType
        self.status = status
        self.tags = tags
        self.mediaUrls = mediaUrls
        self.scheduledDate = scheduledDate
        self.publishDate = publishDate
        self.expirationDate = expirationDate
        self.engagement = engagement
        self.metadata = metadata
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

struct PostEngagement: Codable {
    var views: Int = 0
    var likes: Int = 0
    var shares: Int = 0
    var comments: Int = 0
    var clicks: Int = 0
}

struct PostMetadata: Codable {
    var priority: Int = 0
    var featured: Bool = false
    var allowComments: Bool = true
    var notifyFollowers: Bool = true
    var categories: [String] = []
    var targetAudience: [String] = []
}

// MARK: - Repository Pattern

protocol BusinessPostRepository {
    func createPost(_ post: BusinessPost) async throws -> String
    func updatePost(_ post: BusinessPost) async throws
    func deletePost(id: String) async throws
    func getPost(id: String) async throws -> BusinessPost?
    func getPostsForBusiness(businessId: String, limit: Int?) async throws -> [BusinessPost]
    func getPostsByStatus(_ status: PostStatus, businessId: String) async throws -> [BusinessPost]
    func searchPosts(query: String, businessId: String) async throws -> [BusinessPost]
}

class FirebaseBusinessPostRepository: BusinessPostRepository {
    private let db = Firestore.firestore()
    private let collection = "business_posts"
    
    func createPost(_ post: BusinessPost) async throws -> String {
        var newPost = post
        newPost.createdAt = Timestamp()
        newPost.updatedAt = Timestamp()
        
        let docRef = try db.collection(collection).addDocument(from: newPost)
        return docRef.documentID
    }
    
    func updatePost(_ post: BusinessPost) async throws {
        guard let id = post.id else {
            throw PostError.invalidPostId
        }
        
        var updatedPost = post
        updatedPost.updatedAt = Timestamp()
        
        try db.collection(collection).document(id).setData(from: updatedPost)
    }
    
    func deletePost(id: String) async throws {
        try await db.collection(collection).document(id).delete()
    }
    
    func getPost(id: String) async throws -> BusinessPost? {
        let document = try await db.collection(collection).document(id).getDocument()
        return try document.data(as: BusinessPost.self)
    }
    
    func getPostsForBusiness(businessId: String, limit: Int? = nil) async throws -> [BusinessPost] {
        var query: Query = db.collection(collection)
            .whereField("businessId", isEqualTo: businessId)
            .order(by: "createdAt", descending: true)
        
        if let limit = limit {
            query = query.limit(to: limit)
        }
        
        let snapshot = try await query.getDocuments()
        return try snapshot.documents.compactMap { try $0.data(as: BusinessPost.self) }
    }
    
    func getPostsByStatus(_ status: PostStatus, businessId: String) async throws -> [BusinessPost] {
        let query = db.collection(collection)
            .whereField("businessId", isEqualTo: businessId)
            .whereField("status", isEqualTo: status.rawValue)
            .order(by: "createdAt", descending: true)
        
        let snapshot = try await query.getDocuments()
        return try snapshot.documents.compactMap { try $0.data(as: BusinessPost.self) }
    }
    
    func searchPosts(query: String, businessId: String) async throws -> [BusinessPost] {
        // Note: Firestore doesn't support full-text search natively
        // Consider using Algolia or implement tags-based search
        let firestoreQuery = db.collection(collection)
            .whereField("businessId", isEqualTo: businessId)
            .whereField("tags", arrayContains: query.lowercased())
        
        let snapshot = try await firestoreQuery.getDocuments()
        return try snapshot.documents.compactMap { try $0.data(as: BusinessPost.self) }
    }
}

// MARK: - Service Layer

protocol BusinessPostService {
    func createPost(for business: SlideBusiness, title: String, content: String, type: PostType) async throws -> String
    func updatePost(_ post: BusinessPost) async throws
    func publishPost(id: String) async throws
    func schedulePost(id: String, for date: Date) async throws
    func archivePost(id: String) async throws
    func deletePost(id: String) async throws
    func getBusinessPosts(businessId: String) async throws -> [BusinessPost]
    func getDraftPosts(businessId: String) async throws -> [BusinessPost]
    func getScheduledPosts(businessId: String) async throws -> [BusinessPost]
}

class DefaultBusinessPostService: BusinessPostService {
    private let repository: BusinessPostRepository
    private let authService: AuthenticationService
    private let notificationService: PostNotificationService
    
    init(repository: BusinessPostRepository = FirebaseBusinessPostRepository(),
         authService: AuthenticationService = DefaultAuthenticationService(),
         notificationService: PostNotificationService = DefaultPostNotificationService()) {
        self.repository = repository
        self.authService = authService
        self.notificationService = notificationService
    }
    
    func createPost(for business: SlideBusiness, title: String, content: String, type: PostType) async throws -> String {
        guard let currentUser = authService.currentUser,
              let businessId = business.id else {
            throw PostError.unauthorized
        }
        
        // Validate user has permission to post for this business
        try await validateBusinessPermission(userId: currentUser.uid, businessId: businessId)
        
        let post = BusinessPost(
            businessId: businessId,
            authorId: currentUser.uid,
            title: title,
            content: content,
            type: type
        )
        
        return try await repository.createPost(post)
    }
    
    func updatePost(_ post: BusinessPost) async throws {
        guard let currentUser = authService.currentUser else {
            throw PostError.unauthorized
        }
        
        // Validate user owns this post or has business admin rights
        try await validatePostPermission(userId: currentUser.uid, post: post)
        
        try await repository.updatePost(post)
    }
    
    func publishPost(id: String) async throws {
        guard var post = try await repository.getPost(id: id) else {
            throw PostError.postNotFound
        }
        
        post.status = .published
        post.publishDate = Date()
        
        try await repository.updatePost(post)
        
        // Send notifications if enabled
        if post.metadata.notifyFollowers {
            await notificationService.notifyBusinessFollowers(businessId: post.businessId, post: post)
        }
    }
    
    func schedulePost(id: String, for date: Date) async throws {
        guard var post = try await repository.getPost(id: id) else {
            throw PostError.postNotFound
        }
        
        post.status = .scheduled
        post.scheduledDate = date
        
        try await repository.updatePost(post)
        
        // Schedule notification
        await notificationService.schedulePostNotification(post: post, date: date)
    }
    
    func archivePost(id: String) async throws {
        guard var post = try await repository.getPost(id: id) else {
            throw PostError.postNotFound
        }
        
        post.status = .archived
        try await repository.updatePost(post)
    }
    
    func deletePost(id: String) async throws {
        try await repository.deletePost(id: id)
    }
    
    func getBusinessPosts(businessId: String) async throws -> [BusinessPost] {
        return try await repository.getPostsForBusiness(businessId: businessId, limit: nil)
    }
    
    func getDraftPosts(businessId: String) async throws -> [BusinessPost] {
        return try await repository.getPostsByStatus(.draft, businessId: businessId)
    }
    
    func getScheduledPosts(businessId: String) async throws -> [BusinessPost] {
        return try await repository.getPostsByStatus(.scheduled, businessId: businessId)
    }
    
    // MARK: - Private Methods
    
    private func validateBusinessPermission(userId: String, businessId: String) async throws {
        // Implement business permission logic
        // This could check if user is owner/admin of the business
    }
    
    private func validatePostPermission(userId: String, post: BusinessPost) async throws {
        // Check if user is post author or business admin
        if post.authorId != userId {
            try await validateBusinessPermission(userId: userId, businessId: post.businessId)
        }
    }
}

// MARK: - View Model

@MainActor
class BusinessPostViewModel: ObservableObject {
    @Published var posts: [BusinessPost] = []
    @Published var draftPosts: [BusinessPost] = []
    @Published var scheduledPosts: [BusinessPost] = []
    @Published var isLoading = false
    @Published var error: PostError?
    
    private let postService: BusinessPostService
    private var cancellables = Set<AnyCancellable>()
    
    init(postService: BusinessPostService = DefaultBusinessPostService()) {
        self.postService = postService
    }
    
    func loadPosts(for businessId: String) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            posts = try await postService.getBusinessPosts(businessId: businessId)
            draftPosts = try await postService.getDraftPosts(businessId: businessId)
            scheduledPosts = try await postService.getScheduledPosts(businessId: businessId)
            print ("Loaded posts: \(posts.count)")
        } catch {
            self.error = error as? PostError ?? .unknown
            print("THERE WAS AN ERROR FETCHING POSTS - : \(error.localizedDescription)")
        }
    }
    
    func createPost(for business: SlideBusiness, title: String, content: String, type: PostType) async {
        do {
            _ = try await postService.createPost(for: business, title: title, content: content, type: type)
            if let businessId = business.id {
                await loadPosts(for: businessId)
            }
        } catch {
            self.error = error as? PostError ?? .unknown
        }
    }
    
    func publishPost(_ post: BusinessPost) async {
        guard let id = post.id else { return }
        
        do {
            try await postService.publishPost(id: id)
            await loadPosts(for: post.businessId)
        } catch {
            self.error = error as? PostError ?? .unknown
        }
    }
    
    func schedulePost(_ post: BusinessPost, for date: Date) async {
        guard let id = post.id else { return }
        
        do {
            try await postService.schedulePost(id: id, for: date)
            await loadPosts(for: post.businessId)
        } catch {
            self.error = error as? PostError ?? .unknown
        }
    }
    
    func deletePost(_ post: BusinessPost) async {
        guard let id = post.id else { return }
        
        do {
            try await postService.deletePost(id: id)
            await loadPosts(for: post.businessId)
        } catch {
            self.error = error as? PostError ?? .unknown
        }
    }
}

// MARK: - Error Handling

enum PostError: LocalizedError {
    case unauthorized
    case invalidPostId
    case postNotFound
    case networkError
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "You don't have permission to perform this action"
        case .invalidPostId:
            return "Invalid post ID"
        case .postNotFound:
            return "Post not found"
        case .networkError:
            return "Network error occurred"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}

// MARK: - Supporting Services (Interfaces)

protocol AuthenticationService {
    var currentUser: User? { get }
}

class DefaultAuthenticationService: AuthenticationService {
    var currentUser: User? {
        return Auth.auth().currentUser
    }
}

protocol PostNotificationService {
    func notifyBusinessFollowers(businessId: String, post: BusinessPost) async
    func schedulePostNotification(post: BusinessPost, date: Date) async
}

class DefaultPostNotificationService: PostNotificationService {
    func notifyBusinessFollowers(businessId: String, post: BusinessPost) async {
        // Implement push notification logic
    }
    
    func schedulePostNotification(post: BusinessPost, date: Date) async {
        // Implement scheduled notification logic
    }
}

// MARK: - Extensions for Future Features

extension BusinessPost {
    // Analytics support
    var analyticsData: [String: Any] {
        return [
            "type": postType.rawValue,
            "engagement_score": engagement.views + engagement.likes + engagement.shares,
            "has_media": !mediaUrls.isEmpty,
            "tag_count": tags.count
        ]
    }
    
    // SEO optimization
    var seoTitle: String {
        return title.count > 60 ? String(title.prefix(57)) + "..." : title
    }
    
    var seoDescription: String {
        let cleanContent = content.replacingOccurrences(of: "\n", with: " ")
        return cleanContent.count > 160 ? String(cleanContent.prefix(157)) + "..." : cleanContent
    }
}

// MARK: - Cache Manager for Performance

class PostCacheManager {
    private let cache = NSCache<NSString, NSArray>()
    private let cacheTimeout: TimeInterval = 300 // 5 minutes
    private var cacheTimestamps: [String: Date] = [:]
    
    func getCachedPosts(for businessId: String) -> [BusinessPost]? {
        guard let timestamp = cacheTimestamps[businessId],
              Date().timeIntervalSince(timestamp) < cacheTimeout,
              let cachedArray = cache.object(forKey: businessId as NSString) as? [BusinessPost] else {
            return nil
        }
        return cachedArray
    }
    
    func cachePosts(_ posts: [BusinessPost], for businessId: String) {
        cache.setObject(posts as NSArray, forKey: businessId as NSString)
        cacheTimestamps[businessId] = Date()
    }
    
    func clearCache(for businessId: String) {
        cache.removeObject(forKey: businessId as NSString)
        cacheTimestamps.removeValue(forKey: businessId)
    }
}
