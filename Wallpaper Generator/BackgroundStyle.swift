import SwiftUI

struct BackgroundStyle: Identifiable, Equatable {
    let id: UUID
    let name: String
    let imageName: String?
    let image: UIImage?
    
    // Convenience initializer for static backgrounds
    init(name: String, imageName: String) {
        self.id = UUID() // Initialize id
        self.name = name
        self.imageName = imageName
        self.image = nil
    }
    
    // Convenience initializer for dynamically generated images
    init(name: String, image: UIImage) {
        self.id = UUID() // Initialize id
        self.name = name
        self.imageName = nil
        self.image = image
    }
    
    // New initializer to allow custom IDs
    init(name: String, image: UIImage, id: UUID) {
        self.id = id
        self.name = name
        self.imageName = nil
        self.image = image
    }
    
    static func == (lhs: BackgroundStyle, rhs: BackgroundStyle) -> Bool {
        return lhs.id == rhs.id
    }
}


struct BackgroundSelectionView: View {
    @Binding var selectedBackground: BackgroundStyle?
    @Binding var userGeneratedBackgrounds: [BackgroundStyle] // Use BackgroundStyle
    var removeGeneratedImage: (UUID) -> Void
    
    // Static background styles
    let staticBackgroundStyles = [
        BackgroundStyle(name: "Sunset Mountain", imageName: "sunset_mountain"),
        BackgroundStyle(name: "Ocean View", imageName: "ocean_view"),
        BackgroundStyle(name: "Forest Path", imageName: "forest_path"),
        BackgroundStyle(name: "Serenity", imageName: "serenity"),
        BackgroundStyle(name: "Waterfall", imageName: "waterfall"),
        BackgroundStyle(name: "Jupiter", imageName: "jupiter")
        // Add more static styles as needed
    ]
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [GridItem(), GridItem()]) {
                    
                    // Display static backgrounds
                    ForEach(staticBackgroundStyles) { style in
                        Button(action: {
                            selectedBackground = style
                        }) {
                            VStack {
                                if let imageName = style.imageName {
                                    Image(imageName)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 100)
                                        .cornerRadius(10)
                                }
                                Text(style.name)
                                    .foregroundColor(.primary)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(selectedBackground == style ? Color.blue : Color.clear, lineWidth: 2)
                            )
                        }
                    }
                    
                    // Display dynamically generated backgrounds
                    ForEach(userGeneratedBackgrounds) { style in
                        VStack {
                            Button(action: {
                                selectedBackground = style
                            }) {
                                if let image = style.image {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 100)
                                        .cornerRadius(10)
                                }
                            }
                            Text(style.name)
                                .foregroundColor(.primary)
                            
                            // In the remove button action:
                            Button(action: {
                                removeGeneratedImage(style.id)
                            }) {
                                Text("Remove")
                                    .foregroundColor(.red)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(selectedBackground == style ? Color.blue : Color.clear, lineWidth: 2)
                            )
                        }
                    }
                    .padding()
                }
                .navigationTitle("Select Background")
                .navigationBarItems(trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                })
            }
        }
        
        
    }
}
