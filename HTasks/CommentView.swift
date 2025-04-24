import SwiftUI
import SwiftGlass

struct CommentView: View {
    let post: Post
    @StateObject private var firebaseService = FirebaseService.shared
    @State private var comments: [Comment] = []
    @State private var newCommentText = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Navigation Bar
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                }
                .glass(radius: 12, color: colorScheme == .dark ? .white : .black, material: .regularMaterial)
                
                Spacer()
                
                Text("Comments")
                    .font(.headline)
                    .glass(radius: 12, color: colorScheme == .dark ? .white : .black, material: .regularMaterial)
                
                Spacer()
            }
            .padding()
            
            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .padding()
                    .glass(radius: 12, color: .red, material: .regularMaterial, gradientOpacity: 0.3)
            }
            
            if isLoading {
                ProgressView()
                    .padding()
                    .glass(radius: 12, color: colorScheme == .dark ? .white : .black, material: .regularMaterial)
            } else {
                // Comments List
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(comments) { comment in
                            CommentRow(comment: comment)
                        }
                    }
                    .padding()
                }
            }
            
            // Comment Input
            if firebaseService.isAuthenticated {
                VStack(spacing: 8) {
                    Divider()
                    HStack {
                        TextField("Add a comment...", text: $newCommentText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .glass(radius: 12, color: colorScheme == .dark ? .white : .black, material: .regularMaterial)
                        
                        Button(action: submitComment) {
                            Image(systemName: "arrow.up.circle.fill")
                                .foregroundColor(newCommentText.isEmpty ? .gray : .blue)
                                .font(.title2)
                        }
                        .disabled(newCommentText.isEmpty)
                        .glass(radius: 12, color: newCommentText.isEmpty ? .gray : .blue, material: .regularMaterial, gradientOpacity: 0.7)
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
        .onAppear(perform: loadComments)
    }
    
    private func loadComments() {
        isLoading = true
        errorMessage = nil
        
        firebaseService.fetchComments(for: post.id) { result in
            isLoading = false
            switch result {
            case .success(let fetchedComments):
                comments = fetchedComments
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func submitComment() {
        guard !newCommentText.isEmpty else { return }
        
        let commentText = newCommentText
        newCommentText = ""
        
        firebaseService.createComment(postId: post.id, content: commentText) { result in
            switch result {
            case .success:
                loadComments()
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }
}

struct CommentRow: View {
    let comment: Comment
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(comment.author)
                    .font(.headline)
                Spacer()
                Text(comment.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Text(comment.content)
                .font(.body)
        }
        .padding()
        .glass(radius: 16, color: colorScheme == .dark ? .white : .black, material: .regularMaterial)
    }
}

#Preview {
    CommentView(post: Post(id: "preview", content: "Test Post", author: "Test User", timestamp: Date(), likes: 0, comments: 0))
} 