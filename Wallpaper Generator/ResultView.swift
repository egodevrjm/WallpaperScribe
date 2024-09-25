import SwiftUI

struct ResultView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: WallpaperViewModel
    @State private var showSaveAlert = false
    @State private var saveError: Error?
    
    let image: UIImage
    
    var body: some View {
        ZStack {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    Spacer()
                }
                .padding()
                
                Spacer()
                
                HStack(spacing: 20) {
                    Button(action: {
                        saveImageToPhotoLibrary(image: image)
                    }) {
                        Text("Save")
                            .foregroundColor(.white)
                            .padding()
                            .frame(width: 120)
                            .background(Color.green)
                            .cornerRadius(15)
                    }
                    
                    Button(action: regenerateWallpaper) {
                        Text("Regenerate")
                            .foregroundColor(.white)
                            .padding()
                            .frame(width: 120)
                            .background(Color.orange)
                            .cornerRadius(15)
                    }
                }
                .padding(.bottom, 50)
            }
        }
        .alert(isPresented: $showSaveAlert) {
               if saveError == nil {
                   return Alert(title: Text("Success"), message: Text("Image saved to Photo Library."), dismissButton: .default(Text("OK")))
               } else {
                   return Alert(title: Text("Error"), message: Text(saveError?.localizedDescription ?? "Unknown error"), dismissButton: .default(Text("OK")))
               }
           }
       }
    
    
    func saveImageToPhotoLibrary(image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        showSaveAlert = true
    }
    
    private func regenerateWallpaper() {
        Task {
            await viewModel.regenerateWallpaper()
            presentationMode.wrappedValue.dismiss()
        }
    }
}
