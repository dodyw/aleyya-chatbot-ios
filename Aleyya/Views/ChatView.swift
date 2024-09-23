import SwiftUI
import Photos
import AVFoundation

struct ChatView: View {
    @ObservedObject var viewModel: ChatViewModel
    @State private var showingModelSelection = false
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var inputImage: UIImage?
    @State private var showingPermissionAlert = false
    @State private var permissionAlertMessage = ""
    
    var body: some View {
        VStack {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(viewModel.messages) { message in
                            MessageBubble(message: message)
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages) { _ in
                    if let lastMessage = viewModel.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            HStack {
                Button(action: {
                    showingModelSelection = true
                }) {
                    Image(systemName: "gear")
                        .foregroundColor(.blue)
                }
                
                if let selectedImage = viewModel.selectedImage {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .cornerRadius(5)
                }
                
                TextField("Type a message...", text: $viewModel.inputMessage)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disabled(viewModel.isLoading)
                
                if viewModel.selectedModel.supportsImageUpload {
                    Button(action: {
                        checkPhotoLibraryPermission()
                    }) {
                        Image(systemName: "photo")
                            .foregroundColor(.blue)
                    }
                    
                    Button(action: {
                        checkCameraPermission()
                    }) {
                        Image(systemName: "camera")
                            .foregroundColor(.blue)
                    }
                }
                
                Button(action: viewModel.sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.blue)
                }
                .disabled(viewModel.inputMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && viewModel.selectedImage == nil || viewModel.isLoading || viewModel.apiKey.isEmpty)
            }
            .padding()
        }
        .navigationTitle("Chat")
        .navigationBarItems(
            leading: Text(viewModel.selectedModel.displayName)
                .font(.subheadline)
                .foregroundColor(.secondary),
            trailing: Button(action: viewModel.startNewChat) {
                Image(systemName: "plus.circle")
                    .foregroundColor(.blue)
            }
        )
        .sheet(isPresented: $showingModelSelection) {
            ModelSelectionView(selectedModel: $viewModel.selectedModel)
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $inputImage, sourceType: .photoLibrary)
        }
        .sheet(isPresented: $showingCamera) {
            ImagePicker(image: $inputImage, sourceType: .camera)
        }
        .onChange(of: inputImage) { newImage in
            if let image = newImage {
                viewModel.setImage(image)
            }
        }
        .overlay(
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(width: 80, height: 80)
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(10)
                        .shadow(radius: 10)
                }
            }
        )
        .alert(isPresented: $showingPermissionAlert) {
            Alert(
                title: Text("Permission Required"),
                message: Text(permissionAlertMessage),
                primaryButton: .default(Text("Settings"), action: openSettings),
                secondaryButton: .cancel()
            )
        }
        .alert(isPresented: Binding<Bool>(
            get: { viewModel.apiKey.isEmpty },
            set: { _ in }
        )) {
            Alert(
                title: Text("API Key Required"),
                message: Text("Please set your OpenRouter API key in the settings."),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private func checkPhotoLibraryPermission() {
        PHPhotoLibrary.requestAuthorization { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized, .limited:
                    self.showingImagePicker = true
                case .denied, .restricted:
                    self.permissionAlertMessage = "Please allow access to your photo library in Settings to upload images."
                    self.showingPermissionAlert = true
                case .notDetermined:
                    // This case should not be reached as we've just requested authorization
                    break
                @unknown default:
                    break
                }
            }
        }
    }
    
    private func checkCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                if granted {
                    self.showingCamera = true
                } else {
                    self.permissionAlertMessage = "Please allow access to your camera in Settings to take photos."
                    self.showingPermissionAlert = true
                }
            }
        }
    }
    
    private func openSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }
        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    let sourceType: UIImagePickerController.SourceType

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            picker.dismiss(animated: true)
        }
    }
}

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView(viewModel: ChatViewModel())
    }
}