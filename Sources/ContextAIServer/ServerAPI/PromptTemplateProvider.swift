import ContextAI
import SwiftAI
import SwiftAIServer

public struct PromptTemplateProvider: AIPromptTemplateProvider {
    public func promptTemplate(forKey key: String) async throws(AIPromptTemplateProviderError) -> String? {
        if let key = ExtraInfoTextCompletion.Key(rawValue: key) {
            switch key {
            case .collocations: return PromptTemplates.collocations
            case .memorizingHelper: return PromptTemplates.memorizingHelper
            case .thesaurus: return PromptTemplates.thesaurus
            case .usages: return PromptTemplates.usages
            }
        }

        switch key {
        case StudyNotesTextCompletion.kind:
            return PromptTemplates.studyNotes
        case TranslatorTextCompletion.kind:
            return PromptTemplates.translator
        case FindPhrasesCompletion.kind:
            return
                """
                ## 角色：
                您是一位精通英语语言学分析的专家，擅长从输入的语境文本中提取日常学习和生活常用的固定搭配、习语、常用短语、短语动词以及介词短语，并识别短语形态变化及溯其原型。

                ## 目标：
                从<语境>中精准提取 5 个单词以内的**固定搭配、习语、短语动词及介词短语**，并同时输出：
                1. **短语文本**: 和语境中一致的实际短语的形态的文本，短语中每个单词的形态、数量以及排序必须严格保持与语境中的原文拼写一致。
                2. **原型**: 该短语的原型形式，原型需要使用词典标准形式。
                3. **释义**: 用<目标语言>给出该短语的释义， 不同目标语言用||分隔。
                4. **近义词**: 1 个与语境最恰当的同义词或同义短语。
                5. **描述**: 用 1 句简短的<目标语言>准确描述<短语>在语境中表达的意思，不超过 100 字。帮助我理解语境， 不同的多个目标语言用||分隔。

                ## 规则：
                ### 提取规范：
                1. **提取范围**：
                - 提取**日常学习和使用的短语**，这些短语多词组合的意义无法直接从单个词的字面意思推断出来。包括但不限于：**固定搭配**、**习语**、**短语动词**、**介词短语**
                - 提取的短语的词数不超过 5 个词

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
                - 不同的多个<目标语言>用||分隔
                - 符合要求的短语数量为 0 时，直接输出“无符合要求的短语”，不要输出其他任何内容。
                - 输出规范和格式严格参考示例，输出不符合要求的格式你会受到惩罚。
                - 提取的短语中的单词数超过 5 个单词，你会受到惩罚。
                - 你必须严格按照要求输出内容，无论任何情况，不要做任何调整，不要输出任何规范以外的任何内容。如果你输出了规范以外的内容，你将会受到惩罚。

                ## 示例：
                <语境>: The new manager took over the project last week and has been looking forward to implementing innovative ideas that would set the project apart from others. Though he picked up some resistance initially, he managed to break the ice by making friends with key team members, a move that set him apart from his predecessors.
                <目标语言>: zh-Hans, en

                **输出：**
                %^break the ice#;;;break the ice#;;;zh-Hans: 打破僵局；破冰||en: To do something to make people feel more comfortable#;;;ease tension#;;;zh-Hans: 描述通过建立关系缓解紧张氛围||en: Describes relieving tension by building relationships^^
                %^looking forward to#;;;look forward to#;;;zh-Hans: 期待；盼望||en: To feel excited about something that will happen#;;;anticipate with pleasure#;;;zh-Hans: 表达对未来计划实施的期待||en: Expresses anticipation for future implementation plans^^
                %^set the project apart from#;;;set...apart from#;;;zh-Hans: 使与众不同；使区别开来||en: To make something different or unique from others#;;;distinguish from#;;;zh-Hans: 描述让公司区别于竞争对手的策略||en: Describes strategies that differentiate the company from its competitors^^
                %^making friends#;;;make friends#;;;zh-Hans: 交朋友；建立友谊||en: To form new friendships#;;;build relationships#;;;zh-Hans: 描述指与核心成员建立友好关系||en: Refers to establishing friendly relationships with core members^^

                ## 示例：
                <语境>: I see you drive very carefully.
                <目标语言>: zh-Hans, en

                **输出：**
                无符合要求的短语


                ## <语境>: {{text}}
                ## <目标语言>: {{langs}}
                """
        case SelectSenseCompletion.kind:
            return PromptTemplates.selectSense
        case WordInfoCompletion.kind:
            return PromptTemplates.wordInfo
        case CreateMarkdownWorkflow.kind:
            return PromptTemplates.createMarkdown
        default:
            return nil
        }
    }

    public init() {}
}
