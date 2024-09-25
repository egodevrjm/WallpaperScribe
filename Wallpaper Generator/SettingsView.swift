import SwiftUI

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var apiKey: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("API Key")) {
                    TextField("Enter your API Key", text: $apiKey)
                        .textContentType(.password)
                        .autocapitalization(.none)
                }
            }
            .navigationBarTitle("Settings", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Cancel") {
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
        // Securely store the API key using Keychain
        KeychainHelper.shared.save(apiKey: apiKey)
    }
    
    func loadApiKey() {
        // Load the API key from Keychain
        apiKey = KeychainHelper.shared.getApiKey() ?? ""
    }
}
