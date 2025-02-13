import ContextAI
import ContextSharedModels
import Foundation
import SwiftAI

extension WordInfoCompletion: @retroactive AIStreamCompletion {
    public func initialOutput() -> Output {
        .init(synonym: "", desc: [:])
    }

    public func reduce(partialOutput: inout Output, chunk: Output) {
        partialOutput = chunk
    }

    public func makeOutput(chunk: String, accumulatedString: inout String) -> (output: Output?, shouldStop: Bool) {
        accumulatedString += chunk

        let reg = #/(.*?)(\^\^|$)/#

        guard let match = accumulatedString.firstMatch(of: reg) else {
            return (nil, false)
        }

        let items = String(match.output.1)
            .split(separator: "#;;;")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        guard items.count >= 2 else {
            return (nil, false)
        }

        let synonym = items[0]
        let descString = items[1]

        if !descString.isEmpty && accumulatedString.contains("^^") {
            let desc = handleMultipleLocales(descString)

            return (Output(synonym: synonym, desc: desc), true)
        }

        return (nil, false)
    }

    public func makeOutput(string: String) -> Output {
        fatalError()
    }
}
