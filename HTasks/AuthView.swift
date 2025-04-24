import SwiftUI
import SwiftGlass

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
                        .glass(radius: 12, color: .red, material: .regularMaterial, gradientOpacity: 0.3)
                }
                
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    .glass(radius: 12, color: colorScheme == .dark ? .white : .black, material: .regularMaterial)
                
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .glass(radius: 12, color: colorScheme == .dark ? .white : .black, material: .regularMaterial)
                
                if isSignUp {
                    TextField("Username", text: $username)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .glass(radius: 12, color: colorScheme == .dark ? .white : .black, material: .regularMaterial)
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
                }
                .glass(radius: 12, color: .blue, material: .regularMaterial, gradientOpacity: 0.7)
                
                Button(action: {
                    isSignUp.toggle()
                }) {
                    Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.7))
                }
                .glass(radius: 12, color: colorScheme == .dark ? .white : .black, material: .regularMaterial)
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
                .edgesIgnoringSafeArea(.all)
            )
            .navigationTitle(isSignUp ? "Sign Up" : "Sign In")
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