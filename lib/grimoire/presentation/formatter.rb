# frozen_string_literal: true

module Grimoire
  module Presentation
    # Lightweight Markdown aware formatter for terminal output
    class Formatter
      Token = Struct.new(:text, :color, :type, :payload, keyword_init: true)

      SYNTAX = {
        heading: /\A#+\s+/,
        list: /\A\s*[-*+]\s+/,
        checkbox: /\A\s*[-*+]\s+\[( |x|X)\]\s+/,
        quote: /\A>\s+/,
        code_fence: /\A```/,
        link: /\[\[(.+?)\]\]/,
        bold: /\*\*(.+?)\*\*/
      }.freeze

      def self.highlight(line, inside_code:)
        stripped = line.chomp
        if inside_code
          [Token.new(text: stripped, color: :cyan, type: :code)]
        elsif stripped.match?(SYNTAX[:code_fence])
          [Token.new(text: stripped, color: :magenta, type: :code_fence)]
        elsif (match = stripped.match(SYNTAX[:heading]))
          [
            Token.new(text: match[0], color: :yellow, type: :heading_prefix),
            Token.new(text: stripped.delete_prefix(match[0]), color: :white, type: :heading_text)
          ]
        elsif (match = stripped.match(SYNTAX[:checkbox]))
          [
            Token.new(text: match[0], color: :cyan, type: :checkbox),
            *highlight_inline(stripped.delete_prefix(match[0]))
          ]
        elsif (match = stripped.match(SYNTAX[:list]))
          [
            Token.new(text: match[0], color: :cyan, type: :list_marker),
            *highlight_inline(stripped.delete_prefix(match[0]))
          ]
        elsif stripped.match?(SYNTAX[:quote])
          [Token.new(text: stripped, color: :blue, type: :quote)]
        else
          highlight_inline(stripped)
        end
      end

      def self.highlight_inline(text)
        tokens = []
        cursor = 0
        while cursor < text.length
          link_match = SYNTAX[:link].match(text, cursor)
          bold_match = SYNTAX[:bold].match(text, cursor)
          chosen = [link_match, bold_match].compact.min_by(&:begin)
          break unless chosen

          if chosen.begin(0) > cursor
            tokens << Token.new(text: text[cursor...chosen.begin(0)], color: :white, type: :text)
          end

          case chosen
          when link_match
            tokens << Token.new(text: chosen[0], color: :green, type: :link, payload: { target: chosen[1] })
          else
            tokens << Token.new(text: chosen[1], color: :yellow, type: :strong)
          end

          cursor = chosen.end(0)
        end

        if cursor < text.length
          tokens << Token.new(text: text[cursor..], color: :white, type: :text)
        end

        tokens.empty? ? [Token.new(text:, color: :white, type: :text)] : tokens
      end
    end
  end
end
