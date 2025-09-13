//
//  ShoutoutView.swift
//  airmeishi
//
//  Modern lightning-themed gallery view for shoutout discovery and business card management
//

import SwiftUI

struct ShoutoutView: View {
    @StateObject private var chartService = ShoutoutChartService.shared
    @State private var showingFilters = false
    @State private var showingUserDetail = false
    @State private var selectedUser: ShoutoutUser?
    @State private var searchText = ""
    @State private var showingCreateShoutout = false
    @State private var selectedContact: Contact?
    @State private var isLightningAnimating = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Dark gradient background with lightning effect
                LinearGradient(
                    colors: [
                        Color.black,
                        Color.blue.opacity(0.1),
                        Color.purple.opacity(0.05),
                        Color.black
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Lightning header with search
                    lightningHeader
                    
                    // Business card gallery
                    cardGallery
                    
                    // Floating lightning action button
                    lightningActionButton
                }
            }
            .navigationTitle("Shoutout")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingFilters.toggle() }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundColor(.white)
                            .font(.title2)
                    }
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
                CreateShoutoutView(selectedUser: selectedUser)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            startLightningAnimation()
        }
    }
    
    // MARK: - Lightning Header
    
    private var lightningHeader: some View {
        VStack(spacing: 16) {
            // Animated lightning title
            HStack {
                Image(systemName: "bolt.fill")
                    .foregroundColor(.yellow)
                    .font(.title)
                    .scaleEffect(isLightningAnimating ? 1.2 : 1.0)
                    .animation(
                        .easeInOut(duration: 0.5).repeatForever(autoreverses: true),
                        value: isLightningAnimating
                    )
                
                Text("Lightning Gallery")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                // Live count with pulsing effect
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                        .scaleEffect(isLightningAnimating ? 1.3 : 1.0)
                        .animation(
                            .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                            value: isLightningAnimating
                        )
                    
                    Text("\(chartService.filteredData.count) cards")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal)
            
            // Search bar with lightning accent
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.yellow)
                
                TextField("Search business cards...", text: $searchText)
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
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                LinearGradient(
                                    colors: [.yellow.opacity(0.3), .clear, .yellow.opacity(0.3)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
    
    // MARK: - Card Gallery
    
    private var cardGallery: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 16) {
                ForEach(chartService.filteredData) { dataPoint in
                    LightningCardView(
                        dataPoint: dataPoint,
                        isLightningAnimating: isLightningAnimating
                    ) {
                        selectedUser = dataPoint.user
                        showingUserDetail = true
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 100) // Space for floating button
        }
    }
    
    // MARK: - Floating Lightning Action Button
    
    private var lightningActionButton: some View {
        VStack {
            Spacer()
            
            HStack {
                Spacer()
                
                Button(action: { showingCreateShoutout = true }) {
                    ZStack {
                        // Lightning bolt background
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.yellow, .orange, .red],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 60, height: 60)
                            .shadow(color: .yellow.opacity(0.5), radius: 10, x: 0, y: 0)
                        
                        // Lightning icon
                        Image(systemName: "bolt.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .scaleEffect(isLightningAnimating ? 1.3 : 1.0)
                            .animation(
                                .easeInOut(duration: 0.3).repeatForever(autoreverses: true),
                                value: isLightningAnimating
                            )
                    }
                }
                .padding(.trailing, 20)
                .padding(.bottom, 30)
            }
        }
    }
    
    // MARK: - Animation Control
    
    private func startLightningAnimation() {
        isLightningAnimating = true
    }
}

// MARK: - Lightning Card View

struct LightningCardView: View {
    let dataPoint: ChartDataPoint
    let isLightningAnimating: Bool
    let onTap: () -> Void
    
    @State private var cardOffset: CGFloat = 0
    @State private var isHovering = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // Card header with lightning effect
                HStack {
                    // Profile image with lightning border
                    AsyncImage(url: dataPoint.user.profileImageURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [dataPoint.color, dataPoint.color.opacity(0.6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay {
                                Text(dataPoint.user.initials)
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                    }
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(
                                isLightningAnimating ? Color.yellow : dataPoint.color,
                                lineWidth: isLightningAnimating ? 3 : 2
                            )
                            .scaleEffect(isLightningAnimating ? 1.1 : 1.0)
                            .animation(
                                .easeInOut(duration: 0.5).repeatForever(autoreverses: true),
                                value: isLightningAnimating
                            )
                    )
                    .shadow(
                        color: isLightningAnimating ? .yellow.opacity(0.6) : dataPoint.color.opacity(0.5),
                        radius: isLightningAnimating ? 8 : 4,
                        x: 0, y: 2
                    )
                    
                    Spacer()
                    
                    // Lightning bolt indicator
                    Image(systemName: "bolt.fill")
                        .foregroundColor(isLightningAnimating ? .yellow : .gray)
                        .font(.caption)
                        .scaleEffect(isLightningAnimating ? 1.2 : 1.0)
                        .animation(
                            .easeInOut(duration: 0.3).repeatForever(autoreverses: true),
                            value: isLightningAnimating
                        )
                }
                
                // User info
                VStack(alignment: .leading, spacing: 4) {
                    Text(dataPoint.user.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    if !dataPoint.user.company.isEmpty {
                        Text(dataPoint.user.company)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                    
                    if !dataPoint.user.title.isEmpty {
                        Text(dataPoint.user.title)
                            .font(.caption2)
                            .foregroundColor(.gray.opacity(0.8))
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Verification status with lightning effect
                HStack {
                    Image(systemName: dataPoint.user.verificationStatus.systemImageName)
                        .foregroundColor(verificationColor)
                        .font(.caption)
                    
                    Text(dataPoint.user.verificationStatus.displayName)
                        .font(.caption2)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    // Score indicator
                    HStack(spacing: 2) {
                        ForEach(0..<3) { index in
                            Circle()
                                .fill(index < Int(dataPoint.user.eventScore * 3) ? Color.yellow : Color.gray.opacity(0.3))
                                .frame(width: 4, height: 4)
                        }
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isLightningAnimating ? Color.yellow.opacity(0.3) : Color.white.opacity(0.1),
                                lineWidth: 1
                            )
                    )
            )
            .scaleEffect(isHovering ? 1.05 : 1.0)
            .offset(y: cardOffset)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovering)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: cardOffset)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            isHovering = hovering
        }
        .onTapGesture {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                cardOffset = -5
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    cardOffset = 0
                }
            }
            onTap()
        }
    }
    
    private var verificationColor: Color {
        switch dataPoint.user.verificationStatus {
        case .verified: return .green
        case .pending: return .orange
        case .unverified: return .blue
        case .failed: return .red
        }
    }
}

// MARK: - Create Shoutout View

struct CreateShoutoutView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var recipient: ShoutoutUser?
    @State private var message = ""
    @State private var showingUserPicker = false
    @State private var isLightningAnimating = false
    @State private var showingSuccess = false
    
    init(selectedUser: ShoutoutUser? = nil) {
        self._recipient = State(initialValue: selectedUser)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Dark background with lightning effect
                LinearGradient(
                    colors: [
                        Color.black,
                        Color.purple.opacity(0.1),
                        Color.blue.opacity(0.05),
                        Color.black
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Lightning header
                    lightningHeader
                    
                    // Recipient Selection
                    recipientSelection
                    
                    // Message Input
                    messageInput
                    
                    Spacer()
                    
                    // Send Button with lightning effect
                    lightningSendButton
                }
                .padding()
            }
            .navigationTitle("Lightning Shoutout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .sheet(isPresented: $showingUserPicker) {
                UserPickerView(selectedUser: $recipient)
            }
            .alert("Shoutout Sent!", isPresented: $showingSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your lightning shoutout has been delivered! ⚡")
            }
            .onAppear {
                startLightningAnimation()
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Lightning Header
    
    private var lightningHeader: some View {
        HStack {
            Image(systemName: "bolt.fill")
                .foregroundColor(.yellow)
                .font(.title)
                .scaleEffect(isLightningAnimating ? 1.3 : 1.0)
                .animation(
                    .easeInOut(duration: 0.5).repeatForever(autoreverses: true),
                    value: isLightningAnimating
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Send Lightning Shoutout")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Power up someone's day ⚡")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Recipient Selection
    
    private var recipientSelection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recipient")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "person.circle.fill")
                    .foregroundColor(.yellow)
                    .font(.title3)
            }
            
            Button(action: { showingUserPicker = true }) {
                HStack {
                    if let recipient = recipient {
                        AsyncImage(url: recipient.profileImageURL) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .overlay {
                                    Text(recipient.initials)
                                        .font(.headline)
                                        .foregroundColor(.white)
                                }
                        }
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.yellow, lineWidth: 2)
                                .scaleEffect(isLightningAnimating ? 1.1 : 1.0)
                                .animation(
                                    .easeInOut(duration: 0.5).repeatForever(autoreverses: true),
                                    value: isLightningAnimating
                                )
                        )
                        
                        VStack(alignment: .leading) {
                            Text(recipient.name)
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text(recipient.company)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    } else {
                        Image(systemName: "person.circle.dashed")
                            .font(.title)
                            .foregroundColor(.gray)
                        
                        Text("Select Recipient")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // MARK: - Message Input
    
    private var messageInput: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Lightning Message")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "bolt.circle.fill")
                    .foregroundColor(.yellow)
                    .font(.title3)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                TextField("You're absolutely amazing! ⚡", text: $message, axis: .vertical)
                    .textFieldStyle(PlainTextFieldStyle())
                    .foregroundColor(.white)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        isLightningAnimating ? Color.yellow.opacity(0.5) : Color.white.opacity(0.1),
                                        lineWidth: 1
                                    )
                            )
                    )
                    .lineLimit(3...6)
                
                Text("\(message.count)/200 characters")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }
    
    // MARK: - Lightning Send Button
    
    private var lightningSendButton: some View {
        Button(action: sendShoutout) {
            HStack(spacing: 12) {
                Image(systemName: "bolt.fill")
                    .font(.title2)
                    .scaleEffect(isLightningAnimating ? 1.2 : 1.0)
                    .animation(
                        .easeInOut(duration: 0.3).repeatForever(autoreverses: true),
                        value: isLightningAnimating
                    )
                
                Text("Send Lightning Shoutout")
                    .font(.headline)
                    .fontWeight(.bold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [.yellow, .orange, .red],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: .yellow.opacity(0.5), radius: 10, x: 0, y: 0)
            )
        }
        .disabled(recipient == nil || message.isEmpty || message.count > 200)
        .opacity((recipient == nil || message.isEmpty || message.count > 200) ? 0.5 : 1.0)
    }
    
    // MARK: - Actions
    
    private func sendShoutout() {
        // Simulate sending with lightning effect
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            isLightningAnimating = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            showingSuccess = true
        }
    }
    
    private func startLightningAnimation() {
        isLightningAnimating = true
    }
}

// MARK: - User Picker View

struct UserPickerView: View {
    @Binding var selectedUser: ShoutoutUser?
    @Environment(\.dismiss) private var dismiss
    @StateObject private var chartService = ShoutoutChartService.shared
    @State private var searchText = ""
    @State private var isLightningAnimating = false
    
    var filteredUsers: [ShoutoutUser] {
        if searchText.isEmpty {
            return chartService.users
        } else {
            return chartService.users.filter { user in
                user.name.localizedCaseInsensitiveContains(searchText) ||
                user.company.localizedCaseInsensitiveContains(searchText) ||
                user.title.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Dark background
                LinearGradient(
                    colors: [Color.black, Color.blue.opacity(0.1)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search bar
                    searchBar
                    
                    // User list
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredUsers) { user in
                                LightningUserRow(
                                    user: user,
                                    isLightningAnimating: isLightningAnimating
                                ) {
                                    selectedUser = user
                                    dismiss()
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Select Recipient")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .onAppear {
                isLightningAnimating = true
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.yellow)
            
            TextField("Search contacts...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
                .foregroundColor(.white)
            
            if !searchText.isEmpty {
                Button("Clear") {
                    searchText = ""
                }
                .font(.caption)
                .foregroundColor(.gray)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                )
        )
        .padding()
    }
}

// MARK: - Lightning User Row

struct LightningUserRow: View {
    let user: ShoutoutUser
    let isLightningAnimating: Bool
    let onTap: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Profile image with lightning border
                AsyncImage(url: user.profileImageURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay {
                            Text(user.initials)
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                }
                .frame(width: 60, height: 60)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.yellow, lineWidth: 2)
                        .scaleEffect(isLightningAnimating ? 1.1 : 1.0)
                        .animation(
                            .easeInOut(duration: 0.5).repeatForever(autoreverses: true),
                            value: isLightningAnimating
                        )
                )
                
                // User info
                VStack(alignment: .leading, spacing: 4) {
                    Text(user.name)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    if !user.company.isEmpty {
                        Text(user.company)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    
                    if !user.title.isEmpty {
                        Text(user.title)
                            .font(.caption)
                            .foregroundColor(.gray.opacity(0.8))
                    }
                }
                
                Spacer()
                
                // Lightning bolt and verification
                VStack(spacing: 4) {
                    Image(systemName: "bolt.fill")
                        .foregroundColor(isLightningAnimating ? .yellow : .gray)
                        .font(.title3)
                        .scaleEffect(isLightningAnimating ? 1.2 : 1.0)
                        .animation(
                            .easeInOut(duration: 0.3).repeatForever(autoreverses: true),
                            value: isLightningAnimating
                        )
                    
                    Image(systemName: user.verificationStatus.systemImageName)
                        .foregroundColor(verificationColor)
                        .font(.caption)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isLightningAnimating ? Color.yellow.opacity(0.3) : Color.white.opacity(0.1),
                                lineWidth: 1
                            )
                    )
            )
            .scaleEffect(isHovering ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovering)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            isHovering = hovering
        }
    }
    
    private var verificationColor: Color {
        switch user.verificationStatus {
        case .verified: return .green
        case .pending: return .orange
        case .unverified: return .blue
        case .failed: return .red
        }
    }
}

#Preview {
    ShoutoutView()
}

