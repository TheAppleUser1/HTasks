import SwiftUI
import FirebaseAuth
import SwiftGlass

struct FeedView: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var firebaseService = FirebaseService.shared
    @State private var posts: [Post] = []
    @State private var showingNewPostSheet = false
    @State private var showingAuthSheet = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Social Feed")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(colorScheme == .dark ? .white : .black)
                .padding(.top)
            
            if firebaseService.isAuthenticated {
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(posts) { post in
                            PostCard(post: post)
                                .glass(radius: 12, color: colorScheme == .dark ? .white : .black, material: .regularMaterial, gradientOpacity: 0.15)
                        }
                    }
                    .padding()
                }
            } else {
                VStack(spacing: 20) {
                    Text("Sign in to see what others are up to!")
                        .font(.headline)
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.7))
                        .multilineTextAlignment(.center)
                    
                    Button(action: { showingAuthSheet = true }) {
                        Text("Sign In")
                            .font(.headline)
                            .foregroundColor(colorScheme == .dark ? .black : .white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(colorScheme == .dark ? .white : .black)
                            )
                    }
                    .padding(.horizontal)
                }
                .padding()
                .glass(radius: 16, color: colorScheme == .dark ? .white : .black, material: .regularMaterial, gradientOpacity: 0.15)
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
            .ignoresSafeArea()
        )
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
                Button(action: { showingComments = true }) {
                    HStack {
                        Image(systemName: "bubble.right")
                        Text("\(post.comments)")
                    }
                }
                .glass(radius: 12, color: colorScheme == .dark ? .white : .black, material: .regularMaterial)
            }
            .foregroundColor(.gray)
        }
        .padding()
        .glass(radius: 16, color: colorScheme == .dark ? .white : .black, material: .regularMaterial)
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
                    .glass(radius: 12, color: colorScheme == .dark ? .white : .black, material: .regularMaterial)
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
                }
                .glass(radius: 12, color: .blue, material: .regularMaterial, gradientOpacity: 0.7)
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
                    .glass(radius: 12, color: colorScheme == .dark ? .white : .black, material: .regularMaterial)
                }
            }
        }
    }
}

#Preview {
    FeedView()
} 
