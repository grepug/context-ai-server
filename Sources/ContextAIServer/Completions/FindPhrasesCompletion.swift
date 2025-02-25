import ContextAI
import SwiftAI

extension FindPhrasesCompletion: @retroactive AILLMCompletion {
    public var preferredModel: (any AIModel)? {
        SiliconFlow(apiKey: "", name: .custom("String"))
    }

    public func makeOutput(string: String) -> Output {
        let items = string.split(separator: "\n")
            .map {
                $0.trimmingCharacters(in: .whitespaces)
                    .replacingOccurrences(of: "%^", with: "")
                    .replacingOccurrences(of: "^^", with: "")
            }

        let phrases = items.compactMap { item -> Output.Phrase? in
            let parts = item.split(separator: "#;;;")
                .map { $0.trimmingCharacters(in: .whitespaces) }

            guard parts.count == 5 else {
                print("parts@@ not 5", parts, parts.count)
                return nil
            }

            let lemma = parts[1]

            // has 3 or less white spaces
            guard lemma.components(separatedBy: .whitespaces).count <= 3 else {
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
