import Foundation
import Observation
import Translation

struct WarningIdentity: Hashable {
    let regionID: Int
    let registrationID: Int
    let publishedAt: Date

    init(_ warning: AvalancheWarningDetailed) {
        regionID = warning.RegionId
        registrationID = warning.RegId
        publishedAt = warning.PublishTime
    }
}

@Observable
@MainActor
final class WarningTranslationModel {
    private(set) var texts: [String: String] = [:]
    private(set) var isTranslating = false
    private(set) var configuration: TranslationSession.Configuration?
    private var warning: AvalancheWarningDetailed?
    @ObservationIgnored private var requestID = UUID()

    private let source = Locale.Language(identifier: "en")
    private let target = Locale(identifier: Locale.preferredLanguages.first ?? "en").language
    var languageCode: String { target.languageCode?.identifier ?? "en" }
    var isAvailable: Bool { !["nb", "nn", "sv", "en"].contains(languageCode) }
    var isTranslated: Bool { !texts.isEmpty }

    func select(_ warning: AvalancheWarningDetailed?) {
        guard self.warning.map(WarningIdentity.init) != warning.map(WarningIdentity.init) else { return }
        self.warning = warning
        reset()
    }

    func toggle() {
        if isTranslated {
            reset()
        } else if warning != nil {
            requestID = UUID()
            isTranslating = true
            if configuration != nil {
                configuration?.invalidate()
            } else {
                configuration = .init(source: source, target: target)
            }
        }
    }

    func translate(using session: sending TranslationSession) async {
        guard let warning else { return }
        let request = requestID
        defer { if requestID == request { isTranslating = false } }
        do {
            var requests: [TranslationSession.Request] = []
            for text in Self.sourceTexts(for: warning) { requests.append(.init(sourceText: text)) }
            let responses = try await session.translations(from: requests)
            guard !Task.isCancelled, requestID == request else { return }
            texts = responses.reduce(into: [:]) { $0[$1.sourceText] = $1.targetText }
        } catch { /* Leave the original forecast visible if translation is unavailable. */  }
    }

    nonisolated static func sourceTexts(for warning: AvalancheWarningDetailed) -> [String] {
        var texts = [warning.MainText]
        texts += [warning.AvalancheDanger, warning.EmergencyWarning].compactMap { $0 }.filter { !$0.isEmpty }
        for problem in warning.AvalancheProblems ?? [] {
            texts.append(problem.AvalancheProblemTypeName)
            if !problem.TriggerSenitivityPropagationDestuctiveSizeText.isEmpty {
                texts.append(problem.TriggerSenitivityPropagationDestuctiveSizeText)
            }
        }
        return texts
    }

    private func reset() {
        requestID = UUID()
        configuration = nil
        texts = [:]
        isTranslating = false
    }
}
