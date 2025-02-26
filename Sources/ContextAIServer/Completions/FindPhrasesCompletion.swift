import ContextAI
import SwiftAI

extension FindPhrasesCompletion: @retroactive AIStreamCompletion {
    public var preferredModel: (any AIModel)? {
        SiliconFlow(apiKey: "", name: .custom("String"))
    }

    public func makeOutput(chunk: String, cache: inout String) -> (output: Output?, shouldStop: Bool) {
        cache += chunk

        if cache.contains("无符合要求的短语") {
            return (nil, true)
        }

        if let match = cache.firstMatch(of: #/%\^(.+?)\^\^(.*?)$/#) {
            let string = String(match.output.1)
            let output = _makeOutput(string: string)
            cache = String(match.output.2)

            assert(output.phrases.count == 1)

            return (output, false)
        }

        return (nil, false)
    }

    public func makeOutput(string: String) -> Output {
        fatalError("makeOutput(string:) should not be called")
    }

    private func _makeOutput(string: String) -> Output {
        let items = string.split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }

        let phrases = items.compactMap { item -> Output.Phrase? in
            let parts = item.split(separator: "#;;;")
                .map { $0.trimmingCharacters(in: .whitespaces) }

            guard parts.count == 5 else {
                print("parts@@ not 5", parts, parts.count)
                return nil
            }

            let lemma = parts[1]

            // has 3 or less white spaces
            guard lemma.components(separatedBy: .whitespaces).count <= 6 else {
                print("lemma too many words", lemma)
                return nil
            }

            let phrase = parts[0]
            let sense = handleMultipleLocales(String(parts[2]))
            let adja = phrase
            let syn = parts[3]
            let desc = parts[4]

            return .init(phrase: phrase, lemma: lemma, adja: adja, sense: sense, desc: desc, syn: syn)
        }

        if phrases.count != items.count {
            print("phrases count not equals", "expected \(items.count) phrases, got \(phrases.count)")
        }

        return .init(phrases: phrases)
    }
}
