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
    private var progressData: (current: Int, target: Int) { userProfile.progress(for: definition) }
    private var visualLevel: Int {
        let ratio = Double(max(progressData.current, 0)) / Double(max(progressData.target, 1))
        if ratio >= 2.2 { return 3 }
        if ratio >= 1.2 { return 2 }
        if ratio >= 1.0 { return 1 }
        return 0
    }
    private var levelAccent: Color {
        switch visualLevel {
        case 3: return .yellow
        case 2: return .orange
        case 1: return definition.color
        default: return .gray.opacity(0.45)
        }
    }
    var progressText: String {
        let p = progressData
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
                if let asset = definition.imageAssetName {
                    Image(asset)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 72, height: 72)
                        .saturation(isUnlocked ? 1 : 0)
                        .background(Circle().fill(secondarySystemGroupedBackground))
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(levelAccent)
                        .frame(width: 72, height: 72)
                        .overlay(
                            Circle()
                                .stroke(levelAccent.opacity(0.45), lineWidth: visualLevel > 0 ? CGFloat(visualLevel) + 1 : 1)
                        )
                        .shadow(color: levelAccent.opacity(visualLevel > 0 ? 0.28 : 0), radius: 8, x: 0, y: 4)
                    Image(systemName: isUnlocked ? definition.icon : "lock.fill")
                        .foregroundColor(isUnlocked ? .white : .gray)
                        .font(.system(size: isUnlocked ? 28 : 20, weight: .bold))
                }

                if visualLevel > 0 {
                    HStack(spacing: 2) {
                        ForEach(0..<visualLevel, id: \.self) { _ in
                            Image(systemName: "star.fill")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.white.opacity(0.95))
                        }
                    }
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color.black.opacity(0.25))
                    .clipShape(Capsule())
                    .offset(y: 33)
                }
            }
            
            Text(LocalizationManager.shared.localizedString(definition.titleKey))
                .font(.system(size: 12, weight: .semibold))
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
                .lineLimit(2)
                .frame(height: 34)
            
            Text(isUnlocked ? "\(LocalizationManager.shared.localizedString("Открыто")) • Lv\(visualLevel)" : progressText)
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
                if let asset = definition.imageAssetName {
                    Image(asset)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 140, height: 140)
                        .saturation(isUnlocked ? 1 : 0)
                        .background(Circle().fill(Color(UIColor.secondarySystemGroupedBackground)))
                        .clipShape(Circle())
                } else {
                    Circle().fill(definition.color).frame(width: 120, height: 120)
                    Image(systemName: definition.icon).foregroundColor(.white).font(.system(size: 44, weight: .bold))
                }
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


