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
    @Published var userGeneratedBackgrounds: [BackgroundStyle] = []
    private var userGeneratedImageFilenames: [String] = []


    private let fal: any Client

    init() {
        // Make sure to replace "YOUR_API_KEY" with your actual API key
        self.fal = FalClient.withCredentials(.keyPair("b45528c0-13b0-4ea6-9568-ce72cce22c43:c5bcc1b57e069329561af8e7c1c08d34"))
        loadFilenames()
        loadGeneratedImages()
    }
    
    func saveGeneratedImage(_ image: UIImage) -> BackgroundStyle? {
        let filename = UUID().uuidString + ".jpg"
        let url = getDocumentsDirectory().appendingPathComponent(filename)

        if let data = image.jpegData(compressionQuality: 1.0) {
            do {
                try data.write(to: url)
                userGeneratedImageFilenames.append(filename)
                saveFilenames()

                // Create a BackgroundStyle with the saved image and UUID
                let id = UUID(uuidString: filename.replacingOccurrences(of: ".jpg", with: "")) ?? UUID()
                let backgroundStyle = BackgroundStyle(name: "Generated Image", image: image, id: id)

                // Update the published arrays
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
                if let image = UIImage(contentsOfFile: url.path) {
                    return BackgroundStyle(name: "Generated Image", image: image, id: UUID(uuidString: filename) ?? UUID())
                }
                return nil
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

       // Load the filenames array from disk
       func loadFilenames() {
           let url = getDocumentsDirectory().appendingPathComponent("filenames.json")
           do {
               let data = try Data(contentsOf: url)
               userGeneratedImageFilenames = try JSONDecoder().decode([String].self, from: data)
           } catch {
               print("Error loading filenames: \(error)")
           }
       }

       // Helper method to get the documents directory
       func getDocumentsDirectory() -> URL {
           FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
       }

    func generateWallpaper() async {
        guard !keyword.isEmpty else { return }
        isGenerating = true

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
