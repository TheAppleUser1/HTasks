import SwiftUI

struct WelcomeView: View {
    @State private var scale: CGFloat = 0.1
    @State private var opacity: Double = 0
    @State private var backgroundScale: CGFloat = 1.0
    @State private var backgroundOpacity: Double = 0
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            // Background based on color scheme
            if colorScheme == .dark {
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.blue.opacity(0.4)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .scaleEffect(backgroundScale)
                .opacity(backgroundOpacity)
                .ignoresSafeArea()
            } else {
                Color.white
                    .scaleEffect(backgroundScale)
                    .opacity(backgroundOpacity)
                    .ignoresSafeArea()
            }
            
            // App Icon
            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                .foregroundColor(colorScheme == .dark ? .white : .blue)
                .scaleEffect(scale)
                .opacity(opacity)
                .onAppear {
                    // First animation: Icon appears
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                        scale = 1.0
                        opacity = 1.0
                    }
                    
                    // Second animation: Background transition
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        withAnimation(.easeInOut(duration: 1.2)) {
                            backgroundScale = 1.2
                            backgroundOpacity = 1.0
                        }
                    }
                }
        }
    }
}

#Preview {
    WelcomeView()
        .preferredColorScheme(.dark)
} 