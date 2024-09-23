import SwiftUI

struct SettingsView: View {
    @Binding var apiKey: String
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("API Key")) {
                    SecureField("Enter your OpenRouter API Key", text: $apiKey)
                }
                
                Section {
                    Button("Save") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(apiKey: .constant(""))
    }
}