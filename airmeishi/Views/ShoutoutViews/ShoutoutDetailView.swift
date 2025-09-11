//
//  ShoutoutDetailView.swift
//  airmeishi
//
//  Detailed view for a specific user in the shoutout system
//

import SwiftUI

struct ShoutoutDetailView: View {
    let user: ShoutoutUser
    @Environment(\.dismiss) private var dismiss
    @State private var showingCreateShoutout = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header with profile and stats
                    headerSection
                    
                    // 3D Position Info
                    positionSection
                    
                    // User Information
                    informationSection
                    
                    // Tags and Skills
                    tagsSection
                    
                    // Action Buttons
                    actionButtons
                }
                .padding()
            }
            .navigationTitle("User")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingCreateShoutout) {
                CreateShoutoutView(selectedUser: user)
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            // Profile Image
            AsyncImage(url: user.profileImageURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Color.white.opacity(0.15))
                    .overlay {
                        Text(user.initials)
                            .font(.title)
                            .foregroundColor(.white)
                    }
            }
            .frame(width: 100, height: 100)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(verificationColor.opacity(0.8), lineWidth: 2)
            )
            .shadow(color: Color.black.opacity(0.4), radius: 8, x: 0, y: 4)
            
            // Name and Title
            VStack(spacing: 2) {
                Text(user.name)
                    .font(.headline)
                    .foregroundColor(.white)
                
                if !user.title.isEmpty {
                    Text(user.title)
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
                
                if !user.company.isEmpty {
                    Text(user.company)
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
            }
            
            // Verification Status
            HStack(spacing: 6) {
                Image(systemName: user.verificationStatus.systemImageName)
                Text(user.verificationStatus.displayName)
            }
            .font(.caption)
            .foregroundColor(verificationColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(verificationColor.opacity(0.08))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Position Section
    
    private var positionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("3D Position")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 8) {
                PositionRow(
                    title: "Events Score",
                    value: String(format: "%.1f", user.eventScore),
                    color: .cyan,
                    description: "Activity Level"
                )
                
                PositionRow(
                    title: "Type Score",
                    value: String(format: "%.1f", user.typeScore),
                    color: .orange,
                    description: "Professional Level"
                )
                
                PositionRow(
                    title: "Character Score",
                    value: String(format: "%.1f", user.characterScore),
                    color: .green,
                    description: "Personality Traits"
                )
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
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
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(action: { showingCreateShoutout = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "bolt")
                    Text("Send shoutout")
                }
                .font(.headline)
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white)
                .cornerRadius(12)
            }
            
            Button(action: {
                // TODO: Implement view profile action
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "person")
                    Text("View profile")
                }
                .font(.subheadline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white.opacity(0.06))
                .cornerRadius(12)
            }
        }
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

// MARK: - Supporting Views

struct PositionRow: View {
    let title: String
    let value: String
    let color: Color
    let description: String
    
    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Text(value)
                .font(.headline)
                .foregroundColor(color)
        }
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
