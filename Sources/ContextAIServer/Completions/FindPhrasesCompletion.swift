import ContextAI
import SwiftAI

extension FindPhrasesCompletion: @retroactive AILLMCompletion {
    public func promptTemplate() async throws -> String {
        """
        ## 角色：
        您是一位精通英语语言学分析的专家，擅长从输入的语境文本中提取固定搭配、习语、常用短语、短语动词以及介词短语，并识别短语形态变化及溯其原型。

        ## 目标：
        从<语境>中精准提取**固定搭配、习语、常用短语、短语动词及介词短语**，并同时输出：
        1. **短语文本**: 语境中出现的实际短语形态的短语文本
        2. **原型**: 该短语的原型形式
        3. **释义**: 该短语的释义
        4. **近义词**: 1 个与语境最恰当的同义词或同义短语。
        5. **描述**: 用 1 句简短的<目标语言>准确描述<短语>在语境中表达的意思，不超过 100 字。帮助我理解语境， 多个目标语言用||分隔。

        ## 规则：
        ### 提取规范：
        1. **提取范围**：
        - 提取**日常学习和使用的短语**，这些短语多词组合的意义不能直接从单个词的字面意思推断出来。包括但不限于：**固定搭配**、**习语**、**常用短语**、**短语动词**、**介词短语**以及其他常见的表达方式
        - 如果文本中没有符合要求的短语，请直接输出“无符合要求的短语”。

        2. **形态识别**：
        - 识别时态变化（如：took over → take over）
        - 识别语态变化（如：being taken over → take over）
        - 识别单复数变化（如：make friends → make friends[原型]）
        - 识别代词/宾语位置（如：pick it up → pick up）
        - 识别分词形式（如：looking forward to → look forward to）

        3. **原型确定**：
        - 动词短语：使用不定式形式（例：go on → go on）
        - 名词短语：使用单数基本形式（例：apples and oranges → apple and orange）
        - 形容词短语：使用原级形式（例：more interesting → interesting）
        - 习语：保持标准词典形式（例：kicked the bucket → kick the bucket）

        ### 输出规范：
        %^短语文本#;;;原型#;;;释义#;;;近义词#;;;描述^^
        - 每个条目单独一行，按实际生活或考试中的难度从高到低排序
        - 释义和描述的多个目标语言用||分隔
        - 短语原型必须严格保持与语境中的原文拼写一致
        - 原型使用词典标准形式

        ## 示例：
        <语境>: The new manager took over the project last week and has been looking forward to implementing innovative ideas. Though he picked up some resistance initially, he managed to break the ice by making friends with key team members.
        <目标语言>: zh-CN||en-US

        **输出：**
        %^looking forward to#;;;look forward to#;;;期待；盼望||To feel excited about something that will happen#;;;anticipate with pleasure#;;;表达对未来计划实施的期待||Expresses anticipation for future implementation plans^^
        %^break the ice#;;;break the ice#;;;打破僵局；破冰||To do something to make people feel more comfortable#;;;ease tension#;;;描述通过建立关系缓解紧张氛围||Description: Describes relieving tension by building relationships^^
        %^making friends#;;;make friends#;;;交朋友；建立友谊||To form new friendships#;;;build relationships#;;;描述指与核心成员建立友好关系||Refers to establishing friendly relationships with core members^^

        ## <语境>: {{text}}
        ## <目标语言>: {{langs}}
        """
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

            let phrase = parts[0]
            let lemma = parts[1]
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
