import SwiftUI

struct BackgroundStyle: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let imageName: String?
    let image: UIImage? // For dynamically generated images
    
    // Convenience initializer for static backgrounds
    init(name: String, imageName: String) {
        self.name = name
        self.imageName = imageName
        self.image = nil
    }
    
    // Convenience initializer for dynamically generated images
    init(name: String, image: UIImage) {
        self.name = name
        self.imageName = nil
        self.image = image
    }
}

struct BackgroundSelectionView: View {
    @Binding var selectedBackground: BackgroundStyle?
    @Binding var userGeneratedImages: [UIImage] // Dynamically generated wallpapers
    
    
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
                       
                       // Display dynamically generated images with a remove button
                       ForEach(userGeneratedImages.indices, id: \.self) { index in
                           let image = userGeneratedImages[index]
                           let generatedStyle = BackgroundStyle(name: "Generated Image", image: image)
                           VStack {
                               Button(action: {
                                   selectedBackground = generatedStyle
                               }) {
                                   Image(uiImage: image)
                                       .resizable()
                                       .scaledToFit()
                                       .frame(height: 100)
                                       .cornerRadius(10)
                               }
                               Text("Generated Image")
                                   .foregroundColor(.primary)
                               
                               Button(action: {
                                   userGeneratedImages.remove(at: index) // Remove the image
                               }) {
                                   Text("Remove")
                                       .foregroundColor(.red)
                               }
                           }
                           .padding()
                           .background(
                               RoundedRectangle(cornerRadius: 10)
                                   .stroke(selectedBackground == generatedStyle ? Color.blue : Color.clear, lineWidth: 2)
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
