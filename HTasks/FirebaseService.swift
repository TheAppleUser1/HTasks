import Foundation
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import FirebaseGoogleAuthUI
import GoogleSignIn

class FirebaseService: ObservableObject {
    static let shared = FirebaseService()
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    
    private init() {
        setupFirebase()
    }
    
    private func setupFirebase() {
        // Firebase is configured in HTasksApp.swift
    }
    
    // MARK: - Authentication
    
    func signIn(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let user = result?.user {
                self?.currentUser = user
                self?.isAuthenticated = true
                completion(.success(user))
            }
        }
    }
    
    func signUp(email: String, password: String, username: String, completion: @escaping (Result<User, Error>) -> Void) {
        print("Attempting to sign up user with email: \(email)")
        
        // Validate input
        guard !email.isEmpty, !password.isEmpty, !username.isEmpty else {
            let error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "All fields are required"])
            print("Sign up error: Empty fields")
            completion(.failure(error))
            return
        }
        
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                print("Firebase Auth error (raw): \(error)")
                print("Firebase Auth error (localized): \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let user = result?.user else {
                let error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create user"])
                print("Sign up error: No user returned")
                completion(.failure(error))
                return
            }
            
            // Create user profile in Firestore
            let userData: [String: Any] = [
                "username": username,
                "email": email,
                "createdAt": FieldValue.serverTimestamp()
            ]
            
            print("Creating user profile in Firestore for user: \(user.uid)")
            self?.db.collection("users").document(user.uid).setData(userData) { error in
                if let error = error {
                    print("Firestore error: \(error.localizedDescription)")
                    // Try to delete the auth user if Firestore creation fails
                    user.delete { error in
                        if let error = error {
                            print("Failed to delete auth user after Firestore error: \(error.localizedDescription)")
                        }
                    }
                    completion(.failure(error))
                    return
                }
                
                print("Successfully created user profile")
                self?.currentUser = user
                self?.isAuthenticated = true
                completion(.success(user))
            }
        }
    }
    
    func signOut() throws {
        try Auth.auth().signOut()
        currentUser = nil
        isAuthenticated = false
    }
    
    func signInWithGoogle(presenting: UIViewController, completion: @escaping (Result<User, Error>) -> Void) {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Firebase configuration error"])))
            return
        }
        
        // Create Google Sign In configuration object
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        // Start the sign in flow
        GIDSignIn.sharedInstance.signIn(withPresenting: presenting) { [weak self] result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get ID token"])))
                return
            }
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                         accessToken: user.accessToken.tokenString)
            
            // Sign in with Firebase
            Auth.auth().signIn(with: credential) { [weak self] result, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                if let firebaseUser = result?.user {
                    // Create or update user profile in Firestore
                    let userData: [String: Any] = [
                        "username": user.profile?.name ?? "User",
                        "email": user.profile?.email ?? "",
                        "createdAt": FieldValue.serverTimestamp(),
                        "lastLoginAt": FieldValue.serverTimestamp()
                    ]
                    
                    self?.db.collection("users").document(firebaseUser.uid).setData(userData, merge: true) { error in
                        if let error = error {
                            completion(.failure(error))
                            return
                        }
                        
                        self?.currentUser = firebaseUser
                        self?.isAuthenticated = true
                        completion(.success(firebaseUser))
                    }
                }
            }
        }
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