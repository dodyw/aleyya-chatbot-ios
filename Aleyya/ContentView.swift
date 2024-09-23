import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ChatViewModel()
    @State private var showingSettings = false

    var body: some View {
        NavigationView {
            ChatView(viewModel: viewModel)
                .navigationBarItems(trailing: Button(action: {
                    showingSettings = true
                }) {
                    Image(systemName: "gear")
                })
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(apiKey: $viewModel.apiKey)
        }
        .alert(item: Binding<AlertItem?>(
            get: { viewModel.errorMessage.map { AlertItem(message: $0) } },
            set: { _ in viewModel.errorMessage = nil }
        )) { alertItem in
            Alert(title: Text("Error"), message: Text(alertItem.message))
        }
    }
}

struct AlertItem: Identifiable {
    let id = UUID()
    let message: String
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
