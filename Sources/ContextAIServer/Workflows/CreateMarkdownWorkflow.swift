import Collections
import ContextAI
import ContextSharedModels
import Foundation
import SwiftAI
import SwiftAIServer

extension CreateMarkdownWorkflow: @retroactive AIStreamWorkflow {
    public protocol ToolsKind: Sendable {
        func makeMarkdown(text: String) async throws -> String
    }

    public typealias Tools = ToolsKind

    public func streamChunk(environment: AIWorkflowEnvironment, tools: Tools) -> AsyncThrowingStream<StreamChunk, any Error> {
        let (newStream, continuation) = AsyncThrowingStream<StreamChunk, any Error>.makeStream()

        Task {
            do {
                let markdown = try await tools.makeMarkdown(text: input.text)
                let completion = ConvertTextToMarkdownCompletion(input: .init(text: markdown))
                let stream = try await environment.client.stream(completion: completion)

                for try await chunk in stream {
                    continuation.yield(.init(markdown: chunk.markdown))
                }

                continuation.finish()
            } catch {
                continuation.finish(throwing: error)
            }
        }

        return newStream
    }
}
