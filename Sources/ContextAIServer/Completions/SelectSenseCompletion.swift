import ContextAI
import ContextSharedModels
import SwiftAI

extension SelectSenseCompletion: @retroactive AIStreamCompletion {
    public func promptTemplate() async throws -> String {
        PromptTemplates.selectSense
    }

    public func makeOutput(chunk: String, accumulatedString: inout String) -> (output: Output?, shouldStop: Bool) {
        accumulatedString += chunk

        if let match = accumulatedString.firstMatch(of: #/\^(.+?)\^/#) {
            let index = Int(match.output.1)

            if index != 0 {
                return (index.map { .index($0) }, true)
            }
        }

        if let match = accumulatedString.firstMatch(of: #/\%(.+?)\%/#) {
            return (.aiSense(handleMultipleLocales(String(match.output.1))), true)
        }

        return (nil, false)
    }

    public func makeOutput(string: String) -> Output {
        if let match = string.firstMatch(of: #/\^(.+?)\^/#) {
            if let index = Int(match.output.1), index != 0 {
                return .index(index)
            }
        }

        if let match = string.firstMatch(of: #/\%(.+?)\%/#) {
            return .aiSense(handleMultipleLocales(String(match.output.1)))
        }

        return .aiSense([:])
    }
}

func handleMultipleLocales(_ str: String) -> LocaledStringDict {
    let items = str.split(separator: "||").map { $0.trimmingCharacters(in: .whitespaces) }

    return items.reduce(into: [:]) { (acc, el) in
        guard let match = el.firstMatch(of: #/(.+?):\s?(.+?)$/#) else {
            return
        }

        let locale = CTLocale(String(match.output.1))
        let content = String(match.output.2)

        if let locale {
            acc[locale] = content
        }
    }
}
