import ContextAI
import ContextSharedModels
import SwiftAI

extension SelectSenseCompletion: @retroactive AIStreamCompletion {
    public func initialOutput() -> Output {
        .index(0)
    }

    public func reduce(partialOutput: inout Output, chunk: Output) {
        partialOutput = chunk
    }

    public func makeOutput(chunk: String, accumulatedString: inout String) -> (output: Output?, shouldStop: Bool) {
        accumulatedString += chunk

        if let match = accumulatedString.firstMatch(of: #/\^(.+?)\^/#) {
            let index = Int(match.output.1)

            if let index, index != 0 {
                return (.index(index), true)
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

        let localeString = String(match.output.1)
        let locale = CTLocale(localeString)
        let content = String(match.output.2)
        var finalLocale = locale

        if finalLocale == nil {
            if localeString == "简体中文" {
                finalLocale = .zh_Hans
            } else if localeString == "英语" {
                finalLocale = .en
            }
        }

        if let locale = finalLocale {
            acc[locale] = content
        }
    }
}
