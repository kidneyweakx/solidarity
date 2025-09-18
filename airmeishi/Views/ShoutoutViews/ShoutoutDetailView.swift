//
//  ShoutoutDetailView.swift
//  airmeishi
//
//  Lightening-themed detailed view for a specific user in the shoutout system
//

import SwiftUI

struct ShoutoutDetailView: View {
    let user: ShoutoutUser
    @Environment(\.dismiss) private var dismiss
    @State private var showingCreateShoutout = false
    @State private var isLighteningAnimating = false
    
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
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Lightening header with profile
                        lightningHeader
                        
                        // Lightening stats grid
                        lightningStatsGrid
                        
                        // User Information
                        informationSection
                        
                        // Tags and Skills
                        tagsSection
                        
                        // Lightening Action Buttons
                        lightningActionButtons
                    }
                    .padding()
                }
            }
            .navigationTitle("Lightening Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .sheet(isPresented: $showingCreateShoutout) {
                CreateShoutoutView(selectedUser: user)
            }
            .onAppear {
                startLighteningAnimation()
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Lightening Header
    
    private var lightningHeader: some View {
        VStack(spacing: 20) {
            // Lightening bolt and title
            HStack {
                Image(systemName: "bolt.fill")
                    .foregroundColor(.yellow)
                    .font(.title)
                    .scaleEffect(isLighteningAnimating ? 1.3 : 1.0)
                    .animation(
                        .easeInOut(duration: 0.5).repeatForever(autoreverses: true),
                        value: isLighteningAnimating
                    )
                
                Text("Lightening Profile")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            // Profile Image with lightning effects
            ZStack {
                // Lightening ring
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [.yellow, .orange, .red],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 120, height: 120)
                    .scaleEffect(isLighteningAnimating ? 1.1 : 1.0)
                    .animation(
                        .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                        value: isLighteningAnimating
                    )
                
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
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                }
                .frame(width: 100, height: 100)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(verificationColor, lineWidth: 3)
                        .scaleEffect(isLighteningAnimating ? 1.05 : 1.0)
                        .animation(
                            .easeInOut(duration: 0.6).repeatForever(autoreverses: true),
                            value: isLighteningAnimating
                        )
                )
                .shadow(
                    color: isLighteningAnimating ? .yellow.opacity(0.6) : verificationColor.opacity(0.5),
                    radius: isLighteningAnimating ? 15 : 8,
                    x: 0, y: 4
                )
            }
            
            // Name and Title
            VStack(spacing: 4) {
                Text(user.name)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                if !user.title.isEmpty {
                    Text(user.title)
                        .font(.headline)
                        .foregroundColor(.yellow)
                }
                
                if !user.company.isEmpty {
                    Text(user.company)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            
            // Verification Status with lightning
            HStack(spacing: 8) {
                Image(systemName: user.verificationStatus.systemImageName)
                    .foregroundColor(verificationColor)
                    .font(.title3)
                
                Text(user.verificationStatus.displayName)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Image(systemName: "bolt.fill")
                    .foregroundColor(.yellow)
                    .font(.caption)
                    .scaleEffect(isLighteningAnimating ? 1.2 : 1.0)
                    .animation(
                        .easeInOut(duration: 0.3).repeatForever(autoreverses: true),
                        value: isLighteningAnimating
                    )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(verificationColor.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(verificationColor, lineWidth: 1)
                    )
            )
        }
    }
    
    // MARK: - Lightening Stats Grid
    
    private var lightningStatsGrid: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Lightening Stats")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "bolt.circle.fill")
                    .foregroundColor(.yellow)
                    .font(.title2)
                    .scaleEffect(isLighteningAnimating ? 1.2 : 1.0)
                    .animation(
                        .easeInOut(duration: 0.5).repeatForever(autoreverses: true),
                        value: isLighteningAnimating
                    )
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                LighteningStatCard(
                    title: "Activity",
                    value: String(format: "%.0f%%", user.eventScore * 100),
                    icon: "bolt.fill",
                    color: .yellow,
                    isLighteningAnimating: isLighteningAnimating
                )
                
                LighteningStatCard(
                    title: "Professional",
                    value: String(format: "%.0f%%", user.typeScore * 100),
                    icon: "briefcase.fill",
                    color: .blue,
                    isLighteningAnimating: isLighteningAnimating
                )
                
                LighteningStatCard(
                    title: "Character",
                    value: String(format: "%.0f%%", user.characterScore * 100),
                    icon: "person.fill",
                    color: .green,
                    isLighteningAnimating: isLighteningAnimating
                )
                
                LighteningStatCard(
                    title: "Verified",
                    value: user.verificationStatus.displayName,
                    icon: user.verificationStatus.systemImageName,
                    color: verificationColor,
                    isLighteningAnimating: isLighteningAnimating
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Information Section
    
    private var informationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Contact")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 8) {
                if !user.email.isEmpty {
                    ShoutoutInfoRow(
                        icon: "envelope",
                        title: "Email",
                        value: user.email
                    )
                }
                
                ShoutoutInfoRow(
                    icon: "calendar",
                    title: "Last Interaction",
                    value: DateFormatter.relativeDate.string(from: user.lastInteraction)
                )
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
    
    // MARK: - Tags Section
    
    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tags")
                .font(.headline)
                .foregroundColor(.white)
            
            if user.tags.isEmpty {
                Text("No tags available")
                    .font(.body)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 100))
                ], spacing: 8) {
                    ForEach(user.tags, id: \.self) { tag in
                        Text("#\(tag)")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.06))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
    
    // MARK: - Lightening Action Buttons
    
    private var lightningActionButtons: some View {
        VStack(spacing: 16) {
            // Primary Lightening Shoutout Button
            Button(action: { showingCreateShoutout = true }) {
                HStack(spacing: 12) {
                    Image(systemName: "bolt.fill")
                        .font(.title2)
                        .scaleEffect(isLighteningAnimating ? 1.3 : 1.0)
                        .animation(
                            .easeInOut(duration: 0.3).repeatForever(autoreverses: true),
                            value: isLighteningAnimating
                        )
                    
                    Text("Send Lightening Shoutout")
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
            
            // Secondary Actions
            HStack(spacing: 12) {
                Button(action: {
                    // TODO: Implement view profile action
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "person.circle")
                            .font(.title3)
                        Text("View Profile")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    )
                }
                
                Button(action: {
                    // TODO: Implement share action
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.title3)
                        Text("Share")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    )
                }
            }
        }
    }
    
    // MARK: - Animation Control
    
    private func startLighteningAnimation() {
        isLighteningAnimating = true
    }
    
    // MARK: - Computed Properties
    
    private var verificationColor: Color {
        switch user.verificationStatus {
        case .verified: return .green
        case .pending: return .orange
        case .unverified: return .blue
        case .failed: return .red
        }
    }
}

// MARK: - Lightening Stat Card

struct LighteningStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let isLighteningAnimating: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            // Icon with lightning effect
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .scaleEffect(isLighteningAnimating ? 1.2 : 1.0)
                .animation(
                    .easeInOut(duration: 0.5).repeatForever(autoreverses: true),
                    value: isLighteningAnimating
                )
            
            // Value
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            // Title
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct ShoutoutInfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.white)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                Text(value)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
    }
}

// MARK: - Extensions

extension DateFormatter {
    static let relativeDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.doesRelativeDateFormatting = true
        return formatter
    }()
}

#Preview {
    ShoutoutDetailView(
        user: ShoutoutUser(
            id: UUID(),
            name: "John Doe",
            company: "Tech Corp",
            title: "Software Engineer",
            email: "john@techcorp.com",
            profileImageURL: nil,
            tags: ["developer", "swift", "ios"],
            eventScore: 0.8,
            typeScore: 0.7,
            characterScore: 0.6,
            lastInteraction: Date(),
            verificationStatus: .verified
        )
    )
}
