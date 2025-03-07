import Collections
import ContextAI
import ContextSharedModels
import Foundation
import SwiftAI
import SwiftAIServer

extension CreateMarkdownWorkflow: @retroactive AIStreamWorkflow {
    public func streamChunk(environment: AIWorkflowEnvironment, tools: ()) -> AsyncThrowingStream<StreamChunk, any Error> {
        let completion = ConvertTextToMarkdownCompletion(input: .init(text: input.text))
        let (newStream, continuation) = AsyncThrowingStream<StreamChunk, any Error>.makeStream()

        Task {
            do {
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
