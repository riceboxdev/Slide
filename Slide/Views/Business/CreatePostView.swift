import SwiftUI
import PhotosUI

// MARK: - Create Post View

struct CreatePostView: View {
    @StateObject private var viewModel = CreatePostViewModel()
    @Environment(\.dismiss) private var dismiss
    
    let business: SlideBusiness
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Business Info Header
                    BusinessHeaderView(business: business)
                    
                    // Post Content Form
                    PostFormView(viewModel: viewModel)
                    
                    // Media Section
                    MediaSectionView(viewModel: viewModel)
                    
                    // Post Settings
                    PostSettingsView(viewModel: viewModel)
                    
                    // Action Buttons
                    ActionButtonsView(viewModel: viewModel, business: business, dismiss: dismiss)
                }
                .padding()
            }
            .navigationTitle("Create Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") { }
            } message: {
                Text(viewModel.errorMessage)
            }
            .overlay {
                if viewModel.isLoading {
                    LoadingOverlay()
                }
            }
        }
    }
}

// MARK: - Business Header View

struct BusinessHeaderView: View {
    let business: SlideBusiness
    
    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: business.profilePhoto ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .overlay {
                        Image(systemName: "building.2")
                            .foregroundColor(.gray)
                    }
            }
            .frame(width: 50, height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(business.displayName?.text ?? "Business")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(business.shortFormattedAddress ?? "")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Post Form View

struct PostFormView: View {
    @ObservedObject var viewModel: CreatePostViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            // Post Type Selector
            VStack(alignment: .leading, spacing: 8) {
                Text("Post Type")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(PostType.allCases, id: \.self) { type in
                            PostTypeChip(
                                type: type,
                                isSelected: viewModel.selectedType == type
                            ) {
                                viewModel.selectedType = type
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
            
            // Title Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Title")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                TextField("Enter post title...", text: $viewModel.title)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($viewModel.titleFocused)
            }
            
            // Content Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Content")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                TextEditor(text: $viewModel.content)
                    .frame(minHeight: 120)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .focused($viewModel.contentFocused)
                
                Text("\(viewModel.content.count) characters")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            
            // Tags Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Tags")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                TagInputView(tags: $viewModel.tags)
            }
        }
    }
}

// MARK: - Post Type Chip

struct PostTypeChip: View {
    let type: PostType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: iconForType(type))
                    .font(.caption)
                
                Text(type.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.accentColor : Color(.systemGray5))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
    }
    
    private func iconForType(_ type: PostType) -> String {
        switch type {
        case .announcement: return "megaphone"
        case .promotion: return "tag"
        case .event: return "calendar"
        case .update: return "info.circle"
        case .news: return "newspaper"
        }
    }
}

// MARK: - Tag Input View

struct TagInputView: View {
    @Binding var tags: [String]
    @State private var newTag = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Tag chips
            if !tags.isEmpty {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                    ForEach(tags, id: \.self) { tag in
                        TagChipView(tag: tag) {
                            tags.removeAll { $0 == tag }
                        }
                    }
                }
            }
            
            // Add new tag
            HStack {
                TextField("Add tag...", text: $newTag)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onSubmit {
                        addTag()
                    }
                
                Button("Add") {
                    addTag()
                }
                .disabled(newTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }
    
    private func addTag() {
        let trimmedTag = newTag.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !trimmedTag.isEmpty && !tags.contains(trimmedTag) {
            tags.append(trimmedTag)
            newTag = ""
        }
    }
}

// MARK: - Tag Chip View

struct TagChipView: View {
    let tag: String
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text("#\(tag)")
                .font(.caption)
                .fontWeight(.medium)
            
            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .font(.caption2)
                    .fontWeight(.bold)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.accentColor.opacity(0.1))
        .foregroundColor(.accentColor)
        .cornerRadius(12)
    }
}

// MARK: - Media Section View

struct MediaSectionView: View {
    @ObservedObject var viewModel: CreatePostViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Media")
                .font(.headline)
                .foregroundColor(.primary)
            
            // Selected images preview
            if !viewModel.selectedImages.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(viewModel.selectedImages, id: \.self) { item in
                            MediaPreviewView(item: item) {
                                viewModel.removeImage(item)
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
            
            // Add media buttons
            HStack(spacing: 16) {
                PhotosPicker(
                    selection: $viewModel.selectedImages,
                    maxSelectionCount: 5,
                    matching: .images
                ) {
                    Label("Add Photos", systemImage: "photo")
                        .foregroundColor(.accentColor)
                }
                
                Spacer()
                
                if !viewModel.selectedImages.isEmpty {
                    Text("\(viewModel.selectedImages.count)/5")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Media Preview View

struct MediaPreviewView: View {
    let item: PhotosPickerItem
    let onDelete: () -> Void
    @State private var image: Image?
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Group {
                if let image = image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .overlay {
                            ProgressView()
                        }
                }
            }
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.white)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
            }
            .offset(x: 4, y: -4)
        }
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        item.loadTransferable(type: Data.self) { result in
            switch result {
            case .success(let data):
                if let data = data, let uiImage = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self.image = Image(uiImage: uiImage)
                    }
                }
            case .failure(_):
                break
            }
        }
    }
}

// MARK: - Post Settings View

struct PostSettingsView: View {
    @ObservedObject var viewModel: CreatePostViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Post Settings")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                // Schedule toggle
                Toggle("Schedule for later", isOn: $viewModel.isScheduled)
                    .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                
                // Date picker for scheduled posts
                if viewModel.isScheduled {
                    DatePicker(
                        "Publish Date",
                        selection: $viewModel.scheduledDate,
                        in: Date()...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(CompactDatePickerStyle())
                }
                
                // Additional settings
                Toggle("Allow comments", isOn: $viewModel.allowComments)
                    .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                
                Toggle("Notify followers", isOn: $viewModel.notifyFollowers)
                    .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                
                Toggle("Feature this post", isOn: $viewModel.featuredPost)
                    .toggleStyle(SwitchToggleStyle(tint: .accentColor))
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Action Buttons View

struct ActionButtonsView: View {
    @ObservedObject var viewModel: CreatePostViewModel
    let business: SlideBusiness
    let dismiss: DismissAction
    
    var body: some View {
        VStack(spacing: 12) {
            // Primary action button
            Button(action: {
                Task {
                    await viewModel.createPost(for: business, dismiss: dismiss)
                }
            }) {
                HStack {
                    if viewModel.isScheduled {
                        Image(systemName: "clock")
                    } else {
                        Image(systemName: "paperplane")
                    }
                    
                    Text(viewModel.isScheduled ? "Schedule Post" : "Publish Now")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(!viewModel.isValidPost)
            
            // Save as draft button
            Button("Save as Draft") {
                Task {
                    await viewModel.saveDraft(for: business, dismiss: dismiss)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemGray5))
            .foregroundColor(.primary)
            .cornerRadius(12)
            .disabled(!viewModel.canSaveDraft)
        }
    }
}

// MARK: - Loading Overlay

struct LoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.2)
                    .tint(.white)
                
                Text("Creating post...")
                    .foregroundColor(.white)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(24)
            .background(Color.black.opacity(0.8))
            .cornerRadius(16)
        }
    }
}

// MARK: - Create Post View Model

@MainActor
class CreatePostViewModel: ObservableObject {
    @Published var selectedType: PostType = .announcement
    @Published var title = ""
    @Published var content = ""
    @Published var tags: [String] = []
    @Published var selectedImages: [PhotosPickerItem] = []
    @Published var isScheduled = false
    @Published var scheduledDate = Date().addingTimeInterval(3600) // 1 hour from now
    @Published var allowComments = true
    @Published var notifyFollowers = true
    @Published var featuredPost = false
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    
    @FocusState var titleFocused: Bool
    @FocusState var contentFocused: Bool
    
    private let postService: BusinessPostService
    
    init(postService: BusinessPostService = DefaultBusinessPostService()) {
        self.postService = postService
    }
    
    var isValidPost: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var canSaveDraft: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    func removeImage(_ item: PhotosPickerItem) {
        selectedImages.removeAll { $0 == item }
    }
    
    func createPost(for business: SlideBusiness, dismiss: DismissAction) async {
        guard isValidPost else { return }
        
        isLoading = true
        
        do {
            let postId = try await postService.createPost(
                for: business,
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                content: content.trimmingCharacters(in: .whitespacesAndNewlines),
                type: selectedType
            )
            
            // If scheduled, schedule the post
            if isScheduled {
                try await postService.schedulePost(id: postId, for: scheduledDate)
            } else {
                // Publish immediately
                try await postService.publishPost(id: postId)
            }
            
            dismiss()
            
        } catch {
            showError(error.localizedDescription)
        }
        
        isLoading = false
    }
    
    func saveDraft(for business: SlideBusiness, dismiss: DismissAction) async {
        guard canSaveDraft else { return }
        
        isLoading = true
        
        do {
            _ = try await postService.createPost(
                for: business,
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                content: content.trimmingCharacters(in: .whitespacesAndNewlines),
                type: selectedType
            )
            
            dismiss()
            
        } catch {
            showError(error.localizedDescription)
        }
        
        isLoading = false
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showError = true
    }
}

// MARK: - Preview

#Preview {
    CreatePostView(business: SlideBusiness(
        id: "123",
        displayName: DisplayName(text: "Sample Restaurant"),
        shortFormattedAddress: "123 Main St, City",
        profilePhoto: nil,
        createdAt: Timestamp(),
        updatedAt: Timestamp()
    ))
}