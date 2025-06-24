import SwiftUI
import Core
import SharedUI

/// View displaying search history with ability to re-run searches
/// Swift 5.9 - No Swift 6 features
struct SearchHistoryView: View {
    @StateObject private var viewModel: SearchHistoryViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingClearConfirmation = false
    
    init(
        searchHistoryRepository: any SearchHistoryRepository,
        onSelectEntry: @escaping (SearchHistoryEntry) -> Void
    ) {
        self._viewModel = StateObject(wrappedValue: SearchHistoryViewModel(
            searchHistoryRepository: searchHistoryRepository,
            onSelectEntry: onSelectEntry
        ))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if viewModel.entries.isEmpty {
                    emptyStateView
                } else {
                    historyContent
                }
            }
            .navigationTitle("Search History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                if !viewModel.entries.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Clear") {
                            showingClearConfirmation = true
                        }
                        .foregroundStyle(.red)
                    }
                }
            }
            .alert("Clear Search History", isPresented: $showingClearConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Clear All", role: .destructive) {
                    Task {
                        await viewModel.clearHistory()
                    }
                }
            } message: {
                Text("Are you sure you want to clear all search history? This cannot be undone.")
            }
        }
        .task {
            await viewModel.loadHistory()
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 60))
                .foregroundStyle(AppColors.textTertiary)
            
            VStack(spacing: AppSpacing.sm) {
                Text("No Search History")
                    .textStyle(.headlineMedium)
                    .foregroundStyle(AppColors.textSecondary)
                
                Text("Your recent searches will appear here")
                    .textStyle(.bodyMedium)
                    .foregroundStyle(AppColors.textTertiary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(AppSpacing.xl)
    }
    
    private var historyContent: some View {
        ScrollView {
            VStack(spacing: AppSpacing.xs) {
                ForEach(groupedEntries, id: \.key) { section in
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text(section.key)
                            .textStyle(.labelMedium)
                            .foregroundStyle(AppColors.textSecondary)
                            .padding(.horizontal)
                            .padding(.top, AppSpacing.md)
                        
                        VStack(spacing: 0) {
                            ForEach(section.entries) { entry in
                                SearchHistoryRow(
                                    entry: entry,
                                    onTap: {
                                        viewModel.selectEntry(entry)
                                        dismiss()
                                    },
                                    onDelete: {
                                        Task {
                                            await viewModel.deleteEntry(entry)
                                        }
                                    }
                                )
                                
                                if entry != section.entries.last {
                                    Divider()
                                        .padding(.leading, 60)
                                }
                            }
                        }
                        .background(AppColors.surface)
                        .cornerRadius(AppCornerRadius.medium)
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.bottom)
        }
        .background(AppColors.background)
    }
    
    private var groupedEntries: [(key: String, entries: [SearchHistoryEntry])] {
        let grouped = Dictionary(grouping: viewModel.entries) { entry in
            formatSectionDate(entry.timestamp)
        }
        
        return grouped.sorted { first, second in
            guard let firstDate = first.value.first?.timestamp,
                  let secondDate = second.value.first?.timestamp else {
                return false
            }
            return firstDate > secondDate
        }.map { (key: $0.key, entries: $0.value) }
    }
    
    private func formatSectionDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if let weekday = calendar.dateComponents([.weekday], from: date, to: now).weekday,
                  weekday < 7 {
            return date.formatted(.dateTime.weekday(.wide))
        } else {
            return date.formatted(.dateTime.month(.wide).day())
        }
    }
}

// MARK: - Search History Row
struct SearchHistoryRow: View {
    let entry: SearchHistoryEntry
    let onTap: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppSpacing.md) {
                Image(systemName: entry.searchType.icon)
                    .font(.title3)
                    .foregroundStyle(AppColors.primary)
                    .frame(width: 40, height: 40)
                    .background(AppColors.primaryMuted)
                    .cornerRadius(AppCornerRadius.small)
                
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text(entry.query)
                        .textStyle(.bodyMedium)
                        .foregroundStyle(AppColors.textPrimary)
                        .lineLimit(1)
                    
                    HStack(spacing: AppSpacing.sm) {
                        Text(entry.searchType.displayName)
                            .textStyle(.labelSmall)
                            .foregroundStyle(AppColors.textSecondary)
                        
                        if entry.resultCount > 0 {
                            Text("•")
                                .foregroundStyle(AppColors.textTertiary)
                            
                            Text("\(entry.resultCount) results")
                                .textStyle(.labelSmall)
                                .foregroundStyle(AppColors.textTertiary)
                        }
                    }
                }
                
                Spacer()
                
                Text(formatTime(entry.timestamp))
                    .textStyle(.labelSmall)
                    .foregroundStyle(AppColors.textTertiary)
            }
            .padding()
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - View Model
@MainActor
final class SearchHistoryViewModel: ObservableObject {
    @Published var entries: [SearchHistoryEntry] = []
    @Published var isLoading = false
    
    private let searchHistoryRepository: any SearchHistoryRepository
    private let onSelectEntry: (SearchHistoryEntry) -> Void
    
    init(
        searchHistoryRepository: any SearchHistoryRepository,
        onSelectEntry: @escaping (SearchHistoryEntry) -> Void
    ) {
        self.searchHistoryRepository = searchHistoryRepository
        self.onSelectEntry = onSelectEntry
    }
    
    func loadHistory() async {
        isLoading = true
        do {
            entries = try await searchHistoryRepository.fetchRecent(limit: 30)
        } catch {
            print("Failed to load search history: \(error)")
        }
        isLoading = false
    }
    
    func deleteEntry(_ entry: SearchHistoryEntry) async {
        do {
            try await searchHistoryRepository.delete(entry)
            await loadHistory()
        } catch {
            print("Failed to delete search history entry: \(error)")
        }
    }
    
    func clearHistory() async {
        do {
            try await searchHistoryRepository.deleteAll()
            entries.removeAll()
        } catch {
            print("Failed to clear search history: \(error)")
        }
    }
    
    func selectEntry(_ entry: SearchHistoryEntry) {
        onSelectEntry(entry)
    }
}