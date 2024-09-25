import SwiftUI
import Photos

struct MainView: View {
    @StateObject private var viewModel = WallpaperViewModel()
    @State private var showBackgroundSelection = false
    @State private var showSaveAlert = false
    @State private var saveError: Error?
    @FocusState private var isInputFocused: Bool
    @State private var backgroundOpacity: Double = 1.0

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack(alignment: .top) {
                    // Background Image
                    Group {
                        if let selectedBackground = viewModel.selectedBackground {
                            if let image = selectedBackground.image {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .ignoresSafeArea()
                            } else if let imageName = selectedBackground.imageName {
                                Image(imageName)
                                    .resizable()
                                    .scaledToFill()
                                    .ignoresSafeArea()
                            }
                        } else {
                            Image("sunset_mountain")
                                .resizable()
                                .scaledToFill()
                                .ignoresSafeArea()
                        }
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)

                    // Semi-transparent overlay for better text visibility
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 0) {
                        Spacer()
                        
                        // Main Content
                        VStack(spacing: 20) {
                            Text("Generate Wallpaper")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.bottom, 20)
                            
                            // Keyword Input
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.white)
                                TextField("Enter a keyword", text: $viewModel.keyword)
                                    .foregroundColor(.white)
                                    .accentColor(.white)
                                    .focused($isInputFocused)
                            }
                            .padding()
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(15)
                            .padding(.horizontal, 40)
                            
                            Button(action: {
                                isInputFocused = false  // Dismiss keyboard
                                Task {
                                    await generateWallpaperWithAnimation()
                                }
                            }) {
                                Text("Generate")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.red.opacity(0.8))
                                    .cornerRadius(15)
                            }
                            .padding(.horizontal, 40)
                            .disabled(viewModel.isGenerating)
                        }
                        .padding(.bottom, 50)
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showBackgroundSelection = true
                        }) {
                            Image(systemName: "photo")
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        if viewModel.generatedImage != nil {
                            Button(action: {
                                saveImageToPhotoLibrary()
                            }) {
                                Image(systemName: "square.and.arrow.down")
                            }
                        }
                    }
                }
                
                // Display generated images in a separate section
                if !viewModel.userGeneratedBackgrounds.isEmpty {
                    VStack(alignment: .leading) {
                        Text("Your Generated Wallpapers")
                            .font(.headline)
                            .padding(.leading, 16)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(viewModel.userGeneratedBackgrounds) { backgroundStyle in
                                    if let image = backgroundStyle.image {
                                        Image(uiImage: image)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 150, height: 150)
                                            .cornerRadius(10)
                                            .shadow(radius: 5)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(Color.white.opacity(0.5), lineWidth: 2)
                                            )
                                            .onTapGesture {
                                                viewModel.selectedBackground = backgroundStyle
                                            }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.top, 20)
                }
            }
            .sheet(isPresented: $showBackgroundSelection) {
                BackgroundSelectionView(
                    selectedBackground: Binding(
                        get: { viewModel.selectedBackground },
                        set: { viewModel.selectedBackground = $0 }
                    ),
                    userGeneratedBackgrounds: Binding(
                        get: { viewModel.userGeneratedBackgrounds },
                        set: { viewModel.userGeneratedBackgrounds = $0 }
                    ),
                    removeGeneratedImage: viewModel.removeGeneratedImage(withId:)
                )
            }
            .alert(isPresented: $viewModel.showErrorAlert) {
                Alert(title: Text("Error"), message: Text(viewModel.errorMessage), dismissButton: .default(Text("OK")))
            }
            .alert(isPresented: $showSaveAlert) {
                if let error = saveError {
                    return Alert(title: Text("Error"), message: Text(error.localizedDescription), dismissButton: .default(Text("OK")))
                } else {
                    return Alert(title: Text("Success"), message: Text("Image saved to Photo Library."), dismissButton: .default(Text("OK")))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("") // Empty title to prevent showing the text
        }
    }
    
    private func generateWallpaperWithAnimation() async {
        withAnimation(Animation.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
            backgroundOpacity = 0.5
        }
        
        await viewModel.generateWallpaper()
        
        withAnimation {
            backgroundOpacity = 1.0
        }
        
        // No need to append the generated image here since it's handled in the view model
    }
    
    func saveImageToPhotoLibrary() {
        guard let image = viewModel.generatedImage else { return }
        
        PHPhotoLibrary.requestAuthorization { status in
            switch status {
            case .authorized, .limited:
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAsset(from: image)
                }) { success, error in
                    DispatchQueue.main.async {
                        if let error = error {
                            self.saveError = error
                            self.showSaveAlert = true
                        } else if success {
                            self.showSaveAlert = true
                        } else {
                            self.saveError = NSError(domain: "PhotoLibrarySave", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to save image"])
                            self.showSaveAlert = true
                        }
                    }
                }
            case .denied, .restricted:
                DispatchQueue.main.async {
                    self.saveError = NSError(domain: "PhotoLibraryAccess", code: 0, userInfo: [NSLocalizedDescriptionKey: "Photo library access denied"])
                    self.showSaveAlert = true
                }
            case .notDetermined:
                // This shouldn't happen, but if it does, we can try requesting authorization again
                self.saveImageToPhotoLibrary()
            @unknown default:
                DispatchQueue.main.async {
                    self.saveError = NSError(domain: "PhotoLibraryAccess", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unknown photo library access status"])
                    self.showSaveAlert = true
                }
            }
        }
    }
}
