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


    private let fal: any Client

    init() {
        // Make sure to replace "YOUR_API_KEY" with your actual API key
        self.fal = FalClient.withCredentials(.keyPair("b45528c0-13b0-4ea6-9568-ce72cce22c43:c5bcc1b57e069329561af8e7c1c08d34"))
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
                    DispatchQueue.main.async {
                                      self.generatedImage = uiImage
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
                }    }
    

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
 }
