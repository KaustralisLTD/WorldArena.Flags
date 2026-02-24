import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct AchievementsView: View {
    @EnvironmentObject var userProfile: UserProfile
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 3)
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(LocalizationManager.shared.localizedString("ЛИЧНЫЕ РЕКОРДЫ"))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 20)
                
                personalRecords
                
                Text(LocalizationManager.shared.localizedString("НАГРАДЫ"))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 20)
                
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(userProfile.allAchievementDefinitions) { def in
                        NavigationLink(destination: AchievementDetailView(definition: def).environmentObject(userProfile)) {
                            AchievementCell(definition: def)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
        }
        .navigationTitle(LocalizationManager.shared.localizedString("Достижения"))
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
    
    private var personalRecords: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                RecordCard(title: LocalizationManager.shared.localizedString("Лучшая серия"), value: "#\(userProfile.streak)")
                RecordCard(title: LocalizationManager.shared.localizedString("Макс. лига"), value: userProfile.currentLeague.localizedName)
                RecordCard(title: LocalizationManager.shared.localizedString("Макс. XP"), value: "\(userProfile.xp)")
            }
            .padding(.horizontal, 20)
        }
    }
}

private struct AchievementCell: View {
    @EnvironmentObject var userProfile: UserProfile
    let definition: AchievementDefinition
    
    var isUnlocked: Bool { userProfile.isAchievementUnlocked(id: definition.id) }
    var progressText: String {
        let p = userProfile.progress(for: definition)
        return "\(min(p.current, p.target)) / \(p.target)"
    }
    
    private var secondarySystemGroupedBackground: Color {
        #if os(iOS)
        return Color(UIColor.secondarySystemGroupedBackground)
        #else
        return Color(NSColor.textBackgroundColor)
        #endif
    }
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(isUnlocked ? definition.color : Color.gray.opacity(0.2))
                    .frame(width: 72, height: 72)
                
                if isUnlocked {
                    Image(systemName: definition.icon)
                        .foregroundColor(.white)
                        .font(.system(size: 28, weight: .bold))
                } else {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.gray)
                        .font(.system(size: 20))
                }
            }
            
            Text(LocalizationManager.shared.localizedString(definition.titleKey))
                .font(.system(size: 12, weight: .semibold))
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
                .lineLimit(2)
                .frame(height: 34)
            
            Text(isUnlocked ? LocalizationManager.shared.localizedString("Открыто") : progressText)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(8)
        .background(secondarySystemGroupedBackground)
        .cornerRadius(12)
    }
}

private struct RecordCard: View {
    let title: String
    let value: String
    
    private var secondarySystemGroupedBackground: Color {
        #if os(iOS)
        return Color(UIColor.secondarySystemGroupedBackground)
        #else
        return Color(NSColor.textBackgroundColor)
        #endif
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(value)
                .font(.system(size: 22, weight: .bold))
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
        }
        .frame(width: 160, height: 90)
        .padding(12)
        .background(secondarySystemGroupedBackground)
        .cornerRadius(14)
    }
}

struct AchievementDetailView: View {
    @EnvironmentObject var userProfile: UserProfile
    let definition: AchievementDefinition
    
    var isUnlocked: Bool { userProfile.isAchievementUnlocked(id: definition.id) }
    var progress: (current: Int, target: Int) { userProfile.progress(for: definition) }
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle().fill(definition.color).frame(width: 120, height: 120)
                Image(systemName: definition.icon).foregroundColor(.white).font(.system(size: 44, weight: .bold))
            }
            
            Text(LocalizationManager.shared.localizedString(definition.titleKey))
                .font(.system(size: 22, weight: .bold))
            Text(LocalizationManager.shared.localizedString(definition.descriptionKey))
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            ProgressView(value: Float(progress.current), total: Float(progress.target))
                .padding(.horizontal)
            Text("\(min(progress.current, progress.target)) / \(progress.target)")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding(.top, 20)
        .navigationTitle(LocalizationManager.shared.localizedString("Достижение"))
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}


