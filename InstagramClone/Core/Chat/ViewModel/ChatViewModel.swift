//
//  ChatsViewModel.swift
//  InstagramClone
//
//  Created by Mark Cherenov on 29.11.2023.
//

import Foundation
import Combine
import PhotosUI
import SwiftUI

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messageText = ""
    @Published var messages = [Message]()
    @Published var recentMessages = [Message]()
    
    @Published var selectedImage: PhotosPickerItem? {
        didSet {
            Task {
                await loadImage(fromItem: selectedImage)
            }
        }
    }
    
    @Published var postImage: Image?
    @Published var isLoading = false
    private var uiImage: UIImage?
    
    private var cancellables = Set<AnyCancellable>()
    
    let service: ChatService
    
    init(user: User) {
        self.service = ChatService(chatPartner: user)
        observeMessages()
    }
    
    func observeMessages() {
        service.observeMessages() { messages in
            self.messages.append(contentsOf: messages)
        }
    }
    
    @MainActor
    func sendMessage() async throws {
        do {
            self.isLoading = true
            
            let uiImage = uiImage
            let imageUrl = try await ImageUploader.uploadImage(image: uiImage ?? UIImage())
            
            service.sendMessage(messageText, imageUrl: imageUrl)
            messageText = ""
            self.selectedImage = nil
            self.uiImage = nil
            self.postImage = nil
            self.isLoading = false
        } catch {
            print("Error")
        }

    }
    
    func loadImage(fromItem item: PhotosPickerItem?) async {
        self.isLoading = true

        guard let item = item else { return }
        
        guard let data = try? await item.loadTransferable(type: Data.self) else { return }
        guard let uiImage = UIImage(data: data) else { return }
        self.uiImage = uiImage
        self.postImage = Image(uiImage: uiImage)
        self.isLoading = false

    }
    
}
