import Collections
import ContextAI
import ContextSharedModels
import Foundation
import SwiftAI
import SwiftAIServer

extension WordSuggestionsAndLookupWorkflow: @retroactive AIStreamWorkflow {
    public protocol ToolsKind: Sendable {
        func tokenizedAndFiltered(_ text: String) async throws -> [ContextModel.TokenItem]
        func wordFrequencies(_ tokens: [ContextModel.TokenItem]) async throws -> [UUID: Int]
    }

    public typealias Tools = ToolsKind

    public func streamChunk(client: any AICompletionClientKind, tools: Tools) -> AsyncThrowingStream<StreamChunk, any Error> {
        Implementation(input: input, client: client, tools: tools).streamChunk()
    }
}

extension WordSuggestionsAndLookupWorkflow {
    struct Implementation {
        typealias Chunk = WordSuggestionsAndLookupWorkflow.StreamChunk

        let input: WordSuggestionsAndLookupWorkflow.Input
        let client: any AICompletionClientKind
        let tools: WordSuggestionsAndLookupWorkflow.Tools

        func streamChunk() -> AsyncThrowingStream<Chunk, any Error> {
            let (newStream, continuation) = AsyncThrowingStream<Chunk, any Error>.makeStream()

            Task {
                do {
                    async let phrasesChunk = try await getSuggestedPhrasesChunk()
                    async let wordsChunk = try await getSuggestedWordsChunk()

                    let chunks = try await [phrasesChunk, wordsChunk]

                    continuation.yield(chunks[0])
                    continuation.yield(chunks[1])

                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }

            return newStream
        }
    }
}

extension WordSuggestionsAndLookupWorkflow.Implementation {
    func getSuggestedWordsChunk() async throws -> Chunk {
        let tokens = try await tools.tokenizedAndFiltered(input.text)
        let tokenFrequencies = try await tools.wordFrequencies(tokens)

        let orderedTokenIds = tokenFrequencies.keys.sorted { lhs, rhs in
            let lhsFreq = tokenFrequencies[lhs, default: 0]
            let rhsFreq = tokenFrequencies[rhs, default: 0]

            return lhsFreq < rhsFreq
        }

        let finalTokens =
            orderedTokenIds
            .prefix(3)
            .compactMap { id in tokens.first { $0.id == id } }

        let items: [ContextModel.ContextSegment] = try await withThrowingTaskGroup(of: ContextModel.ContextSegment.self) { group in
            for token in finalTokens {
                group.addTask {
                    let sense = try await fetchAISense(token: token)

                    return ContextModel.ContextSegment(
                        id: token.id,
                        segment: .textRange(.init(array: token.range)),
                        text: token.text,
                        sense: sense
                    )
                }
            }

            return try await group.reduce(into: []) { partialResult, item in
                partialResult.append(item)
            }
        }

        let suggestedItems = items.reduce(into: [:]) { partialResult, item in
            partialResult[item.id] = item
        }

        return .init(suggestedItems: suggestedItems)
    }

    func getSuggestedPhrasesChunk() async throws -> Chunk {
        let completion = FindPhrasesCompletion(input: .init(text: input.text, langs: input.langs))
        let phrases = try await client.generate(completion: completion).phrases

        let items: [UUID: ContextModel.ContextSegment] = phrases.reduce(into: [:]) { partialResult, item in
            guard let range = getRange(text: item.phrase, adjacentText: item.adja, wholeText: input.text) else {
                return
            }

            let seg = ContextModel.ContextSegment(
                id: .init(),
                segment: .textRange(.init(array: range)),
                text: item.phrase,
                sense: item.sense
            )
            partialResult[seg.id] = seg
        }

        return Chunk(suggestedItems: items)
    }

    private func getRange(text: String, adjacentText: String, wholeText: String) -> [Int]? {
        // First find the range of adjacentText which contains our target text
        guard let adjacentRange = wholeText.range(of: adjacentText) else {
            return nil
        }

        // Then find the target text within the adjacent text range
        let adjacentSubstring = wholeText[adjacentRange]
        guard let textRange = adjacentSubstring.range(of: text) else {
            return nil
        }

        // Calculate absolute positions in wholeText
        let start = wholeText.distance(from: wholeText.startIndex, to: adjacentRange.lowerBound) + adjacentSubstring.distance(from: adjacentSubstring.startIndex, to: textRange.lowerBound)
        let end = wholeText.distance(from: wholeText.startIndex, to: adjacentRange.lowerBound) + adjacentSubstring.distance(from: adjacentSubstring.startIndex, to: textRange.upperBound)

        return [start, end]
    }
}

extension WordSuggestionsAndLookupWorkflow.Implementation {
    func fetchAISense(token: ContextModel.TokenItem) async throws -> LocaledStringDict {
        let completion = SelectSenseCompletion(input: .init(text: input.text, word: token.text, adja: token.adjacentText, sense: ""))
        let output = try await client.generate(completion: completion)

        switch output {
        case .aiSense(let dict):
            return dict
        case .index:
            return [:]
        }
    }
}
