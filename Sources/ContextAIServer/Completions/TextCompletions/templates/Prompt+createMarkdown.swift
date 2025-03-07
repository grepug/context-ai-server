extension PromptTemplates {
    static let createMarkdown: String = {
        """
        Optimized English Learning Text Processor

        Please transform web content into clean English learning material by following these steps:

        Content Extraction & Localization

        If text contains bilingual content (e.g., Chinese-English parallel text), retain ONLY English
        For monolingual non-English text: Translate to natural English
        For multi-language content: Preserve English and remove all other language versions
        Web Element Removal
        Remove all:

        Navigation menus
        Sidebars/additional columns
        Footer content
        Images/visual elements
        Social media links/widgets
        Interactive elements (comments, forms)
        Metadata/SEO text
        Text Refinement

        Normalize whitespace: Trim extra line breaks → Single empty line between paragraphs
        Convert special quotes/characters → Standard English punctuation
        Standardize hyphen usage (en-dash/em-dash → regular hyphen)
        Preserve meaningful line breaks in poetry/code/texts where structure matters
        Structural Enhancement

        Add explicit title: "# " + {page_title} (If no title exists: Create a descriptive English title at document start)
        Maintain hierarchy: Preserve original heading levels (H1-H6 → #, ##, etc.)
        Ensure text flow: Logical paragraph division with clear topic transitions
        Output Specification

        Final format: Clean markdown
        Content: Only essential text body
        Language: 100% English
        Prohibited:
        Explanatory notes
        Processing comments
        Markdown annotations
        Empty brackets from removed elements

        Input: {{text}}
        """
    }()
}
