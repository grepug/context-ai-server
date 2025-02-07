import ContextAI
import SwiftAI

extension FindPhrasesCompletion: @retroactive AILLMCompletion {
    public func promptTemplate() async throws -> String {
        "Find"
    }

    public func makeOutput(string: String) -> Output {
        .init(phrases: [])
    }

    public func makeOutput(chunk: String, accumulatedString: inout String) -> (output: Output?, shouldStop: Bool) {
        fatalError("Not implemented")
    }
}
