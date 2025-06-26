//
//  CollaborativeListsView.swift
//  Core
//
//  Main view for displaying and managing collaborative lists
//

import SwiftUI

@available(iOS 15.0, *)
public struct CollaborativeListsView: View {
    @StateObject private var listService = CollaborativeListService()
    @State private var showingCreateList = false
    @State private var selectedList: CollaborativeListService.CollaborativeList?
    @State private var searchText = ""
    @State private var selectedFilter: ListFilter = .all
    @State private var showingArchivedLists = false
    
    private enum ListFilter: String, CaseIterable {
        case all = "All Lists"
        case active = "Active"
        case completed = "Completed"
        case shared = "Shared with Me"
        case owned = "My Lists"
        
        var icon: String {
            switch self {
            case .all: return "list.bullet"
            case .active: return "circle"
            case .completed: return "checkmark.circle"
            case .shared: return "person.2"
            case .owned: return "person"
            }
        }
    }
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            ZStack {
                if filteredLists.isEmpty && searchText.isEmpty {
                    emptyStateView
                } else {
                    listContent
                }
                
                if listService.syncStatus.isSyncing {
                    VStack {
                        Spacer()
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Syncing...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(8)
                        .background(Color(.systemBackground))
                        .cornerRadius(20)
                        .shadow(radius: 2)
                        .padding(.bottom)
                    }
                }
            }
            .navigationTitle("Lists")
            .searchable(text: $searchText, prompt: "Search lists")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Picker("Filter", selection: $selectedFilter) {
                            ForEach(ListFilter.allCases, id: \.self) { filter in
                                Label(filter.rawValue, systemImage: filter.icon)
                                    .tag(filter)
                            }
                        }
                        
                        Divider()
                        
                        Button(action: { showingArchivedLists.toggle() }) {
                            Label(
                                showingArchivedLists ? "Hide Archived" : "Show Archived",
                                systemImage: showingArchivedLists ? "archivebox.fill" : "archivebox"
                            )
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCreateList = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateList) {
                CreateListView(listService: listService)
            }
            .sheet(item: $selectedList) { list in
                NavigationView {
                    CollaborativeListDetailView(list: list, listService: listService)
                }
            }
            .refreshable {
                listService.syncLists()
            }
        }
    }
    
    // MARK: - List Content
    
    private var listContent: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Active Lists Section
                if !activeLists.isEmpty {
                    Section {
                        ForEach(activeLists) { list in
                            ListCard(list: list) {
                                selectedList = list
                            }
                            .transition(.scale.combined(with: .opacity))
                        }
                    } header: {
                        CollaborativeSectionHeader(title: "Active Lists", count: activeLists.count)
                    }
                }
                
                // Completed Lists Section
                if !completedLists.isEmpty {
                    Section {
                        ForEach(completedLists) { list in
                            ListCard(list: list) {
                                selectedList = list
                            }
                            .transition(.scale.combined(with: .opacity))
                        }
                    } header: {
                        CollaborativeSectionHeader(title: "Completed", count: completedLists.count)
                    }
                }
                
                // Recent Activity
                if !listService.activities.isEmpty {
                    Section {
                        RecentActivityCard(activities: Array(listService.activities.prefix(5)))
                    } header: {
                        CollaborativeSectionHeader(title: "Recent Activity", showCount: false)
                    }
                }
            }
            .padding()
        }
        .animation(.spring(), value: filteredLists)
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "list.bullet.rectangle")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("No Lists Yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Create collaborative lists to share with family and friends")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: { showingCreateList = true }) {
                Label("Create Your First List", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(25)
            }
            
            // Quick Start Templates
            VStack(spacing: 12) {
                Text("Quick Start")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    QuickStartTemplate(type: .shopping, action: createListFromTemplate)
                    QuickStartTemplate(type: .wishlist, action: createListFromTemplate)
                    QuickStartTemplate(type: .project, action: createListFromTemplate)
                    QuickStartTemplate(type: .moving, action: createListFromTemplate)
                }
            }
            .padding(.top, 40)
        }
        .padding()
    }
    
    // MARK: - Computed Properties
    
    private var filteredLists: [CollaborativeListService.CollaborativeList] {
        let lists = showingArchivedLists ? listService.lists : listService.lists.filter { !$0.isArchived }
        
        let filtered: [CollaborativeListService.CollaborativeList]
        switch selectedFilter {
        case .all:
            filtered = lists
        case .active:
            filtered = lists.filter { list in
                list.items.contains { !$0.isCompleted }
            }
        case .completed:
            filtered = lists.filter { list in
                !list.items.isEmpty && list.items.allSatisfy { $0.isCompleted }
            }
        case .shared:
            filtered = lists.filter { $0.createdBy != "current-user-id" }
        case .owned:
            filtered = lists.filter { $0.createdBy == "current-user-id" }
        }
        
        if searchText.isEmpty {
            return filtered
        } else {
            return filtered.filter { list in
                list.name.localizedCaseInsensitiveContains(searchText) ||
                list.items.contains { $0.title.localizedCaseInsensitiveContains(searchText) }
            }
        }
    }
    
    private var activeLists: [CollaborativeListService.CollaborativeList] {
        filteredLists.filter { list in
            list.items.contains { !$0.isCompleted }
        }
    }
    
    private var completedLists: [CollaborativeListService.CollaborativeList] {
        filteredLists.filter { list in
            !list.items.isEmpty && list.items.allSatisfy { $0.isCompleted }
        }
    }
    
    // MARK: - Actions
    
    private func createListFromTemplate(_ type: CollaborativeListService.CollaborativeList.ListType) {
        Task {
            try? await listService.createList(
                name: defaultName(for: type),
                type: type
            )
        }
    }
    
    private func defaultName(for type: CollaborativeListService.CollaborativeList.ListType) -> String {
        switch type {
        case .shopping:
            return "Shopping List"
        case .wishlist:
            return "Wish List"
        case .project:
            return "Project Items"
        case .moving:
            return "Moving Checklist"
        case .maintenance:
            return "Home Maintenance"
        case .custom:
            return "New List"
        }
    }
}

// MARK: - List Card

private struct ListCard: View {
    let list: CollaborativeListService.CollaborativeList
    let action: () -> Void
    
    private var progress: Double {
        guard !list.items.isEmpty else { return 0 }
        let completed = list.items.filter { $0.isCompleted }.count
        return Double(completed) / Double(list.items.count)
    }
    
    private var activeItemsCount: Int {
        list.items.filter { !$0.isCompleted }.count
    }
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Image(systemName: list.type.icon)
                        .font(.title3)
                        .foregroundColor(Color(list.type.color))
                        .frame(width: 40, height: 40)
                        .background(Color(list.type.color).opacity(0.2))
                        .cornerRadius(10)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(list.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        HStack(spacing: 4) {
                            if list.collaborators.count > 1 {
                                Image(systemName: "person.2.fill")
                                    .font(.caption2)
                                Text("\(list.collaborators.count)")
                                    .font(.caption)
                            }
                            
                            Text("•")
                                .foregroundColor(.secondary)
                            
                            Text(list.lastModified.formatted(.relative(presentation: .named)))
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if activeItemsCount > 0 {
                        Text("\(activeItemsCount)")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(Color.blue)
                            .clipShape(Circle())
                    }
                }
                
                // Progress
                if !list.items.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("\(list.items.filter { $0.isCompleted }.count) of \(list.items.count) completed")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("\(Int(progress * 100))%")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }
                        
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color(.systemGray5))
                                    .frame(height: 4)
                                
                                Rectangle()
                                    .fill(Color.green)
                                    .frame(width: geometry.size.width * progress, height: 4)
                            }
                            .cornerRadius(2)
                        }
                        .frame(height: 4)
                    }
                }
                
                // Recent Items Preview
                if !list.items.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(list.items.filter { !$0.isCompleted }.prefix(3)) { item in
                            HStack(spacing: 8) {
                                Image(systemName: "circle")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text(item.title)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                                
                                if let assignedTo = item.assignedTo {
                                    Text("@\(assignedTo)")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                                
                                Spacer()
                            }
                        }
                        
                        if activeItemsCount > 3 {
                            Text("+ \(activeItemsCount - 3) more items")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Section Header

private struct CollaborativeSectionHeader: View {
    let title: String
    var count: Int? = nil
    var showCount: Bool = true
    
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            if showCount, let count = count {
                Text("(\(count))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 4)
        .padding(.bottom, 8)
    }
}

// MARK: - Quick Start Template

private struct QuickStartTemplate: View {
    let type: CollaborativeListService.CollaborativeList.ListType
    let action: (CollaborativeListService.CollaborativeList.ListType) -> Void
    
    var body: some View {
        Button(action: { action(type) }) {
            VStack(spacing: 8) {
                Image(systemName: type.icon)
                    .font(.title2)
                    .foregroundColor(Color(type.color))
                    .frame(width: 50, height: 50)
                    .background(Color(type.color).opacity(0.2))
                    .cornerRadius(12)
                
                Text(type.rawValue)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color(.tertiarySystemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Recent Activity Card

private struct RecentActivityCard: View {
    let activities: [CollaborativeListService.ListActivity]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(activities) { activity in
                HStack(spacing: 12) {
                    Image(systemName: activityIcon(for: activity.action))
                        .font(.caption)
                        .foregroundColor(activityColor(for: activity.action))
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(activityText(for: activity))
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        
                        Text(activity.timestamp.formatted(.relative(presentation: .named)))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private func activityIcon(for action: CollaborativeListService.ListActivity.ActivityAction) -> String {
        switch action {
        case .created: return "plus.circle"
        case .addedItem: return "plus"
        case .completedItem: return "checkmark.circle"
        case .uncompletedItem: return "circle"
        case .editedItem: return "pencil"
        case .deletedItem: return "trash"
        case .assignedItem: return "person.badge.plus"
        case .invitedUser: return "person.badge.plus"
        case .joinedList: return "person.2"
        case .leftList: return "person.badge.minus"
        case .archivedList: return "archivebox"
        }
    }
    
    private func activityColor(for action: CollaborativeListService.ListActivity.ActivityAction) -> Color {
        switch action {
        case .created, .addedItem, .joinedList:
            return .green
        case .completedItem:
            return .blue
        case .deletedItem, .leftList:
            return .red
        case .archivedList:
            return .orange
        default:
            return .secondary
        }
    }
    
    private func activityText(for activity: CollaborativeListService.ListActivity) -> String {
        var text = "\(activity.userName) \(activity.action.rawValue)"
        if let itemTitle = activity.itemTitle {
            text += " \"\(itemTitle)\""
        }
        return text
    }
}