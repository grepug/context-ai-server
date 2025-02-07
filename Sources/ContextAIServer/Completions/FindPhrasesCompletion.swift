import ContextAI
import SwiftAI

extension FindPhrasesCompletion: @retroactive AILLMCompletion {
    public func promptTemplate() async throws -> String {
        "Find"
    }

    //$^Bends over his knees#;;;en:to lean forward with the upper body, typically while sitting.||zh-Hans:弯下腰^^
    // $^Turning his eyes upward#;;;en:to look upwards, often with a particular expression.||zh-Hans:抬眼向上看^^
    // $^Favorite expressions#;;;en:phrases or sayings that someone frequently uses.||zh-Hans:最喜欢的表达方式^^
    // $^Build global businesses#;;;en:to create or develop companies that operate internationally.||zh-Hans:建立全球业务^^
    public func makeOutput(string: String) -> Output {
        let items = string.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespaces) }

        let phrases = items.map { item -> Output.Phrase in
            guard let match = item.firstMatch(of: #/\$(\^.+?\^)#;(\w+):(.+?)\^/#) else {
                fatalError("Invalid phrase format")
            }

            let phrase = String(match.output.1)
            let lemma = String(match.output.2)
            let adja = String(match.output.3)
            let sense = handleMultipleLocales(adja)

            return .init(phrase: phrase, lemma: lemma, adja: adja, sense: sense)
        }

        return .init(phrases: phrases)
    }
}
