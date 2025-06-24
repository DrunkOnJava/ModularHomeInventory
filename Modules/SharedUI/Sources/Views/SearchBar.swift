import SwiftUI

/// Search bar component
/// Swift 5.9 - No Swift 6 features
public struct SearchBar: View {
    @Binding var text: String
    let placeholder: String
    let onEditingChanged: ((Bool) -> Void)?
    let onCommit: (() -> Void)?
    
    @FocusState private var isFocused: Bool
    
    public init(
        text: Binding<String>,
        placeholder: String = "Search",
        onEditingChanged: ((Bool) -> Void)? = nil,
        onCommit: (() -> Void)? = nil
    ) {
        self._text = text
        self.placeholder = placeholder
        self.onEditingChanged = onEditingChanged
        self.onCommit = onCommit
    }
    
    public var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .focused($isFocused)
                .onSubmit {
                    onCommit?()
                }
                .onChange(of: isFocused) { newValue in
                    onEditingChanged?(newValue)
                }
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}