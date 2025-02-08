// import AsyncAlgorithms
// import ContextAI
// import ContextSharedModels
// import Foundation
// import SwiftAI
// import SwiftAIServer

// public struct AnyAITask: AITask {
//     public static var kind: String { "" }
//     public var input: AnyCodable
//     public typealias Output = AnyCodable

//     public init(input: AnyCodable) {
//         self.input = input
//     }
// }

// public struct ResponseBuilder {
//     let data: Data
//     let client: any AICompletionClientKind
//     let wordSuggestionsAndLookupWorkflowToolType: any WordSuggestionsAndLookupWorkflow.Tools

//     func makeWorkflowResponseStream<T: AIStreamWorkflow>(task: T, input: AnyCodable, tools: T.Tools) throws -> AsyncThrowingStream<Data, Error> {
//         let workflow = T.init(input: try input.decoding(as: T.Input.self))
//         return workflow.streamChunk(client: client, tools: tools)
//     }

//     var streamTasks: [any AIStreamTask.Type] {
//         [
//             WordSuggestionsAndLookupWorkflow.self
//         ]
//     }

//     func makeResponseStream() async throws {
//         let content = try JSONDecoder().decode(AIClientRequestContent<AnyAITask>.self, from: data)
//         let kind = content.kind
//         let task = content.task
//         let input = task.input

//         if let key = TextCompletionKey(rawValue: kind) {
//             let completion = key.makeCompletion(input: input.params)

//             await client.stream(completion: completion).map { chunk in
//                 try chunk.toData()
//             }

//             return
//         }

//         streamTasks[0].init(input: input)

//         fatalError()
//     }
// }

// extension AnyCodable: @retroactive AITaskInput {}
