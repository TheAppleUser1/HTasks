import SwiftUI
import FirebaseAuth
import SwiftGlass

struct AuthView: View {
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var isSignIn = false
    @State private var showError = false
    @State private var errorMessage = ""
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @StateObject private var firebaseService = FirebaseService.shared
    
    var body: some View {
        VStack(spacing: 24) {
            // Logo and Title
            VStack(spacing: 16) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Welcome HTasks")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                
                Text(isSignIn ? "Sign in to continue" : "Create an account to continue")
                    .font(.headline)
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.7))
            }
            .padding(.top, 40)
            
            // Input Fields
            VStack(spacing: 16) {
                if !isSignIn {
                    TextField("Choose a username", text: $username)
                        .textFieldStyle(.plain)
                        .padding()
                        .glass(radius: 12, color: colorScheme == .dark ? .white : .black, material: .regularMaterial, gradientOpacity: 0.15)
                }
                
                TextField("Enter your email", text: $email)
                    .textFieldStyle(.plain)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .padding()
                    .glass(radius: 12, color: colorScheme == .dark ? .white : .black, material: .regularMaterial, gradientOpacity: 0.15)
                
                SecureField("Create a password", text: $password)
                    .textFieldStyle(.plain)
                    .padding()
                    .glass(radius: 12, color: colorScheme == .dark ? .white : .black, material: .regularMaterial, gradientOpacity: 0.15)
            }
            .padding(.horizontal)
            
            // Action Button
            Button(action: handleAuth) {
                Text(isSignIn ? "Sign In" : "Create Account")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue)
                    )
            }
            .padding(.horizontal)
            
            // Toggle Sign In/Sign Up
            Button(action: { isSignIn.toggle() }) {
                Text(isSignIn ? "Don't have an account? Sign up" : "Already have an account? Sign in")
                    .foregroundColor(.blue)
            }
            
            Text("OR")
                .foregroundColor(colorScheme == .dark ? .white.opacity(0.5) : .black.opacity(0.5))
                .padding(.vertical)
            
            // Social Sign In Buttons
            VStack(spacing: 12) {
                Button(action: signInWithGoogle) {
                    HStack {
                        Image("google_logo") // Add this image to your assets
                            .resizable()
                            .frame(width: 24, height: 24)
                        Text("Continue with Google")
                            .font(.headline)
                    }
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .frame(maxWidth: .infinity)
                    .padding()
                }
                .glass(radius: 12, color: colorScheme == .dark ? .white : .black, material: .regularMaterial, gradientOpacity: 0.15)
                
                Button(action: signInWithFacebook) {
                    HStack {
                        Image("facebook_logo") // Add this image to your assets
                            .resizable()
                            .frame(width: 24, height: 24)
                        Text("Continue with Facebook")
                            .font(.headline)
                    }
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .frame(maxWidth: .infinity)
                    .padding()
                }
                .glass(radius: 12, color: colorScheme == .dark ? .white : .black, material: .regularMaterial, gradientOpacity: 0.15)
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
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
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private func handleAuth() {
        if isSignIn {
            signIn()
        } else {
            signUp()
        }
    }
    
    private func signUp() {
        guard !email.isEmpty && !password.isEmpty && !username.isEmpty else {
            errorMessage = "Please fill in all fields"
            showError = true
            return
        }
        
        firebaseService.signUp(email: email, password: password, username: username) { result in
            switch result {
            case .success:
                // Create user document in Firestore
                createUserDocument()
                dismiss()
            case .failure(let error):
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
    
    private func signIn() {
        guard !email.isEmpty && !password.isEmpty else {
            errorMessage = "Please fill in all fields"
            showError = true
            return
        }
        
        firebaseService.signIn(email: email, password: password) { result in
            switch result {
            case .success:
                dismiss()
            case .failure(let error):
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
    
    private func createUserDocument() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let userData: [String: Any] = [
            "username": username,
            "email": email,
            "settings": UserSettings.defaultSettings,
            "promptsRemaining": 15,
            "lastPromptReset": Date(),
            "createdAt": Date()
        ]
        
        firebaseService.createUserDocument(userId: userId, data: userData)
    }
    
    private func signInWithGoogle() {
        // Implement Google Sign In
    }

} 

