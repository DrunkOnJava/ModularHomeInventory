import SwiftUI
import Core

/// Grid view for displaying photo thumbnails
/// Swift 5.9 - No Swift 6 features
public struct PhotoGridView: View {
    let photos: [Photo]
    let columns: Int
    let spacing: CGFloat
    let onPhotoTap: (Int) -> Void
    let onAddPhoto: () -> Void
    
    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: spacing), count: columns)
    }
    
    public init(
        photos: [Photo],
        columns: Int = 3,
        spacing: CGFloat = 2,
        onPhotoTap: @escaping (Int) -> Void,
        onAddPhoto: @escaping () -> Void
    ) {
        self.photos = photos
        self.columns = columns
        self.spacing = spacing
        self.onPhotoTap = onPhotoTap
        self.onAddPhoto = onAddPhoto
    }
    
    public var body: some View {
        ScrollView {
            LazyVGrid(columns: gridColumns, spacing: spacing) {
                ForEach(Array(photos.enumerated()), id: \.element.id) { index, photo in
                    PhotoThumbnailView(photo: photo)
                        .onTapGesture {
                            onPhotoTap(index)
                        }
                }
                
                // Add photo button
                AddPhotoButton(action: onAddPhoto)
            }
            .padding(spacing)
        }
    }
}

// MARK: - Photo Thumbnail View
struct PhotoThumbnailView: View {
    let photo: Photo
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if let image = photo.image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.width)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(AppColors.surface)
                        .overlay {
                            ProgressView()
                                .tint(AppColors.textTertiary)
                        }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.width)
            .cornerRadius(AppCornerRadius.small)
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

// MARK: - Add Photo Button
struct AddPhotoButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            GeometryReader { geometry in
                VStack(spacing: AppSpacing.xs) {
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .medium))
                    Text("Add Photo")
                        .textStyle(.labelSmall)
                }
                .foregroundStyle(AppColors.textSecondary)
                .frame(width: geometry.size.width, height: geometry.size.width)
                .background(AppColors.surface)
                .overlay {
                    RoundedRectangle(cornerRadius: AppCornerRadius.small)
                        .strokeBorder(AppColors.border, style: StrokeStyle(lineWidth: 2, dash: [5]))
                }
            }
            .aspectRatio(1, contentMode: .fit)
        }
    }
}