import SwiftUI

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.openURL) var openURL
    @State private var apiKey: String = ""
    @AppStorage("showGeneratedImages") private var showGeneratedImages: Bool = true

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("API Key"), footer: Text("Don't have an API Key? Tap 'Get an API Key' to obtain one from fal.ai.")) {
                    TextField("Enter your API Key", text: $apiKey)
                        .textContentType(.password)
                        .autocapitalization(.none)
                    
                    Button(action: {
                        if let url = URL(string: "https://fal.ai/dashboard/keys") {
                            openURL(url)
                        }
                    }) {
                        Text("Get an API Key")
                            .foregroundColor(.blue)
                    }
                }

                Section {
                    Toggle("Show Generated Images", isOn: $showGeneratedImages)
                }
            }
            .navigationBarTitle("Settings", displayMode: .inline)
            .navigationBarItems(
                leading: apiKey.isEmpty ? nil : Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    saveApiKey()
                    presentationMode.wrappedValue.dismiss()
                }
            )

            .onAppear {
                loadApiKey()
            }
        }
    }

    func saveApiKey() {
        KeychainHelper.shared.save(apiKey: apiKey)
    }

    func loadApiKey() {
        apiKey = KeychainHelper.shared.getApiKey() ?? ""
    }
}
