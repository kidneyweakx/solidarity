import SwiftUI

// MARK: - Tab Bar Icon with Glow

struct TabBarIcon: View {
    let systemName: String
    let title: String
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                if isSelected {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.white.opacity(0.25), Color.white.opacity(0.0)],
                                center: .center,
                                startRadius: 1,
                                endRadius: 18
                            )
                        )
                        .frame(width: 24, height: 24)
                }
                Image(systemName: systemName)
                    .symbolRenderingMode(.monochrome)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(isSelected ? .white : Color(white: 0.65))
                    .shadow(color: isSelected ? Color.white.opacity(0.45) : Color.clear, radius: isSelected ? 2 : 0)
            }
            Text(title)
                .font(.footnote)
                .foregroundColor(isSelected ? .white : Color(white: 0.65))
        }
        .padding(.top, 8)
        .padding(.bottom, 2)
    }
}

// MARK: - Floating Glossy Backdrop

struct FloatingTabBarBackdrop: View {
    var body: some View {
        ZStack {
            // Flat, semi-transparent surface for Material-like feel
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                )
        }
        .frame(height: 54)
        .padding(.horizontal, 16)
        .padding(.bottom, 22)
        .background(Color.clear)
        .accessibilityHidden(true)
    }
}


// MARK: - App Tabs (for custom bar)

enum MainAppTab: Int, CaseIterable {
    case glossary = 0
    case events = 1
    case shoutout = 2
    case id = 3
}

// MARK: - Custom Floating Tab Bar

struct CustomFloatingTabBar: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        ZStack(alignment: .bottom) {
            FloatingTabBarBackdrop()
                .allowsHitTesting(false)
                .padding(.bottom, -6)
            
            HStack {
                TabBarButton(systemName: "list.bullet.rectangle", title: "Glossary", isSelected: selectedTab == MainAppTab.glossary.rawValue) {
                    selectedTab = MainAppTab.glossary.rawValue
                }
                Spacer(minLength: 16)
                TabBarButton(systemName: "circle.grid.2x2", title: "Events", isSelected: selectedTab == MainAppTab.events.rawValue) {
                    selectedTab = MainAppTab.events.rawValue
                }
                Spacer(minLength: 16)
                TabBarButton(systemName: "bolt", title: "Shoutout", isSelected: selectedTab == MainAppTab.shoutout.rawValue) {
                    selectedTab = MainAppTab.shoutout.rawValue
                }
                Spacer(minLength: 16)
                TabBarButton(systemName: "target", title: "ID", isSelected: selectedTab == MainAppTab.id.rawValue) {
                    selectedTab = MainAppTab.id.rawValue
                }
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 12)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

// MARK: - Tab Bar Button (uses TabBarIcon)

struct TabBarButton: View {
    let systemName: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            TabBarIcon(systemName: systemName, title: title, isSelected: isSelected)
        }
        .buttonStyle(.plain)
    }
}


