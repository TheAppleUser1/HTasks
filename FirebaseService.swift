import Foundation
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

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
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let user = result?.user {
                // Create user profile in Firestore
                let userData: [String: Any] = [
                    "username": username,
                    "email": email,
                    "createdAt": FieldValue.serverTimestamp()
                ]
                
                self?.db.collection("users").document(user.uid).setData(userData) { error in
                    if let error = error {
                        completion(.failure(error))
                        return
                    }
                    
                    self?.currentUser = user
                    self?.isAuthenticated = true
                    completion(.success(user))
                }
            }
        }
    }
    
    func signOut() throws {
        try Auth.auth().signOut()
        currentUser = nil
        isAuthenticated = false
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