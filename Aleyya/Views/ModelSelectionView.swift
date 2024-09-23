import SwiftUI

struct ModelSelectionView: View {
    @Binding var selectedModel: ChatModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                ForEach(ChatModel.allCases) { model in
                    Button(action: {
                        selectedModel = model
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack {
                            Text(model.displayName)
                            Spacer()
                            if model == selectedModel {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Model")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct ModelSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        ModelSelectionView(selectedModel: .constant(.sonnet35))
    }
}