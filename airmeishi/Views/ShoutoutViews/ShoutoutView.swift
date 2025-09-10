//
//  ShoutoutView.swift
//  airmeishi
//
//  3D chart view for shoutout discovery and user search
//

import SwiftUI

struct ShoutoutView: View {
    @StateObject private var chartService = ShoutoutChartService.shared
    @State private var showingFilters = false
    @State private var showingUserDetail = false
    @State private var selectedUser: ShoutoutUser?
    @State private var searchText = ""
    @State private var showingCreateShoutout = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Dark background
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header with search and filters
                    headerSection
                    
                    // 3D Chart Visualization
                    chartVisualization
                    
                    // Action buttons
                    actionButtons
                }
            }
            .navigationTitle("Shoutout")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Filters") {
                        showingFilters.toggle()
                    }
                    .foregroundColor(.white)
                }
            }
            .sheet(isPresented: $showingFilters) {
                ShoutoutFiltersView()
            }
            .sheet(isPresented: $showingUserDetail) {
                if let user = selectedUser {
                    ShoutoutDetailView(user: user)
                }
            }
            .sheet(isPresented: $showingCreateShoutout) {
                CreateShoutoutView()
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Search users...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .foregroundColor(.white)
                    .onChange(of: searchText) { _, newValue in
                        chartService.searchUsers(query: newValue)
                    }
                
                if !searchText.isEmpty {
                    Button("Clear") {
                        searchText = ""
                        chartService.searchUsers(query: "")
                    }
                    .font(.caption)
                    .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(12)
            .padding(.horizontal)
            
            // Community Stats
            communityStatsView
        }
        .padding(.vertical)
    }
    
    private var communityStatsView: some View {
        HStack(spacing: 20) {
            VStack {
                Image(systemName: "person.2")
                    .font(.title2)
                    .foregroundColor(.cyan)
                
                Text("\(chartService.filteredData.count)")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("Users")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            VStack {
                Image(systemName: "chart.scatter.3d")
                    .font(.title2)
                    .foregroundColor(.orange)
                
                Text("3D Map")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("Active")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            VStack {
                Image(systemName: "bolt.fill")
                    .font(.title2)
                    .foregroundColor(.yellow)
                
                Text("Shoutouts")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("Ready")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Chart Visualization
    
    private var chartVisualization: some View {
        GeometryReader { geometry in
            ZStack {
                // 3D Chart Background
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                    )
                
                // 3D Data Points
                ForEach(chartService.filteredData) { dataPoint in
                    FloatingDataPoint(
                        dataPoint: dataPoint,
                        containerSize: geometry.size
                    ) {
                        selectedUser = dataPoint.user
                        showingUserDetail = true
                    }
                }
                
                // Axis Labels
                axisLabels
            }
            .padding()
        }
    }
    
    private var axisLabels: some View {
        VStack {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("(X) Events")
                        .font(.caption)
                        .foregroundColor(.cyan)
                    Text("Activity Level")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("(Y) Type")
                        .font(.caption)
                        .foregroundColor(.orange)
                    Text("Professional")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("(Z) Character")
                        .font(.caption)
                        .foregroundColor(.green)
                    Text("Personality")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
        }
        .padding()
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        VStack(spacing: 16) {
            // Pro Tips
            proTipsSection
            
            // Main Action Button
            Button(action: {
                showingCreateShoutout = true
            }) {
                HStack {
                    Image(systemName: "bolt.fill")
                        .font(.title2)
                    
                    Text("Make my own shoutout!")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [Color.blue, Color.purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
            .padding(.horizontal)
        }
        .padding(.bottom)
    }
    
    private var proTipsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("How to step up your game:")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("1. Create shoutouts →")
                    .font(.body)
                    .foregroundColor(.gray)
                
                Text("2. Start matching →")
                    .font(.body)
                    .foregroundColor(.gray)
                
                Text("3. Checkout events →")
                    .font(.body)
                    .foregroundColor(.gray)
            }
            
            Text("Most importantly: you need to have FUN <3")
                .font(.caption)
                .foregroundColor(.pink)
                .padding(.top, 4)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// MARK: - Floating Data Point

struct FloatingDataPoint: View {
    let dataPoint: ChartDataPoint
    let containerSize: CGSize
    let onTap: () -> Void
    
    @State private var isAnimating = false
    @State private var dragOffset = CGSize.zero
    
    private var position: CGPoint {
        let x = CGFloat(dataPoint.x) * (containerSize.width - 100) + 50
        let y = CGFloat(1.0 - dataPoint.y) * (containerSize.height - 100) + 50
        return CGPoint(x: x + dragOffset.width, y: y + dragOffset.height)
    }
    
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                // User Avatar
                AsyncImage(url: dataPoint.user.profileImageURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(dataPoint.color.gradient)
                        .overlay {
                            Text(dataPoint.user.initials)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(dataPoint.color, lineWidth: 2)
                )
                .shadow(color: dataPoint.color.opacity(0.5), radius: 4, x: 0, y: 2)
                
                // User Name
                Text(dataPoint.user.name)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .frame(maxWidth: 60)
            }
        }
        .position(position)
        .scaleEffect(isAnimating ? 1.1 : 1.0)
        .scaleEffect(1.0 + CGFloat(dataPoint.z) * 0.1)
        .animation(
            .easeInOut(duration: 2.0).repeatForever(autoreverses: true),
            value: isAnimating
        )
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffset = value.translation
                }
                .onEnded { _ in
                    withAnimation(.spring()) {
                        dragOffset = .zero
                    }
                }
        )
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Create Shoutout View

struct CreateShoutoutView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var recipient: ShoutoutUser?
    @State private var message = ""
    @State private var tipAmount = ""
    @State private var showingUserPicker = false
    
    init(selectedUser: ShoutoutUser? = nil) {
        self._recipient = State(initialValue: selectedUser)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Recipient Selection
                Button(action: {
                    showingUserPicker = true
                }) {
                    HStack {
                        if let recipient = recipient {
                            AsyncImage(url: recipient.profileImageURL) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Circle()
                                    .fill(Color.blue.gradient)
                                    .overlay {
                                        Text(recipient.initials)
                                            .font(.headline)
                                            .foregroundColor(.white)
                                    }
                            }
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                            
                            VStack(alignment: .leading) {
                                Text(recipient.name)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text(recipient.company)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            Image(systemName: "person.circle")
                                .font(.title)
                                .foregroundColor(.blue)
                            
                            Text("Select Recipient")
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGroupedBackground))
                    .cornerRadius(12)
                }
                
                // Message
                VStack(alignment: .leading, spacing: 8) {
                    Text("Message")
                        .font(.headline)
                    
                    TextField("You rockkkkk", text: $message, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(3...6)
                }
                
                // Tip Amount
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tip Amount")
                        .font(.headline)
                    
                    HStack {
                        TextField("100", text: $tipAmount)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                        
                        Text("WAMO")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Send Button
                Button(action: sendShoutout) {
                    Text("Send Shoutout")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .disabled(recipient == nil || message.isEmpty || tipAmount.isEmpty)
            }
            .padding()
            .navigationTitle("Create Shoutout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingUserPicker) {
                UserPickerView(selectedUser: $recipient)
            }
        }
    }
    
    private func sendShoutout() {
        // TODO: Implement shoutout sending logic
        dismiss()
    }
}

// MARK: - User Picker View

struct UserPickerView: View {
    @Binding var selectedUser: ShoutoutUser?
    @Environment(\.dismiss) private var dismiss
    @StateObject private var chartService = ShoutoutChartService.shared
    
    var body: some View {
        NavigationView {
            List(chartService.users) { user in
                Button(action: {
                    selectedUser = user
                    dismiss()
                }) {
                    HStack {
                        AsyncImage(url: user.profileImageURL) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Circle()
                                .fill(Color.blue.gradient)
                                .overlay {
                                    Text(user.initials)
                                        .font(.headline)
                                        .foregroundColor(.white)
                                }
                        }
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                        
                        VStack(alignment: .leading) {
                            Text(user.name)
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text(user.company)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
            .navigationTitle("Select User")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ShoutoutView()
}
