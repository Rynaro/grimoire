# frozen_string_literal: true

require 'redcarpet'
require 'rouge'
require 'pastel'

module Grimoire
  module Renderers
    # Renders markdown to terminal-friendly output with syntax highlighting
    class MarkdownRenderer < Redcarpet::Render::Base
      def initialize
        super
        @pastel = Pastel.new
      end

      def normal_text(text)
        text
      end

      def header(text, level)
        case level
        when 1
          "\n#{@pastel.bold.cyan(text)}\n" + "#{@pastel.cyan('━' * [text.length, 60].min)}\n"
        when 2
          "\n#{@pastel.bold.yellow(text)}\n" + "#{@pastel.dim('─' * [text.length, 60].min)}\n"
        when 3
          "\n#{@pastel.bold.green(text)}\n"
        else
          "\n#{@pastel.bold(text)}\n"
        end
      end

      def paragraph(text)
        "#{text}\n\n"
      end

      def block_code(code, language)
        begin
          if language && !language.empty?
            lexer = Rouge::Lexer.find(language) || Rouge::Lexers::PlainText.new
            formatter = Rouge::Formatters::Terminal256.new
            "\n#{@pastel.dim('┌─ ' + language)}\n" +
            "#{formatter.format(lexer.lex(code))}\n" +
            "#{@pastel.dim('└─')}\n\n"
          else
            "\n#{@pastel.dim(code)}\n\n"
          end
        rescue
          "\n#{@pastel.dim(code)}\n\n"
        end
      end

      def block_quote(text)
        lines = text.split("\n")
        lines.map { |line| @pastel.dim("│ #{line}") }.join("\n") + "\n\n"
      end

      def list(contents, list_type)
        "\n#{contents}\n"
      end

      def list_item(text, list_type)
        prefix = list_type == :ordered ? "  #{@pastel.cyan('›')}" : "  #{@pastel.cyan('•')}"
        "#{prefix} #{text}\n"
      end

      def emphasis(text)
        @pastel.italic(text)
      end

      def double_emphasis(text)
        @pastel.bold(text)
      end

      def triple_emphasis(text)
        @pastel.bold.italic(text)
      end

      def codespan(code)
        @pastel.on_black.white(" #{code} ")
      end

      def link(link, title, content)
        @pastel.blue.underline(content) + @pastel.dim(" (#{link})")
      end

      def linebreak
        "\n"
      end

      def hrule
        "\n#{@pastel.dim('─' * 60)}\n\n"
      end

      # Handle [[note links]]
      def preprocess(text)
        text.gsub(/\[\[([^\]]+)\]\]/) do
          note_name = $1
          @pastel.cyan.bold("⟦#{note_name}⟧")
        end
      end

      def postprocess(text)
        text
      end
    end

    # Main markdown processor
    class MarkdownProcessor
      def self.render(markdown_text)
        renderer = MarkdownRenderer.new
        markdown = Redcarpet::Markdown.new(
          renderer,
          fenced_code_blocks: true,
          autolink: true,
          tables: true,
          strikethrough: true,
          space_after_headers: true,
          underline: true,
          highlight: true,
          footnotes: true
        )
        
        processed = renderer.preprocess(markdown_text)
        markdown.render(processed)
      end
    end
  end
end
