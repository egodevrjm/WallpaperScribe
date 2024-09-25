import SwiftUI
import Photos

struct MainView: View {
    @StateObject private var viewModel = WallpaperViewModel()
    @State private var showBackgroundSelection = false
    @State private var showSaveAlert = false
    @State private var saveError: Error?
    @FocusState private var isInputFocused: Bool
    @State private var backgroundOpacity: Double = 1.0
    @State private var showSettingsView = false
    @AppStorage("showGeneratedImages") private var showGeneratedImages: Bool = true
    @State private var backgroundBlur: CGFloat = 0.0
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack(alignment: .top) {
                    Group {
                        if let selectedBackground = viewModel.selectedBackground {
                            if let image = selectedBackground.image {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .ignoresSafeArea()
                                    .opacity(backgroundOpacity) // Bind opacity
                                    .blur(radius: backgroundBlur) // Bind blur effect
                            } else if let imageName = selectedBackground.imageName {
                                Image(imageName)
                                    .resizable()
                                    .scaledToFill()
                                    .ignoresSafeArea()
                                    .opacity(backgroundOpacity) // Bind opacity
                                    .blur(radius: backgroundBlur) // Bind blur effect
                            }
                        } else {
                            Image("sunset_mountain")
                                .resizable()
                                .scaledToFill()
                                .ignoresSafeArea()
                                .opacity(backgroundOpacity) // Bind opacity
                                .blur(radius: backgroundBlur) // Bind blur effect
                        }
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .onTapGesture {
                        isInputFocused = false // Dismiss keyboard when tapping outside
                    } // Add tap gesture here
                    
                    // Semi-transparent overlay for better text visibility
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 0) {
                        Spacer()
                        
                        // Main Content
                        VStack(spacing: 20) {
                            Text("Generate Wallpaper")
                                .font(.custom("Modern Deco", size: 32)) // Use the custom Modern Deco font
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.bottom, 20)
                            
                            // Keyword Input
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.white)
                                TextField("Enter a keyword", text: $viewModel.keyword)
                                    .foregroundColor(.white)
                                    .accentColor(.white)
                                    .focused($isInputFocused) // Add focused state binding
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
                            .disabled(viewModel.isGenerating || !viewModel.isApiKeySet)
                        }
                        .padding(.bottom, 50)
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            showSettingsView = true
                        }) {
                            Image(systemName: "gearshape")
                                .resizable()
                                .frame(width: 24, height: 24)
                                .alignmentGuide(.firstTextBaseline) { d in d[.bottom] }
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack(spacing: 20) {
                            Button(action: {
                                showBackgroundSelection = true
                            }) {
                                Image(systemName: "photo")
                                    .resizable()
                                    .frame(width: 24, height: 24)
                                    .alignmentGuide(.firstTextBaseline) { d in d[.bottom] }
                            }
                            
                            // Save button is always displayed
                            Button(action: {
                                saveImageToPhotoLibrary() // Save the current background
                            }) {
                                Image(systemName: "square.and.arrow.down")
                                    .resizable()
                                    .frame(width: 24, height: 24)
                                    .alignmentGuide(.firstTextBaseline) { d in d[.bottom] }
                                    .offset(y: -2)
                            }
                        }
                    }
                }
                
                // Display generated images in a separate section if enabled
                if showGeneratedImages && !viewModel.userGeneratedBackgrounds.isEmpty {
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
            .sheet(isPresented: $showSettingsView, onDismiss: {
                // Reload API key in view model
                if let newApiKey = KeychainHelper.shared.getApiKey() {
                    viewModel.updateApiKey(newApiKey)
                }
            }) {
                SettingsView()
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
            .onAppear {
                if !viewModel.isApiKeySet {
                    showSettingsView = true
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("") // Empty title to prevent showing the text
        }
    }
    
    private func generateWallpaperWithAnimation() async {
        // Reduce opacity slightly and apply blur with more prominent effect
        withAnimation(Animation.easeInOut(duration: 1.0)) {
            backgroundOpacity = 0.7
            backgroundBlur = 10.0 // Apply larger blur to emphasize the animation
        }
        
        await viewModel.generateWallpaper()
        
        // Reset blur and opacity once wallpaper generation completes
        withAnimation(Animation.easeOut(duration: 1.0)) {
            backgroundOpacity = 1.0
            backgroundBlur = 0.0 // Smoothly remove blur effect
        }
    }
    
    
    func saveImageToPhotoLibrary() {
        var imageToSave: UIImage?
        
        // Check if the current background is a generated image or static
        if let selectedBackground = viewModel.selectedBackground {
            if let image = selectedBackground.image {
                // Generated image
                imageToSave = image
            } else if let imageName = selectedBackground.imageName {
                // Static image (use UIImage(named:) to get the image from the asset catalog)
                imageToSave = UIImage(named: imageName)
            }
        } else {
            // Default fallback (e.g., "sunset_mountain")
            imageToSave = UIImage(named: "sunset_mountain")
        }
        
        // Proceed to save the image if available
        guard let image = imageToSave else { return }
        
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
                // Retry authorization
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
