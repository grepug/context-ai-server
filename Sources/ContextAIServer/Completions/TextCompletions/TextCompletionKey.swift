import SwiftAI

public enum TextCompletionKey: String, Hashable, Sendable {
    case translator
    case studyNotes
    case thesaurus
    case memorizingHelper
    case collocations
    case usages
}

extension TextCompletionKey {
    var template: String {
        switch self {
        case .collocations: PromptTemplates.collocations
        case .translator: PromptTemplates.translator
        case .studyNotes: PromptTemplates.studyNotes
        case .thesaurus: PromptTemplates.thesaurus
        case .memorizingHelper: PromptTemplates.memorizingHelper
        case .usages: PromptTemplates.usages
        }
    }

    public func makeCompletion(input: AICompletionNormalizedInput) -> AIStaticTextCompletion<AICompletionNormalizedInput> {
        .init(
            key: rawValue,
            input: input,
            staticTemplate: template
        )
    }
}
