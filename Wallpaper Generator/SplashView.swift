import SwiftUI

struct SplashView: View {
    @State private var isActive = false
    
    var body: some View {
        VStack {
            // Your splash screen content, e.g., logo, app name, etc.
            Image(systemName: "star.fill")
                .resizable()
                .frame(width: 100, height: 100)
                .foregroundColor(.yellow)
            
            Text("Your App Name")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.blue)
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            // Simulate loading time or check for app readiness
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                // After the delay, set isActive to true to switch to MainView
                self.isActive = true
            }
        }
        .fullScreenCover(isPresented: $isActive) {
            MainView() // Switch to your MainView
        }
    }
}
