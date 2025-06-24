import SwiftUI
import Core

/// Swipeable photo gallery view
/// Swift 5.9 - No Swift 6 features
public struct PhotoGalleryView: View {
    let photos: [Photo]
    @Binding var selectedIndex: Int
    @Environment(\.dismiss) private var dismiss
    
    public init(photos: [Photo], selectedIndex: Binding<Int>) {
        self.photos = photos
        self._selectedIndex = selectedIndex
    }
    
    public var body: some View {
        NavigationView {
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                if photos.isEmpty {
                    emptyStateView
                } else {
                    TabView(selection: $selectedIndex) {
                        ForEach(Array(photos.enumerated()), id: \.element.id) { index, photo in
                            PhotoDetailView(photo: photo)
                                .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                    .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }
                
                ToolbarItem(placement: .principal) {
                    Text("\(selectedIndex + 1) of \(photos.count)")
                        .foregroundStyle(.white)
                        .textStyle(.bodyMedium)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: sharePhoto) {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        
                        Button(action: deletePhoto) {
                            Label("Delete", systemImage: "trash")
                                .foregroundStyle(.red)
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundStyle(.white)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 60))
                .foregroundStyle(.gray)
            
            Text("No Photos")
                .textStyle(.headlineLarge)
                .foregroundStyle(.white)
            
            Text("Add photos to see them here")
                .textStyle(.bodyMedium)
                .foregroundStyle(.gray)
        }
    }
    
    private func sharePhoto() {
        // To be implemented - share current photo
    }
    
    private func deletePhoto() {
        // To be implemented - delete current photo
    }
}

// MARK: - Photo Detail View
struct PhotoDetailView: View {
    let photo: Photo
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if let imageData = photo.imageData,
                   let image = UIImage(data: imageData) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    let delta = value / lastScale
                                    scale *= delta
                                    lastScale = value
                                }
                                .onEnded { _ in
                                    lastScale = 1.0
                                    withAnimation(.spring()) {
                                        scale = min(max(scale, 1), 3)
                                    }
                                }
                        )
                        .simultaneousGesture(
                            DragGesture()
                                .onChanged { value in
                                    offset = CGSize(
                                        width: lastOffset.width + value.translation.width,
                                        height: lastOffset.height + value.translation.height
                                    )
                                }
                                .onEnded { _ in
                                    lastOffset = offset
                                }
                        )
                        .onTapGesture(count: 2) {
                            withAnimation(.spring()) {
                                if scale > 1 {
                                    scale = 1
                                    offset = .zero
                                    lastOffset = .zero
                                } else {
                                    scale = 2
                                }
                            }
                        }
                } else {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                }
                
                // Caption overlay
                if let caption = photo.caption, !caption.isEmpty {
                    VStack {
                        Spacer()
                        Text(caption)
                            .textStyle(.bodyMedium)
                            .foregroundStyle(.white)
                            .padding(.horizontal, AppSpacing.md)
                            .padding(.vertical, AppSpacing.sm)
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(AppCornerRadius.small)
                            .padding(AppSpacing.lg)
                    }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}