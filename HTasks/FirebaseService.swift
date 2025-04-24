import Foundation
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import FirebaseFirestoreSwift

class FirebaseService: ObservableObject {
    static let shared = FirebaseService()
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var userPrompts: Int = 15
    @Published var lastPromptReset: Date?
    
    private init() {
        setupFirebase()
        setupAuthStateListener()
    }
    
    private func setupFirebase() {
        // Firebase is configured in HTasksApp.swift
    }
    
    private func setupAuthStateListener() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.isAuthenticated = user != nil
                self?.currentUser = user
                if let user = user {
                    self?.loadUserPromptData(userId: user.uid)
                }
            }
        }
    }
    
    // MARK: - Authentication
    
    func signIn(email: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            completion(.success(()))
        }
    }
    
    func signUp(email: String, password: String, username: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let userId = result?.user.uid else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get user ID"])))
                return
            }
            
            self?.createUserDocument(userId: userId, data: [
                "username": username,
                "email": email,
                "settings": UserSettings.defaultSettings,
                "promptsRemaining": 15,
                "lastPromptReset": Date(),
                "createdAt": Date()
            ])
            
            completion(.success(()))
        }
    }
    
    func signOut() {
        try? Auth.auth().signOut()
    }
    
    // MARK: - User Profile
    
    func updateUserFCMToken(token: String) {
        guard let userId = currentUser?.uid else {
            print("Cannot update FCM token: User not authenticated")
            return
        }
        
        let userRef = db.collection("users").document(userId)
        
        print("Updating FCM token for user \(userId): \(token)")
        // Use FieldValue.arrayUnion to add the token without duplicates
        // Store tokens in an array to support multiple devices per user
        userRef.updateData(["fcmTokens": FieldValue.arrayUnion([token])]) { error in
            if let error = error {
                // If the field doesn't exist yet, set it initially
                if (error as NSError).code == 5 /* NOT_FOUND */ {
                    print("fcmTokens field not found, creating it.")
                    userRef.setData(["fcmTokens": [token]], merge: true) { setError in
                        if let setError = setError {
                            print("Error setting initial FCM token: \(setError.localizedDescription)")
                        }
                    }
                } else {
                    print("Error updating FCM token: \(error.localizedDescription)")
                }
            } else {
                print("Successfully updated FCM token.")
            }
        }
    }
    
    // MARK: - User Data Management
    
    func createUserDocument(userId: String, data: [String: Any]) {
        db.collection("users").document(userId).setData(data) { error in
            if let error = error {
                print("Error creating user document: \(error.localizedDescription)")
            }
        }
    }
    
    func fetchUserTasks(userId: String, completion: @escaping (Result<[HTTask], Error>) -> Void) {
        db.collection("users").document(userId).collection("tasks").getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            let tasks = snapshot?.documents.compactMap { document -> HTTask? in
                try? document.data(as: HTTask.self)
            } ?? []
            
            completion(.success(tasks))
        }
    }
    
    func saveTask(_ task: HTTask, userId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            try db.collection("users").document(userId).collection("tasks").document(task.id.uuidString).setData(from: task)
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }
    
    func deleteTask(_ task: HTTask, userId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection("users").document(userId).collection("tasks").document(task.id.uuidString).delete { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func fetchUserSettings(userId: String, completion: @escaping (Result<UserSettings, Error>) -> Void) {
        db.collection("users").document(userId).getDocument { document, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = document?.data()?["settings"] as? [String: Any],
                  let settings = try? UserSettings.from(dictionary: data) else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to decode settings"])))
                return
            }
            
            completion(.success(settings))
        }
    }
    
    func saveUserSettings(_ settings: UserSettings, userId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection("users").document(userId).updateData([
            "settings": settings.toDictionary()
        ]) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    // MARK: - AI Prompts Management
    
    private func loadUserPromptData(userId: String) {
        db.collection("users").document(userId).getDocument { [weak self] document, error in
            guard let document = document,
                  let promptsRemaining = document.data()?["promptsRemaining"] as? Int,
                  let lastResetTimestamp = document.data()?["lastPromptReset"] as? Timestamp else {
                return
            }
            
            let lastReset = lastResetTimestamp.dateValue()
            if !Calendar.current.isDate(lastReset, inSameDayAs: Date()) {
                // Reset prompts if it's a new day
                self?.resetDailyPrompts(userId: userId)
            } else {
                self?.userPrompts = promptsRemaining
                self?.lastPromptReset = lastReset
            }
        }
    }
    
    func usePrompt(userId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard userPrompts > 0 else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No prompts remaining"])))
            return
        }
        
        db.collection("users").document(userId).updateData([
            "promptsRemaining": FieldValue.increment(Int64(-1))
        ]) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                self.userPrompts -= 1
                completion(.success(()))
            }
        }
    }
    
    private func resetDailyPrompts(userId: String) {
        let data: [String: Any] = [
            "promptsRemaining": 15,
            "lastPromptReset": Date()
        ]
        
        db.collection("users").document(userId).updateData(data) { [weak self] error in
            if error == nil {
                self?.userPrompts = 15
                self?.lastPromptReset = Date()
            }
        }
    }
    
    // MARK: - Posts
    
    func createPost(content: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let userId = currentUser?.uid else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
            return
        }
        
        let postData: [String: Any] = [
            "content": content,
            "authorId": userId,
            "createdAt": FieldValue.serverTimestamp(),
            "likes": 0,
            "comments": 0
        ]
        
        db.collection("posts").addDocument(data: postData) { error in
            if let error = error {
                completion(.failure(error))
                return
            }
            completion(.success(()))
        }
    }
    
    func fetchPosts(completion: @escaping (Result<[Post], Error>) -> Void) {
        db.collection("posts")
            .order(by: "createdAt", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }
                
                var posts: [Post] = []
                let group = DispatchGroup()
                
                for document in documents {
                    group.enter()
                    let data = document.data()
                    
                    // Fetch author information
                    if let authorId = data["authorId"] as? String {
                        self.db.collection("users").document(authorId).getDocument { userSnapshot, error in
                            if let userData = userSnapshot?.data(),
                               let username = userData["username"] as? String {
                                let post = Post(
                                    id: document.documentID,
                                    content: data["content"] as? String ?? "",
                                    author: username,
                                    timestamp: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                                    likes: data["likes"] as? Int ?? 0,
                                    comments: data["comments"] as? Int ?? 0
                                )
                                posts.append(post)
                            }
                            group.leave()
                        }
                    } else {
                        group.leave()
                    }
                }
                
                group.notify(queue: .main) {
                    completion(.success(posts))
                }
            }
    }
    
    func likePost(postId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let userId = currentUser?.uid else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
            return
        }
        
        let postRef = db.collection("posts").document(postId)
        let likeRef = db.collection("likes").document("\(postId)_\(userId)")
        
        db.runTransaction { transaction, errorPointer in
            let postDocument: DocumentSnapshot
            do {
                try postDocument = transaction.getDocument(postRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }
            
            guard let oldLikes = postDocument.data()?["likes"] as? Int else {
                let error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Post data not found"])
                errorPointer?.pointee = error
                return nil
            }
            
            transaction.updateData(["likes": oldLikes + 1], forDocument: postRef)
            transaction.setData(["userId": userId, "postId": postId, "createdAt": FieldValue.serverTimestamp()], forDocument: likeRef)
            
            return nil
        } completion: { _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            completion(.success(()))
        }
    }
    
    // MARK: - Comments
    
    func createComment(postId: String, content: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let userId = currentUser?.uid else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
            return
        }
        
        let batch = db.batch()
        
        // Create the comment document
        let commentRef = db.collection("comments").document()
        let commentData: [String: Any] = [
            "postId": postId,
            "content": content,
            "authorId": userId,
            "createdAt": FieldValue.serverTimestamp()
        ]
        batch.setData(commentData, forDocument: commentRef)
        
        // Update the post's comment count
        let postRef = db.collection("posts").document(postId)
        batch.updateData(["comments": FieldValue.increment(Int64(1))], forDocument: postRef)
        
        // Commit the batch
        batch.commit { error in
            if let error = error {
                completion(.failure(error))
                return
            }
            completion(.success(()))
        }
    }
    
    func fetchComments(for postId: String, completion: @escaping (Result<[Comment], Error>) -> Void) {
        db.collection("comments")
            .whereField("postId", isEqualTo: postId)
            .order(by: "createdAt", descending: false)
            .getDocuments { [weak self] snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }
                
                var comments: [Comment] = []
                let group = DispatchGroup()
                
                for document in documents {
                    group.enter()
                    let data = document.data()
                    
                    if let authorId = data["authorId"] as? String {
                        self?.db.collection("users").document(authorId).getDocument { userSnapshot, error in
                            defer { group.leave() }
                            
                            if let userData = userSnapshot?.data(),
                               let username = userData["username"] as? String {
                                let comment = Comment(
                                    id: document.documentID,
                                    postId: data["postId"] as? String ?? "",
                                    content: data["content"] as? String ?? "",
                                    author: username,
                                    timestamp: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                                )
                                comments.append(comment)
                            }
                        }
                    } else {
                        group.leave()
                    }
                }
                
                group.notify(queue: .main) {
                    completion(.success(comments.sorted { $0.timestamp < $1.timestamp }))
                }
            }
    }
}

// MARK: - Models

struct Post: Identifiable {
    let id: String
    let content: String
    let author: String
    let timestamp: Date
    let likes: Int
    let comments: Int
}

struct Comment: Identifiable {
    let id: String
    let postId: String
    let content: String
    let author: String
    let timestamp: Date
}

// Helper extension for UserSettings
extension UserSettings {
    func toDictionary() -> [String: Any] {
        [
            "name": name,
            "streak": streak,
            "totalTasksCompleted": totalTasksCompleted,
            "lastLoginDate": lastLoginDate,
            "notificationsEnabled": notificationsEnabled,
            "theme": theme,
            "taskCategories": taskCategories.map { $0.rawValue },
            "showDeleteConfirmation": showDeleteConfirmation,
            "deleteConfirmationText": deleteConfirmationText,
            "showSocialFeatures": showSocialFeatures
        ]
    }
    
    static func from(dictionary: [String: Any]) throws -> UserSettings {
        guard let name = dictionary["name"] as? String,
              let streak = dictionary["streak"] as? Int,
              let totalTasksCompleted = dictionary["totalTasksCompleted"] as? Int,
              let lastLoginDate = dictionary["lastLoginDate"] as? Date,
              let notificationsEnabled = dictionary["notificationsEnabled"] as? Bool,
              let theme = dictionary["theme"] as? String,
              let categoryStrings = dictionary["taskCategories"] as? [String],
              let showDeleteConfirmation = dictionary["showDeleteConfirmation"] as? Bool,
              let deleteConfirmationText = dictionary["deleteConfirmationText"] as? String,
              let showSocialFeatures = dictionary["showSocialFeatures"] as? Bool else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid dictionary format"])
        }
        
        let categories = categoryStrings.compactMap { TaskCategory(rawValue: $0) }
        
        return UserSettings(
            name: name,
            streak: streak,
            totalTasksCompleted: totalTasksCompleted,
            lastLoginDate: lastLoginDate,
            notificationsEnabled: notificationsEnabled,
            theme: theme,
            taskCategories: categories,
            showDeleteConfirmation: showDeleteConfirmation,
            deleteConfirmationText: deleteConfirmationText,
            stats: TaskStats(),
            showSocialFeatures: showSocialFeatures
        )
    }
} 
