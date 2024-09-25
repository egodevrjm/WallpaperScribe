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
    ]
    
    @State private var searchText = ""  // Search input text
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading) {
                    // Search TextField
                    TextField("Search backgrounds...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                        .padding(.top)
                    
                    // Filtered Default Images Section
                    let filteredDefaultImages = staticBackgroundStyles.filter { searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText) }
                    
                    if !filteredDefaultImages.isEmpty {
                        Text("Default Images")
                            .font(.headline)
                            .padding(.leading, 16)
                        
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 20)]) {
                            ForEach(filteredDefaultImages) { style in
                                ZStack {
                                    Button(action: {
                                        selectedBackground = style
                                        presentationMode.wrappedValue.dismiss() // Dismiss after selecting
                                    }) {
                                        ZStack(alignment: .bottom) {
                                            // Image with corner radius and shadow
                                            Image(style.imageName ?? "placeholder")
                                                .resizable()
                                                .scaledToFill()
                                                .frame(height: 160)
                                                .cornerRadius(15)
                                                .shadow(radius: 5)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 15)
                                                        .stroke(selectedBackground == style ? Color.blue : Color.clear, lineWidth: 4)
                                                )
                                            
                                            // Text overlay with gradient background
                                            LinearGradient(gradient: Gradient(colors: [.black.opacity(0.8), .clear]), startPoint: .bottom, endPoint: .center)
                                                .frame(height: 40)
                                                .cornerRadius(15)
                                                .overlay(
                                                    Text(style.name)
                                                        .fontWeight(.bold)
                                                        .foregroundColor(.white)
                                                        .padding([.leading, .trailing])
                                                )
                                        }
                                        .clipShape(RoundedRectangle(cornerRadius: 15))
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Filtered User Generated Images Section
                    let filteredUserGeneratedImages = userGeneratedBackgrounds.filter { searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText) }
                    
                    if !filteredUserGeneratedImages.isEmpty {
                        Text("User Generated Images")
                            .font(.headline)
                            .padding([.top, .leading], 16)
                        
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 20)]) {
                            ForEach(filteredUserGeneratedImages) { style in
                                ZStack {
                                    Button(action: {
                                        selectedBackground = style
                                        presentationMode.wrappedValue.dismiss() // Dismiss after selecting
                                    }) {
                                        ZStack(alignment: .bottom) {
                                            if let image = style.image {
                                                Image(uiImage: image)
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(height: 160)
                                                    .cornerRadius(15)
                                                    .shadow(radius: 5)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 15)
                                                            .stroke(selectedBackground == style ? Color.blue : Color.clear, lineWidth: 4)
                                                    )
                                            }

                                            // Text overlay with gradient background
                                            LinearGradient(gradient: Gradient(colors: [.black.opacity(0.8), .clear]), startPoint: .bottom, endPoint: .center)
                                                .frame(height: 40)
                                                .cornerRadius(15)
                                                .overlay(
                                                    Text(style.name)
                                                        .fontWeight(.bold)
                                                        .foregroundColor(.white)
                                                        .padding([.leading, .trailing])
                                                )
                                        }
                                        .clipShape(RoundedRectangle(cornerRadius: 15))
                                    }

                                    // Remove button
                                    Button(action: {
                                        removeGeneratedImage(style.id)
                                    }) {
                                        Image(systemName: "trash")
                                            .foregroundColor(.red)
                                            .padding(10)
                                            .background(Color.white.opacity(0.8))
                                            .clipShape(Circle())
                                            .shadow(radius: 5)
                                    }
                                    .offset(x: 50, y: -50) // Position the remove button over the image
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.top)
            }
            .navigationTitle("Select Background")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}
