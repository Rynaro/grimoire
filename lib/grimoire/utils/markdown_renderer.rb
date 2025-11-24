# frozen_string_literal: true

require 'kramdown'
require 'kramdown-parser-gfm'
require 'rouge'

module Grimoire
  module Utils
    class MarkdownRenderer
      def initialize
        @formatter = Rouge::Formatters::Terminal256.new
      end

      def render_to_text(markdown)
        # Convert markdown to plain text with formatting hints
        doc = Kramdown::Document.new(markdown, input: 'GFM')
        doc.to_kramdown
      end

      def highlight_code(code, language = 'text')
        lexer = Rouge::Lexer.find(language) || Rouge::Lexers::PlainText
        @formatter.format(lexer.lex(code))
      rescue StandardError
        code
      end

      def parse_markdown(markdown)
        # Parse markdown and return structured data for rendering
        doc = Kramdown::Document.new(markdown, input: 'GFM')
        doc.root
      end

      def extract_links(markdown)
        links = []
        
        # Wiki-style links
        markdown.scan(/\[\[([^\]]+)\]\]/) do |match|
          links << { type: :wiki, name: match[0] }
        end

        # Markdown links
        markdown.scan(/\[([^\]]+)\]\(([^)]+)\)/) do |text, url|
          links << { type: :markdown, text: text, url: url }
        end

        links
      end
    end
  end
end
