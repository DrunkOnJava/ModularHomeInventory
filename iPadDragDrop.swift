import SwiftUI
import UniformTypeIdentifiers
import Core
import SharedUI

/// Drag and drop support for iPad
/// Enables dragging items between collections, locations, and even between apps
struct iPadDragDrop {
    
    // MARK: - Item Drag Provider
    
    static func itemDragProvider(for item: Item) -> NSItemProvider {
        let provider = NSItemProvider()
        
        // Provide item as JSON
        if let data = try? JSONEncoder().encode(item) {
            provider.registerDataRepresentation(
                forTypeIdentifier: UTType.json.identifier,
                visibility: .all
            ) { completion in
                completion(data, nil)
                return nil
            }
        }
        
        // Provide item as plain text
        provider.registerItem(
            forTypeIdentifier: UTType.plainText.identifier,
            loadHandler: { completion in
                let text = """
                \(item.name)
                \(item.brand ?? "")
                \(item.model ?? "")
                Price: \(item.purchasePrice.map { String(format: "%.2f", $0) } ?? "N/A")
                """
                completion(text as NSItemProviderWriting?, nil)
                return nil
            }
        )
        
        // Provide first photo if available
        if let firstPhoto = item.photos.first,
           let url = URL(string: firstPhoto) {
            provider.registerFileRepresentation(
                forTypeIdentifier: UTType.image.identifier,
                fileOptions: [],
                visibility: .all
            ) { completion in
                // Download and provide image
                URLSession.shared.dataTask(with: url) { data, _, error in
                    if let data = data,
                       let tempURL = try? FileManager.default.url(
                        for: .itemReplacementDirectory,
                        in: .userDomainMask,
                        appropriateFor: nil,
                        create: true
                       ).appendingPathComponent("\(item.id).jpg") {
                        try? data.write(to: tempURL)
                        completion(tempURL, true, error)
                    } else {
                        completion(nil, false, error)
                    }
                }.resume()
                return Progress()
            }
        }
        
        return provider
    }
    
    // MARK: - Collection Drag Provider
    
    static func collectionDragProvider(for collection: Collection, items: [Item]) -> NSItemProvider {
        let provider = NSItemProvider()
        
        // Provide collection with items as JSON
        let exportData = CollectionExportData(
            collection: collection,
            items: items
        )
        
        if let data = try? JSONEncoder().encode(exportData) {
            provider.registerDataRepresentation(
                forTypeIdentifier: "com.modularhomeinventory.collection",
                visibility: .all
            ) { completion in
                completion(data, nil)
                return nil
            }
        }
        
        // Provide as CSV
        provider.registerFileRepresentation(
            forTypeIdentifier: UTType.commaSeparatedText.identifier,
            fileOptions: [],
            visibility: .all
        ) { completion in
            let csvData = generateCSV(for: items)
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("\(collection.name).csv")
            
            do {
                try csvData.write(to: tempURL)
                completion(tempURL, true, nil)
            } catch {
                completion(nil, false, error)
            }
            
            return Progress()
        }
        
        return provider
    }
    
    private static func generateCSV(for items: [Item]) -> Data {
        var csv = "Name,Brand,Model,Price,Category,Location\n"
        
        for item in items {
            csv += "\"\(item.name)\","
            csv += "\"\(item.brand ?? "")\","
            csv += "\"\(item.model ?? "")\","
            csv += "\(item.purchasePrice ?? 0),"
            csv += "\"\(item.category.displayName)\","
            csv += "\"\(item.location?.name ?? "")\"\n"
        }
        
        return csv.data(using: .utf8) ?? Data()
    }
}

// MARK: - Drag Support

struct DraggableItem: ViewModifier {
    let item: Item
    let preview: AnyView?
    
    func body(content: Content) -> some View {
        content
            .draggable(item) {
                preview ?? AnyView(DragPreviewView(item: item))
            }
    }
}

struct DraggableCollection: ViewModifier {
    let collection: Collection
    let items: [Item]
    
    func body(content: Content) -> some View {
        content
            .onDrag {
                iPadDragDrop.collectionDragProvider(for: collection, items: items)
            }
    }
}

// MARK: - Drop Support

struct DroppableLocation: ViewModifier {
    let location: Location
    let onDrop: ([Item]) -> Void
    @State private var isTargeted = false
    
    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                    .strokeBorder(
                        AppColors.primary,
                        lineWidth: isTargeted ? 3 : 0
                    )
                    .animation(.easeInOut(duration: 0.2), value: isTargeted)
            )
            .dropDestination(for: Item.self) { items, _ in
                onDrop(items)
                return true
            } isTargeted: {
                isTargeted = $0
            }
    }
}

struct DroppableCollection: ViewModifier {
    let collection: Collection
    let onDrop: ([Item]) -> Void
    @State private var isTargeted = false
    
    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.medium)
                    .strokeBorder(
                        AppColors.primary,
                        lineWidth: isTargeted ? 3 : 0
                    )
                    .animation(.easeInOut(duration: 0.2), value: isTargeted)
            )
            .dropDestination(for: Item.self) { items, _ in
                onDrop(items)
                return true
            } isTargeted: {
                isTargeted = $0
            }
    }
}

// MARK: - Drag Preview

struct DragPreviewView: View {
    let item: Item
    
    var body: some View {
        HStack {
            if let firstPhoto = item.photos.first,
               let url = URL(string: firstPhoto) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(AppColors.surface)
                }
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.small))
            } else {
                RoundedRectangle(cornerRadius: AppCornerRadius.small)
                    .fill(AppColors.surface)
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundStyle(AppColors.textTertiary)
                    )
            }
            
            VStack(alignment: .leading) {
                Text(item.name)
                    .textStyle(.bodyLarge)
                    .lineLimit(1)
                
                if let brand = item.brand {
                    Text(brand)
                        .textStyle(.labelMedium)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
            
            Spacer()
        }
        .padding()
        .frame(width: 300)
        .background(AppColors.surface)
        .cornerRadius(AppCornerRadius.medium)
        .shadow(radius: 8)
    }
}

// MARK: - Drop Delegate

struct ItemDropDelegate: DropDelegate {
    let destinationLocation: Location?
    let onDrop: ([Item]) -> Void
    @Binding var isTargeted: Bool
    
    func performDrop(info: DropInfo) -> Bool {
        guard info.hasItemsConforming(to: [.json]) else { return false }
        
        let providers = info.itemProviders(for: [.json])
        
        for provider in providers {
            provider.loadDataRepresentation(forTypeIdentifier: UTType.json.identifier) { data, _ in
                guard let data = data,
                      let item = try? JSONDecoder().decode(Item.self, from: data) else {
                    return
                }
                
                DispatchQueue.main.async {
                    onDrop([item])
                }
            }
        }
        
        return true
    }
    
    func dropEntered(info: DropInfo) {
        isTargeted = true
    }
    
    func dropExited(info: DropInfo) {
        isTargeted = false
    }
}

// MARK: - Export Data Models

struct CollectionExportData: Codable {
    let collection: Collection
    let items: [Item]
}

// MARK: - View Extensions

extension View {
    func draggableItem(_ item: Item, preview: AnyView? = nil) -> some View {
        self.modifier(DraggableItem(item: item, preview: preview))
    }
    
    func draggableCollection(_ collection: Collection, items: [Item]) -> some View {
        self.modifier(DraggableCollection(collection: collection, items: items))
    }
    
    func droppableLocation(_ location: Location, onDrop: @escaping ([Item]) -> Void) -> some View {
        self.modifier(DroppableLocation(location: location, onDrop: onDrop))
    }
    
    func droppableCollection(_ collection: Collection, onDrop: @escaping ([Item]) -> Void) -> some View {
        self.modifier(DroppableCollection(collection: collection, onDrop: onDrop))
    }
}

// MARK: - Drag & Drop Between Apps

struct InterAppDragDrop {
    
    /// Handle drops from other apps (e.g., Files, Photos)
    static func handleExternalDrop(providers: [NSItemProvider], completion: @escaping ([URL]) -> Void) {
        var urls: [URL] = []
        let group = DispatchGroup()
        
        for provider in providers {
            // Handle images
            if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                group.enter()
                provider.loadFileRepresentation(forTypeIdentifier: UTType.image.identifier) { url, error in
                    if let url = url {
                        // Copy to app's documents
                        let destinationURL = FileManager.default.temporaryDirectory
                            .appendingPathComponent(UUID().uuidString)
                            .appendingPathExtension(url.pathExtension)
                        
                        do {
                            try FileManager.default.copyItem(at: url, to: destinationURL)
                            urls.append(destinationURL)
                        } catch {
                            print("Failed to copy image: \(error)")
                        }
                    }
                    group.leave()
                }
            }
            
            // Handle CSV files
            if provider.hasItemConformingToTypeIdentifier(UTType.commaSeparatedText.identifier) {
                group.enter()
                provider.loadFileRepresentation(forTypeIdentifier: UTType.commaSeparatedText.identifier) { url, error in
                    if let url = url {
                        urls.append(url)
                    }
                    group.leave()
                }
            }
        }
        
        group.notify(queue: .main) {
            completion(urls)
        }
    }
}