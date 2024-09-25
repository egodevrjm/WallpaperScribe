import SwiftUI

struct SplashView: View {
    @State private var currentIndex = 0
    @State private var isActive = false
    
    let defaultImages = [
        "sunset_mountain",
        "ocean_view",
        "forest_path",
        "serenity",
        "waterfall",
        "jupiter"
    ]
    
    var body: some View {
        ZStack {
            // Dark background
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                            // App Name with Custom Font
                            Text("WallpaperScribe")
                                .font(.custom("Modern Deco", size: 56)) // Use the custom Modern Deco font
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.top, 60)
                                .padding(.bottom, 60)
                
                // Card Deck Animation (show 3 images at once)
                ZStack {
                    ForEach(0..<3, id: \.self) { position in
                        let imageIndex = (currentIndex + position) % defaultImages.count
                        Image(defaultImages[imageIndex])
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 250, height: 400)
                            .cornerRadius(15)
                            .shadow(radius: 10)
                            .rotationEffect(getRotation(for: position))
                            .offset(x: getHorizontalOffset(for: position))
                            .opacity(getOpacity(for: position))
                            .zIndex(getZIndex(for: position))
                            .animation(.easeInOut(duration: 0.8)) // Smooth animation
                    }
                }
                .frame(width: 250, height: 400)
                .onAppear {
                    // Cycle through images every 2 seconds
                    Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
                        withAnimation {
                            currentIndex = (currentIndex + 1) % defaultImages.count
                        }
                    }
                }
                
                Spacer()
                
                // Loading indicator at the bottom
                VStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5) // Make the loading icon larger
                    Text("Loading...")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.top, 8)
                }
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            // Simulate loading delay, replace this with actual loading logic
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                self.isActive = true
            }
        }
        .fullScreenCover(isPresented: $isActive) {
            MainView() // Switch to your MainView after loading
        }
    }
    
    // MARK: - Helper Functions
    
    // Get rotation angle for the card position
    func getRotation(for position: Int) -> Angle {
        if position == 0 {
            return .degrees(0) // Center card (main card) is upright
        } else if position == 1 {
            return .degrees(-15) // Left card is rotated slightly to the left
        } else {
            return .degrees(15) // Right card is rotated slightly to the right
        }
    }
    
    // Get horizontal offset for the card position
    func getHorizontalOffset(for position: Int) -> CGFloat {
        if position == 0 {
            return 0 // Center card is in the middle
        } else if position == 1 {
            return -100 // Left card moves to the left
        } else {
            return 100 // Right card moves to the right
        }
    }
    
    // Get opacity for the card position
    func getOpacity(for position: Int) -> Double {
        return position == 0 ? 1.0 : 0.5 // Center card is fully opaque, others are 50%
    }
    
    // Get ZIndex for proper layering of cards
    func getZIndex(for position: Int) -> Double {
        return position == 0 ? 1 : 0 // Center card is on top
    }
}
