import SwiftUI
import FalClient

@MainActor
class WallpaperViewModel: ObservableObject {
    @Published var keyword: String = ""
    @Published var selectedBackground: BackgroundStyle?
    @Published var isGenerating: Bool = false
    @Published var generatedImage: UIImage?
    @Published var showErrorAlert: Bool = false
    @Published var errorMessage: String = ""
    
    private var fal: (any Client)?
    private var apiKey: String?
    
    var isApiKeySet: Bool {
         return apiKey != nil && !apiKey!.isEmpty
     }
    
    // Existing properties...
    @Published var userGeneratedBackgrounds: [BackgroundStyle] = []
    private var userGeneratedImageFilenames: [String] = []
    
    init() {
        loadApiKey()
        initializeFalClient()
        
        // Load images from disk when the view model is initialized
        loadFilenames()
        loadGeneratedImages()
    }
    
    private func loadApiKey() {
        apiKey = KeychainHelper.shared.getApiKey()
    }
    
    private func initializeFalClient() {
        if let apiKey = apiKey, !apiKey.isEmpty {
            fal = FalClient.withCredentials(.keyPair(apiKey))
        } else {
            fal = nil
        }
    }
    
    func updateApiKey(_ newApiKey: String) {
        apiKey = newApiKey
        initializeFalClient()
    }
    
    func generateWallpaper() async {
        guard !keyword.isEmpty else { return }
        isGenerating = true
        
        guard let fal = fal else {
            DispatchQueue.main.async {
                self.errorMessage = "API client not configured. Please set your API key in Settings."
                self.showErrorAlert = true
                self.isGenerating = false
            }
            return
        }
        
        do {
            let prompt = refinePrompt()
            let payload = Payload.dict([
                "prompt": .string(prompt),
                "image_size": .string("portrait_16_9"),
                "num_inference_steps": .int(4),
                "num_images": .int(1),
                "enable_safety_checker": .bool(true)
            ])
            
            let result = try await fal.subscribe(
                to: "fal-ai/flux/schnell",
                input: payload,
                includeLogs: true
            ) { update in
                if case let .inProgress(logs) = update {
                    print("Generation Logs: \(logs)")
                }
            }
            
            if case let .dict(resultDict) = result,
               case let .array(images)? = resultDict["images"],
               case let .dict(firstImage)? = images.first,
               case let .string(imageUrlString)? = firstImage["url"],
               let imageUrl = URL(string: imageUrlString) {
                let (data, _) = try await URLSession.shared.data(from: imageUrl)
                if let uiImage = UIImage(data: data) {
                    if let backgroundStyle = saveGeneratedImage(uiImage) {
                        DispatchQueue.main.async {
                            self.generatedImage = uiImage
                            self.selectedBackground = backgroundStyle
                        }
                    } else {
                        // Handle the error if saving the image failed
                        DispatchQueue.main.async {
                            self.errorMessage = "Failed to save generated image."
                            self.showErrorAlert = true
                        }
                    }
                } else {
                    throw NSError(domain: "ImageProcessing", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to create image from data"])
                }
            } else {
                throw NSError(domain: "ResultProcessing", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to process result"])
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.showErrorAlert = true
            }
        }
        
        DispatchQueue.main.async {
            self.isGenerating = false
        }
    }
    
    func saveGeneratedImage(_ image: UIImage) -> BackgroundStyle? {
        let uuid = UUID()
        let filename = uuid.uuidString + ".jpg"
        let url = getDocumentsDirectory().appendingPathComponent(filename)
        
        if let data = image.jpegData(compressionQuality: 1.0) {
            do {
                try data.write(to: url)
                userGeneratedImageFilenames.append(filename)
                saveFilenames()
                
                // Create a BackgroundStyle with the saved image
                let backgroundStyle = BackgroundStyle(name: "Generated Image", image: image, id: uuid)
                userGeneratedBackgrounds.append(backgroundStyle)
                return backgroundStyle
            } catch {
                print("Error saving image: \(error)")
            }
        }
        return nil
    }
    
    func loadGeneratedImages() {
        userGeneratedBackgrounds = userGeneratedImageFilenames.compactMap { filename in
            let url = getDocumentsDirectory().appendingPathComponent(filename)
            if let image = UIImage(contentsOfFile: url.path),
               let id = UUID(uuidString: filename.replacingOccurrences(of: ".jpg", with: "")) {
                return BackgroundStyle(name: "Generated Image", image: image, id: id)
            } else {
                print("Invalid UUID string in filename: \(filename)")
                // Optionally handle the error, e.g., remove the filename from the array
                return nil
            }
        }
    }
    
    // Save the filenames array to disk
    func saveFilenames() {
        let url = getDocumentsDirectory().appendingPathComponent("filenames.json")
        do {
            let data = try JSONEncoder().encode(userGeneratedImageFilenames)
            try data.write(to: url)
        } catch {
            print("Error saving filenames: \(error)")
        }
    }
    
    func loadFilenames() {
        let url = getDocumentsDirectory().appendingPathComponent("filenames.json")
        do {
            let data = try Data(contentsOf: url)
            let filenames = try JSONDecoder().decode([String].self, from: data)
            // Filter out invalid filenames
            userGeneratedImageFilenames = filenames.filter { filename in
                UUID(uuidString: filename.replacingOccurrences(of: ".jpg", with: "")) != nil
            }
        } catch {
            print("Error loading filenames: \(error)")
        }
    }
    
    // Helper method to get the documents directory
    func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    func refinePrompt() -> String {
        var refinedPrompt = keyword
        if let background = selectedBackground {
            refinedPrompt += ", background: \(background.name)"
        }
        refinedPrompt += ", vertical orientation, full-screen composition"
        return refinedPrompt
    }
    
    func regenerateWallpaper() async {
        await generateWallpaper()
    }
    
    func removeGeneratedImage(withId id: UUID) {
        let filename = id.uuidString + ".jpg"
        let url = getDocumentsDirectory().appendingPathComponent(filename)
        
        do {
            try FileManager.default.removeItem(at: url)
            // Remove the filename from the array and save
            if let index = userGeneratedImageFilenames.firstIndex(of: filename) {
                userGeneratedImageFilenames.remove(at: index)
                saveFilenames()
            } else {
                print("Filename not found in the list: \(filename)")
            }
            // Remove the background style from the array
            if let index = userGeneratedBackgrounds.firstIndex(where: { $0.id == id }) {
                userGeneratedBackgrounds.remove(at: index)
            }
            // If the removed background was selected, reset the selected background
            if selectedBackground?.id == id {
                selectedBackground = nil
            }
        } catch {
            print("Error removing image: \(error)")
        }
    }
}
