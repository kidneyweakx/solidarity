//
//  ContactFiltersView.swift
//  airmeishi
//
//  Filter and sort options for contact list
//

import SwiftUI

struct ContactFiltersView: View {
    @Binding var selectedSource: ContactSource?
    @Binding var selectedVerificationStatus: VerificationStatus?
    @Binding var selectedTag: String?
    @Binding var sortOption: ContactSortOption
    
    @StateObject private var contactRepository = ContactRepository.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                // Sort Options
                Section("Sort By") {
                    ForEach(ContactSortOption.allCases) { option in
                        HStack {
                            Image(systemName: option.systemImageName)
                                .foregroundColor(.blue)
                                .frame(width: 20)
                            
                            Text(option.rawValue)
                            
                            Spacer()
                            
                            if sortOption == option {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            sortOption = option
                        }
                    }
                }
                
                // Source Filter
                Section("Filter by Source") {
                    HStack {
                        Image(systemName: "clear")
                            .foregroundColor(.gray)
                            .frame(width: 20)
                        
                        Text("All Sources")
                        
                        Spacer()
                        
                        if selectedSource == nil {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedSource = nil
                    }
                    
                    ForEach(ContactSource.allCases) { source in
                        HStack {
                            Image(systemName: source.systemImageName)
                                .foregroundColor(.blue)
                                .frame(width: 20)
                            
                            Text(source.displayName)
                            
                            Spacer()
                            
                            if selectedSource == source {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedSource = source
                        }
                    }
                }
                
                // Verification Status Filter
                Section("Filter by Verification") {
                    HStack {
                        Image(systemName: "clear")
                            .foregroundColor(.gray)
                            .frame(width: 20)
                        
                        Text("All Statuses")
                        
                        Spacer()
                        
                        if selectedVerificationStatus == nil {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedVerificationStatus = nil
                    }
                    
                    ForEach(VerificationStatus.allCases) { status in
                        HStack {
                            Image(systemName: status.systemImageName)
                                .foregroundColor(Color(status.color))
                                .frame(width: 20)
                            
                            Text(status.displayName)
                            
                            Spacer()
                            
                            if selectedVerificationStatus == status {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedVerificationStatus = status
                        }
                    }
                }
                
                // Tag Filter
                Section("Filter by Tag") {
                    HStack {
                        Image(systemName: "clear")
                            .foregroundColor(.gray)
                            .frame(width: 20)
                        
                        Text("All Tags")
                        
                        Spacer()
                        
                        if selectedTag == nil {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedTag = nil
                    }
                    
                    ForEach(availableTags, id: \.self) { tag in
                        HStack {
                            Image(systemName: "tag")
                                .foregroundColor(.blue)
                                .frame(width: 20)
                            
                            Text("#\(tag)")
                            
                            Spacer()
                            
                            if selectedTag == tag {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedTag = tag
                        }
                    }
                }
                
                // Clear All Filters
                Section {
                    Button("Clear All Filters") {
                        selectedSource = nil
                        selectedVerificationStatus = nil
                        selectedTag = nil
                    }
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .navigationTitle("Filters & Sort")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var availableTags: [String] {
        contactRepository.getAllTags()
    }
}

#Preview {
    ContactFiltersView(
        selectedSource: .constant(nil),
        selectedVerificationStatus: .constant(nil),
        selectedTag: .constant(nil),
        sortOption: .constant(.dateReceived)
    )
}