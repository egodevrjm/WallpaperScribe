import SwiftUI
import Photos

struct MainView: View {
    @StateObject private var viewModel = WallpaperViewModel()
    @State private var showBackgroundSelection = false
    @State private var showSaveAlert = false
    @State private var saveError: Error?
    @FocusState private var isInputFocused: Bool
    @State private var backgroundOpacity: Double = 1.0
    @AppStorage("userGeneratedImages") private var userGeneratedImagesData: Data = Data() // For persisting generated images
    @State private var userGeneratedImages: [UIImage] = [] // Array to load generated images
    @State private var selectedBackground: BackgroundStyle? // Track selected background
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack(alignment: .top) {
                    // Background Image (either default or generated)
                    Group {
                        if let selectedBackground = selectedBackground {
                            if let image = selectedBackground.image {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .ignoresSafeArea() // Ensure the image fills the entire view
                            } else if let imageName = selectedBackground.imageName {
                                Image(imageName)
                                    .resizable()
                                    .scaledToFill()
                                    .ignoresSafeArea() // Ensure the image fills the entire view
                            }
                        } else {
                            Image("sunset_mountain") // Default image
                                .resizable()
                                .scaledToFill()
                                .ignoresSafeArea() // Ensure the image fills the entire view
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
                .sheet(isPresented: $showBackgroundSelection) {
                    BackgroundSelectionView(selectedBackground: $selectedBackground, userGeneratedImages: $userGeneratedImages)
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
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("") // Empty title to prevent showing the text
            .onAppear {
                loadGeneratedImages()
            }
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
        
        // After generating the wallpaper, add it to the user's images section and persist it
        if let generatedImage = viewModel.generatedImage {
            userGeneratedImages.append(generatedImage)
            saveGeneratedImages()
            selectedBackground = BackgroundStyle(name: "Generated Image", image: generatedImage) // Automatically set as the background
        }
    }
    
    private func loadGeneratedImages() {
        if let loadedImages = UIImage.convertDataArrayToImages(dataArray: userGeneratedImagesData) {
            userGeneratedImages = loadedImages
        }
    }
    
    private func saveGeneratedImages() {
        userGeneratedImagesData = UIImage.convertImagesToDataArray(images: userGeneratedImages)
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
