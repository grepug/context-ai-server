import Collections
import ContextAI
import ContextSharedModels
import Foundation
import Logging
import SwiftAI
import SwiftAIServer

extension WordSuggestionsAndLookupWorkflow: @retroactive AIStreamWorkflow {
    public protocol ToolsKind: Sendable {
        func tokenizedAndFiltered(_ text: String) async throws -> [ContextModel.TokenItem]
        func wordFrequencies(_ tokens: [ContextModel.TokenItem]) async throws -> [UUID: Int]

        func legacy_fetchEntry(token: ContextModel.TokenItem) async throws -> ContextModel.Entry?
    }

    public func streamChunk(environment: AIWorkflowEnvironment, tools: ToolsKind) -> AsyncThrowingStream<StreamChunk, any Error> {
        Implementation(input: input, environment: environment, tools: tools).streamChunk()
    }
}

extension WordSuggestionsAndLookupWorkflow {
    struct Implementation {
        typealias Chunk = WordSuggestionsAndLookupWorkflow.StreamChunk

        let input: WordSuggestionsAndLookupWorkflow.Input
        let environment: AIWorkflowEnvironment
        let tools: WordSuggestionsAndLookupWorkflow.Tools

        var logger: Logger {
            environment.logger
        }

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

        let items: [ContextModel.ContextSegment] = try await withThrowingTaskGroup(of: ContextModel.ContextSegment?.self) { group in
            for token in finalTokens {
                group.addTask {
                    let sense = try await fetchWordSense(token: token)

                    var segment = ContextModel.ContextSegment(
                        id: token.id,
                        segment: .textRange(.init(array: token.range)),
                        text: token.text
                    )

                    switch sense {
                    case .entrySense(let entrySense):
                        segment.entrySense = entrySense
                    case .aiSense(let aiSense):
                        segment.sense = aiSense
                    case nil:
                        return nil
                    }

                    return segment
                }
            }

            return try await group.reduce(into: []) { partialResult, item in
                if let item {
                    partialResult.append(item)
                }
            }
        }

        let suggestedItems = items.reduce(into: [:]) { partialResult, item in
            partialResult[item.id] = item
        }

        return .init(suggestedItems: suggestedItems)
    }

    func getSuggestedPhrasesChunk() async throws -> Chunk {
        let completion = FindPhrasesCompletion(input: .init(text: input.text, langs: input.langs))
        let phrases = try await environment.client.generate(completion: completion).phrases

        let items: [UUID: ContextModel.ContextSegment] = phrases.reduce(into: [:]) { partialResult, item in
            guard let range = getRange(text: item.phrase, adjacentText: item.adja, wholeText: input.text) else {
                print("Could not find range for \(item.phrase), adja: \(item.adja), wholeText: \(input.text)")
                return
            }

            let seg = ContextModel.ContextSegment(
                id: .init(),
                segment: .textRange(.init(array: range)),
                text: item.phrase,
                lemma: item.lemma,
                synonym: item.syn,
                sense: item.sense,
                desc: handleMultipleLocales(item.desc)
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
    enum SenseOutput {
        case entrySense(ContextModel.EntrySense)
        case aiSense(LocaledStringDict)
    }

    func fetchAISense(token: ContextModel.TokenItem, senses: [ContextModel.EntrySense], promptSense: String) async throws -> SenseOutput? {
        let input = SelectSenseCompletion.Input(
            text: input.text,
            word: token.text,
            adja: token.adjacentText,
            sense: promptSense
        )
        let completion = SelectSenseCompletion(input: input)
        let stream = await environment.client.stream(completion: completion)

        for try await output in stream {
            switch output {
            case .aiSense(let dict):
                return .aiSense(dict)
            case .index(let index):
                if senses.count >= index {
                    return .entrySense(senses[index - 1])
                }
            }
        }

        return nil
    }
}

extension WordSuggestionsAndLookupWorkflow.Implementation {
    private func fetchWordSense(token: ContextModel.TokenItem) async throws -> SenseOutput? {
        let entry = try await tools.legacy_fetchEntry(token: token)

        let senses =
            entry?.senses.filter { sense in
                sense.localizedTexts.contains(where: { $0.locale == .en })
            } ?? []

        let prompt = senses.indices.map { index in
            let sense = senses[index]
            return "^\(index + 1)^: \(sense.pos.rawValue), \(sense.localizedTexts.first(where: { $0.locale == .en })!.text)"
        }.joined(separator: "\n")

        let result = try await fetchAISense(token: token, senses: senses, promptSense: prompt)

        if let result {
            return result
        }

        return try await fetchAISense(token: token, senses: senses, promptSense: "")
    }
}
