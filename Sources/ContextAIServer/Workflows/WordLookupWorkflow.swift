import Collections
import ContextAI
import ContextSharedModels
import Foundation
import SwiftAI
import SwiftAIServer

extension WordLookupWorkflow: @retroactive AIStreamWorkflow {
    public protocol ToolsKind: Sendable {
        func legacy_fetchEntry(token: ContextModel.TokenItem) async throws -> ContextModel.Entry?
    }

    public func streamChunk(client: any AICompletionClientKind, tools: ToolsKind) -> AsyncThrowingStream<Output, any Error> {
        Implementation(input: input, client: client, tools: tools).streamChunk()
    }
}

extension WordLookupWorkflow {
    struct Implementation {
        typealias Chunk = WordLookupWorkflow.StreamChunk

        let input: WordLookupWorkflow.Input
        let client: any AICompletionClientKind
        let tools: WordLookupWorkflow.Tools

        func streamChunk() -> AsyncThrowingStream<Chunk, any Error> {
            fatalError("WordLookupWorkflow is not implemented")
        }
    }
}
