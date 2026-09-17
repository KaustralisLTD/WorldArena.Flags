import SwiftUI
#if os(iOS)
import UIKit
#endif

struct FriendStreaksView: View {
    let friends: [Friend]
    @ObservedObject var gameState: GameState
    /// Отправить напоминание выбранному другу; возвращает строку для тоста или nil при ошибке.
    let onRemind: (Friend) async -> String?
    let onContinue: () -> Void
    
    @State private var showContent = false
    @State private var showFriends = false
    @State private var showButtons = false
    @State private var titleScale: CGFloat = 0.8
    @State private var nudgeToastMessage: String?
    @State private var isSendingNudge = false
    @State private var remindedUsernames: Set<String> = []
    @State private var remindPulseUsernames: Set<String> = []
    @State private var sendingPulseUsername: String?
    
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @Environment(\.colorScheme) private var colorScheme
    
    private var accentA: Color { Color(red: 0.35, green: 0.22, blue: 0.98) }
    private var accentB: Color { Color(red: 0.1, green: 0.55, blue: 1.0) }
    
    private var pageBackground: some View {
        Group {
            if colorScheme == .dark {
                LinearGradient(
                    colors: [
                        Color(red: 0.05, green: 0.06, blue: 0.12),
                        accentA.opacity(0.35),
                        Color(red: 0.04, green: 0.1, blue: 0.16)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                LinearGradient(
                    colors: [
                        Color(red: 0.97, green: 0.96, blue: 1.0),
                        Color(red: 0.88, green: 0.93, blue: 1.0),
                        Color(red: 0.95, green: 0.98, blue: 1.0)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
        .ignoresSafeArea()
    }
    
    var body: some View {
        ZStack {
            pageBackground
            
            VStack(spacing: 26) {
                Spacer(minLength: 8)
                
                VStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [accentA.opacity(0.35), accentB.opacity(0.45)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 72, height: 72)
                            .blur(radius: 10)
                        Image(systemName: "person.3.sequence.fill")
                            .font(.system(size: 36, weight: .semibold))
                            .foregroundStyle(
                                LinearGradient(colors: [accentA, accentB], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                    }
                    .scaleEffect(titleScale)
                    
                    Text(localizationManager.localizedString("Your Friend Streaks"))
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    
                    Text(localizationManager.localizedString("See how your friends are doing"))
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 12)
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : -24)
                
                // Friends list
                VStack(spacing: 16) {
                    if friends.isEmpty {
                        // Empty state
                        VStack(spacing: 16) {
                            Image(systemName: "person.2.slash")
                                .font(.system(size: 48))
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(colorScheme == .dark ? .white.opacity(0.5) : .secondary)
                            
                            Text(localizationManager.localizedString("No friends yet"))
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(colorScheme == .dark ? .white : .primary)
                            
                            Text(localizationManager.localizedString("Add friends to see their streaks and compete together!"))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(colorScheme == .dark ? .white.opacity(0.75) : .secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        .opacity(showFriends ? 1 : 0)
                        .scaleEffect(showFriends ? 1 : 0.8)
                    } else {
                        // Friends list
                        VStack(spacing: 12) {
                            ForEach(Array(friends.enumerated()), id: \.element.id) { index, friend in
                                HStack(spacing: 0) {
                                    NavigationLink(destination: FriendProfileView(friend: friend, gameState: gameState)) {
                                        FriendStreakRow(
                                            friend: friend,
                                            delay: Double(index) * 0.1,
                                            isVisible: showFriends,
                                            showPlayedTodayBadge: friend.playedToday
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .disabled(isSendingNudge)
                                    if friend.playedToday {
                                        HStack(spacing: 6) {
                                            Image(systemName: "flame.fill")
                                                .font(.system(size: 16))
                                                .foregroundColor(.orange)
                                            Text("\(friend.streak) \(localizationManager.localizedString("days"))")
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(.secondary)
                                        }
                                        .padding(.leading, 12)
                                    } else {
                                        let remindSent = remindedUsernames.contains(friend.username)
                                        let pulse = remindPulseUsernames.contains(friend.username)
                                        Button(action: {
                                            Task {
                                                isSendingNudge = true
                                                sendingPulseUsername = friend.username
                                                defer {
                                                    isSendingNudge = false
                                                    sendingPulseUsername = nil
                                                }
                                                if let msg = await onRemind(friend) {
                                                    remindedUsernames.insert(friend.username)
                                                    remindPulseUsernames.insert(friend.username)
                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                                                        remindPulseUsernames.remove(friend.username)
                                                    }
                                                    nudgeToastMessage = msg
                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
                                                        nudgeToastMessage = nil
                                                    }
                                                }
                                            }
                                        }) {
                                            let sending = sendingPulseUsername == friend.username && isSendingNudge
                                            HStack(spacing: 6) {
                                                if sending {
                                                    ProgressView()
                                                        .tint(.white)
                                                        .scaleEffect(0.9)
                                                } else if remindSent {
                                                    Image(systemName: "checkmark.circle.fill")
                                                        .font(.system(size: 15, weight: .bold))
                                                }
                                                Text(
                                                    remindSent
                                                        ? localizationManager.localizedString("friends.remind.status_sent")
                                                        : localizationManager.localizedString("Remind")
                                                )
                                                .font(.system(size: 13, weight: .heavy, design: .rounded))
                                                .foregroundColor(.white)
                                            }
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 10)
                                            .background(
                                                LinearGradient(
                                                    colors: remindSent
                                                        ? [Color.green.opacity(0.95), Color.teal.opacity(0.92)]
                                                        : [accentB.opacity(0.95), accentA.opacity(0.88)],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            .clipShape(Capsule())
                                            .shadow(color: (remindSent ? Color.green : accentB).opacity(0.35), radius: 10, y: 4)
                                            .scaleEffect(pulse ? 1.06 : 1.0)
                                            .animation(.spring(response: 0.28, dampingFraction: 0.62), value: pulse)
                                        }
                                        .buttonStyle(BorderlessButtonStyle())
                                        .disabled(isSendingNudge || remindSent)
                                        .padding(.leading, 8)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Action buttons — в одном стиле с экраном результатов игры
                VStack(spacing: 16) {
                    Button(action: onContinue) {
                        HStack(spacing: 12) {
                            Text(localizationManager.localizedString("CONTINUE"))
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 64)
                        .background(
                            LinearGradient(
                                colors: [Color.blue, Color.purple, Color.pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(32)
                        .shadow(color: .blue.opacity(0.4), radius: 15, x: 0, y: 8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 32)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .opacity(showButtons ? 1 : 0)
                    .scaleEffect(showButtons ? 1 : 0.8)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
        .overlay(alignment: .bottom) {
            if let msg = nudgeToastMessage {
                HStack(spacing: 10) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 16, weight: .semibold))
                    Text(msg)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [accentA.opacity(0.92), accentB.opacity(0.88)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: accentB.opacity(0.45), radius: 16, y: 8)
                )
                .padding(.bottom, 108)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onAppear {
            startAnimations()
        }
    }
    
    // MARK: - Animations
    
    private func startAnimations() {
        withAnimation(.easeOut(duration: 0.8)) {
            showContent = true
        }
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.3)) {
            titleScale = 1.0
        }
        
        withAnimation(.easeOut(duration: 0.6).delay(0.6)) {
            showFriends = true
        }
        
        withAnimation(.easeOut(duration: 0.5).delay(1.0)) {
            showButtons = true
        }
    }
}

struct FriendStreakRow: View {
    let friend: Friend
    let delay: Double
    let isVisible: Bool
    var showPlayedTodayBadge: Bool = false
    
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        HStack(spacing: 16) {
            // Avatar (флаг страны или первая буква)
            ZStack {
                Circle()
                    .fill(avatarBackgroundColor)
                    .frame(width: 50, height: 50)
                #if os(iOS)
                if let data = friend.remotePhotoAvatarData, let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                } else {
                    Text(friend.displayAvatar)
                        .font(.system(size: friend.countryCode != nil ? 26 : 20, weight: .bold))
                }
                #else
                Text(friend.displayAvatar)
                    .font(.system(size: friend.countryCode != nil ? 26 : 20, weight: .bold))
                #endif
            }
            
            // Friend info
            VStack(alignment: .leading, spacing: 4) {
                Text(friend.displayNameOrUsername)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 14))
                    
                    Text("\(friend.streak) \(localizationManager.localizedString("days"))")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if !showPlayedTodayBadge {
                // Streak number справа (для тех, кому показываем кнопку «Напомнить»)
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(friend.streak)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.orange)
                    Text(localizationManager.localizedString("streak"))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground).opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.18), Color.blue.opacity(0.12)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
        )
        .opacity(isVisible ? 1 : 0)
        .offset(x: isVisible ? 0 : -50)
        .animation(
            .easeOut(duration: 0.6)
            .delay(delay),
            value: isVisible
        )
    }
    
    private var avatarBackgroundColor: Color {
        let colors: [Color] = [.blue, .green, .orange, .purple, .red, .pink]
        let index = abs(friend.username.hashValue) % colors.count
        return colors[index]
    }
}

#Preview {
    FriendStreaksView(
        friends: [
            Friend(id: UUID(), username: "Anton", avatar: "person.circle.fill", level: 5, xp: 2500, streak: 14, isOnline: true, joinDate: Date().addingTimeInterval(-86400 * 30), playedToday: true),
            Friend(id: UUID(), username: "Alex", avatar: "person.circle.fill", level: 3, xp: 1200, streak: 11, isOnline: false, joinDate: Date().addingTimeInterval(-86400 * 15), playedToday: false)
        ],
        gameState: GameState(),
        onRemind: { _ async in LocalizationManager.shared.localizedString("friends.remind.status_sent") },
        onContinue: {}
    )
}
