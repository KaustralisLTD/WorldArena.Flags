import Foundation

#if os(iOS)
import Dispatch
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppTrackingTransparency)
import AppTrackingTransparency
#endif
#endif

/// Управляет ATT-запросом так, чтобы он показывался до рекламного трекинга.
/// `@unchecked Sendable`: singleton; колбэки NotificationCenter помечены как `@Sendable`, захват `self` иначе ругается компилятор.
final class TrackingAuthorizationService: @unchecked Sendable {
    static let shared = TrackingAuthorizationService()

    #if os(iOS)
    private var requestInFlight = false
    private var pendingCompletions: [() -> Void] = []
    /// Токен от `addObserver(forName:object:queue:using:)` — снимать только его, не `self`.
    private var didBecomeActiveObserver: NSObjectProtocol?
    #endif

    private init() {}

    #if os(iOS) && canImport(AppTrackingTransparency)
    @MainActor
    func requestIfNeeded(completion: @escaping () -> Void) {
        let status = ATTrackingManager.trackingAuthorizationStatus

        guard status == .notDetermined else {
            completion()
            return
        }

        // Если запрос уже в процессе — просто добавляем completion в очередь.
        pendingCompletions.append(completion)
        guard !requestInFlight else {
            return
        }
        requestInFlight = true

        print("ATT: status=notDetermined, starting request...")

        let startRequest: () -> Void = {
            // Небольшая задержка после появления UI, чтобы системный ATT-алерт стабильно показывался.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                ATTrackingManager.requestTrackingAuthorization { newStatus in
                    DispatchQueue.main.async {
                        print("ATT: request completed, status=\(newStatus.rawValue)")
                        let handlers = self.pendingCompletions
                        self.pendingCompletions.removeAll(keepingCapacity: false)
                        self.requestInFlight = false
                        handlers.forEach { $0() }
                    }
                }
            }
        }

        #if canImport(UIKit)
        if UIApplication.shared.applicationState == .active {
            startRequest()
        } else {
            didBecomeActiveObserver = NotificationCenter.default.addObserver(
                forName: UIApplication.didBecomeActiveNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                guard let self else { return }
                if let token = self.didBecomeActiveObserver {
                    NotificationCenter.default.removeObserver(token)
                    self.didBecomeActiveObserver = nil
                }
                startRequest()
            }
            return
        }
        #else
        startRequest()
        #endif
    }
    #else
    @MainActor
    func requestIfNeeded(completion: @escaping () -> Void) {
        completion()
    }
    #endif
}

