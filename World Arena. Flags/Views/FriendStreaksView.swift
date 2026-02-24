import SwiftUI

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
    
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.purple.opacity(0.1), Color.blue.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                // Title section
                VStack(spacing: 12) {
                    Text(localizationManager.localizedString("Your Friend Streaks"))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.primary)
                        .scaleEffect(titleScale)
                    
                    Text(localizationManager.localizedString("See how your friends are doing"))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : -30)
                
                // Friends list
                VStack(spacing: 16) {
                    if friends.isEmpty {
                        // Empty state
                        VStack(spacing: 16) {
                            Image(systemName: "person.2.slash")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary)
                            
                            Text(localizationManager.localizedString("No friends yet"))
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            Text(localizationManager.localizedString("Add friends to see their streaks and compete together!"))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
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
                                            isVisible: showFriends
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .disabled(isSendingNudge)
                                    Button(action: {
                                        Task {
                                            isSendingNudge = true
                                            defer { isSendingNudge = false }
                                            if let msg = await onRemind(friend) {
                                                nudgeToastMessage = msg
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                                    nudgeToastMessage = nil
                                                }
                                            }
                                        }
                                    }) {
                                        Text(localizationManager.localizedString("Remind"))
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(Color.blue)
                                            .cornerRadius(8)
                                    }
                                    .buttonStyle(BorderlessButtonStyle())
                                    .disabled(isSendingNudge)
                                    .padding(.leading, 8)
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
                Text(msg)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(10)
                    .padding(.bottom, 100)
                    .transition(.opacity)
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
    
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        HStack(spacing: 16) {
            // Avatar (флаг страны или первая буква)
            ZStack {
                Circle()
                    .fill(avatarBackgroundColor)
                    .frame(width: 50, height: 50)
                
                Text(friend.displayAvatar)
                    .font(.system(size: friend.countryCode != nil ? 26 : 20, weight: .bold))
            }
            
            // Friend info
            VStack(alignment: .leading, spacing: 4) {
                Text(friend.displayNameOrUsername)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                HStack(spacing: 6) {
                    Text("🔥")
                        .font(.system(size: 14))
                    
                    Text("\(friend.streak) \(localizationManager.localizedString("days"))")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Streak status
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(friend.streak)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.orange)
                
                Text(localizationManager.localizedString("streak"))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
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
            Friend(id: UUID(), username: "Anton", avatar: "person.circle.fill", level: 5, xp: 2500, streak: 14, isOnline: true, joinDate: Date().addingTimeInterval(-86400 * 30)),
            Friend(id: UUID(), username: "Alex", avatar: "person.circle.fill", level: 3, xp: 1200, streak: 11, isOnline: false, joinDate: Date().addingTimeInterval(-86400 * 15))
        ],
        gameState: GameState(),
        onRemind: { _ async in "Reminder sent" },
        onContinue: {}
    )
}
