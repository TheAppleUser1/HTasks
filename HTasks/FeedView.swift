import SwiftUI
import FirebaseAuth

struct FeedView: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var firebaseService = FirebaseService.shared
    @State private var posts: [Post] = []
    @State private var showingNewPostSheet = false
    @State private var showingAuthSheet = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Custom Top Bar
                HStack(spacing: 16) {
                    Text("Feed")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                    
                    Spacer()
                    
                    if firebaseService.isAuthenticated {
                        Button(action: {
                            showingNewPostSheet = true
                        }) {
                            Image(systemName: "square.and.pencil")
                                .font(.title3)
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                        }
                    } else {
                        Button(action: {
                            showingAuthSheet = true
                        }) {
                            Text("Sign In")
                                .font(.headline)
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                        }
                    }
                }
                .padding()
                .background(
                    Rectangle()
                        .fill(colorScheme == .dark ? Color.black : Color.white)
                        .shadow(color: Color.black.opacity(0.1), radius: 2, y: 1)
                )
                
                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                }
                
                if isLoading {
                    ProgressView()
                        .padding()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(posts) { post in
                                PostCard(post: post, onLike: {
                                    likePost(post)
                                })
                            }
                        }
                        .padding()
                    }
                }
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: colorScheme == .dark ? 
                                      [Color.black, Color.blue.opacity(0.2)] : 
                                      [Color.white, Color.blue.opacity(0.1)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .edgesIgnoringSafeArea(.all)
            )
        }
        .sheet(isPresented: $showingNewPostSheet) {
            NewPostView(onPost: { content in
                createPost(content: content)
            })
        }
        .sheet(isPresented: $showingAuthSheet) {
            AuthView()
        }
        .onAppear {
            loadPosts()
        }
    }
    
    private func loadPosts() {
        isLoading = true
        errorMessage = nil
        
        firebaseService.fetchPosts { result in
            Task { @MainActor in
                switch result {
                case .success(let fetchedPosts):
                    posts = fetchedPosts
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
                isLoading = false
            }
        }
    }
    
    private func createPost(content: String) {
        isLoading = true
        errorMessage = nil
        
        firebaseService.createPost(content: content) { result in
            Task { @MainActor in
                switch result {
                case .success:
                    loadPosts()
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
                isLoading = false
            }
        }
    }
    
    private func likePost(_ post: Post) {
        isLoading = true
        errorMessage = nil
        
        firebaseService.likePost(postId: post.id) { result in
            Task { @MainActor in
                switch result {
                case .success:
                    loadPosts()
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
                isLoading = false
            }
        }
    }
}

struct PostCard: View {
    let post: Post
    let onLike: () -> Void
    @Environment(\.colorScheme) var colorScheme
    @State private var showingComments = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(post.author)
                    .font(.headline)
                Spacer()
                Text(post.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Text(post.content)
                .font(.body)
            
            HStack {
                Button(action: onLike) {
                    HStack {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                        Text("\(post.likes)")
                    }
                }
                
                Spacer()
                
                Button(action: { showingComments = true }) {
                    HStack {
                        Image(systemName: "bubble.right")
                        Text("\(post.comments)")
                    }
                }
            }
            .foregroundColor(.gray)
        }
        .padding()
        .background(colorScheme == .dark ? Color(.systemGray6) : .white)
        .cornerRadius(12)
        .shadow(radius: 2)
        .sheet(isPresented: $showingComments) {
            CommentView(post: post)
        }
    }
}

struct NewPostView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var postContent: String = ""
    @Environment(\.colorScheme) var colorScheme
    let onPost: (String) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                TextEditor(text: $postContent)
                    .frame(maxHeight: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.white.opacity(0.8))
                    )
                    .padding()
                
                Button(action: {
                    if !postContent.isEmpty {
                        onPost(postContent)
                        dismiss()
                    }
                }) {
                    Text("Post")
                        .fontWeight(.semibold)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(colorScheme == .dark ? Color.blue.opacity(0.7) : Color.blue)
                        )
                        .foregroundColor(.white)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle("New Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct AuthView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var firebaseService = FirebaseService.shared
    @State private var email = ""
    @State private var password = ""
    @State private var username = ""
    @State private var isSignUp = false
    @State private var errorMessage: String?
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                }
                
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                if isSignUp {
                    TextField("Username", text: $username)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                Button(action: {
                    if isSignUp {
                        signUp()
                    } else {
                        signIn()
                    }
                }) {
                    Text(isSignUp ? "Sign Up" : "Sign In")
                        .fontWeight(.semibold)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(colorScheme == .dark ? Color.blue.opacity(0.7) : Color.blue)
                        )
                        .foregroundColor(.white)
                }
                
                Button(action: {
                    isSignUp.toggle()
                }) {
                    Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.7))
                }
            }
            .padding()
            .navigationTitle(isSignUp ? "Sign Up" : "Sign In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func signIn() {
        firebaseService.signIn(email: email, password: password) { result in
            switch result {
            case .success:
                dismiss()
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func signUp() {
        firebaseService.signUp(email: email, password: password, username: username) { result in
            switch result {
            case .success:
                dismiss()
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    FeedView()
} 
