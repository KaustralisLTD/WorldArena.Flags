import SwiftUI

struct LifecycleBonusView: View {
    let contactID: String
    private let loadState: (() async throws -> LifecycleService.BonusState)?
    private let submitAnswer: ((String, Int, String) async throws -> LifecycleService.BonusState)?
    init(contactID: String, loadState: (() async throws -> LifecycleService.BonusState)? = nil, submitAnswer: ((String, Int, String) async throws -> LifecycleService.BonusState)? = nil) {
        self.contactID = contactID; self.loadState = loadState; self.submitAnswer = submitAnswer
    }
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var language = LocalizationManager.shared
    @State private var sessionID: String?
    @State private var question: LifecycleService.BonusQuestion?
    @State private var result: LifecycleService.BonusState?
    @State private var loading = false
    @State private var failed = false
    @State private var unavailable = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    Text(language.localizedString("lifecycle.bonus.title")).font(.largeTitle.bold()).multilineTextAlignment(.center)
                    Text(language.localizedString("lifecycle.bonus.body")).foregroundColor(.secondary)
                    if let result, result.done == true {
                        Image(systemName: result.reward == nil ? "checkmark.circle.fill" : "star.circle.fill").font(.system(size: 64)).foregroundColor(.teal)
                        Text("\(language.localizedString("Correct Answers")): \(result.correct ?? 0) / \(result.total ?? 10)").font(.title2.bold())
                        if let reward = result.reward { Text("+\(reward.amount) F-Bucks").font(.largeTitle.bold()).foregroundColor(.teal).accessibilityIdentifier("lifecycle.bonus.reward") }
                        Button(language.localizedString("Close")) { dismiss() }.buttonStyle(.borderedProminent)
                    } else if let question, !failed {
                        ProgressView(value: Double(question.index), total: Double(question.total))
                        Text("\(question.index + 1) / \(question.total)").font(.headline).accessibilityIdentifier("lifecycle.bonus.progress")
                        Text(language.currentLocale.localizedString(forRegionCode: question.flag) ?? question.flag).font(.largeTitle.bold()).multilineTextAlignment(.center)
                        ForEach(question.options, id: \.self) { code in
                            Button {
                                Task { await answer(code, index: question.index) }
                            } label: {
                                Text(CountryDatabase.getLocalizedCapitalName(for: code, language: language.currentBundleLanguageCode, fallback: code))
                                    .font(.headline).frame(maxWidth: .infinity).padding(16)
                            }.buttonStyle(.bordered).disabled(loading).accessibilityIdentifier("lifecycle.answer." + code)
                        }
                    }
                    if loading { ProgressView() }
                    if failed {
                        Text(language.localizedString(unavailable ? "lifecycle.bonus.unavailable" : "Server Error"))
                            .foregroundColor(.secondary).multilineTextAlignment(.center)
                        if !unavailable { Button(language.localizedString("Try Again")) { Task { await start() } }.buttonStyle(.borderedProminent) }
                    }
                }.padding(24).frame(maxWidth: 600).frame(maxWidth: .infinity)
            }
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button(language.localizedString("Close")) { dismiss() } } }
        }.task { await start() }
    }
    private func flag(_ code: String) -> String {
        String(String.UnicodeScalarView(code.uppercased().unicodeScalars.compactMap { UnicodeScalar(127397 + $0.value) }))
    }
    @MainActor private func start() async {
        guard !loading else { return }
        loading = true; failed = false; unavailable = false
        defer { loading = false }
        do {
            let state: LifecycleService.BonusState
            if let loadState { state = try await loadState() }
            else { state = try await LifecycleService.bonus(path: "start", body: ["contactId": contactID]) }
            sessionID = state.sessionId; question = state.question
            if state.done == true { result = state }
        } catch {
            failed = true; unavailable = error is LifecycleService.RequestFailure
        }
    }
    @MainActor private func answer(_ code: String, index: Int) async {
        guard !loading, let sessionID else { return }
        loading = true
        defer { loading = false }
        do {
            let state: LifecycleService.BonusState
            if let submitAnswer { state = try await submitAnswer(sessionID, index, code) }
            else { state = try await LifecycleService.bonus(path: "answer", body: ["sessionId": sessionID, "index": index, "answer": code]) }
            question = state.question
            if state.done == true { result = state }
        } catch {
            failed = true; unavailable = error is LifecycleService.RequestFailure
        }
    }
}
