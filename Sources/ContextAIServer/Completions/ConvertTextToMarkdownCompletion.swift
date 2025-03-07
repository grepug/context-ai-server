import ContextAI
import SwiftAI

extension ConvertTextToMarkdownCompletion: @retroactive AIStreamCompletion {
    public func makeOutput(chunk: String, cache: inout String) -> (output: Output?, shouldStop: Bool) {
        cache += chunk

        return (.init(markdown: cache), false)
    }

    public func makeOutput(string: String) -> Output {
        .init(markdown: string)
    }
}
