# frozen_string_literal: true

module Grimoire
  module Domain
    module Services
      class LinkExtractor
        Link = Struct.new(:type, :name, :text, :url, keyword_init: true)

        def extract(content)
          links = []
          
          # Wiki-style links: [[note name]]
          content.to_s.scan(/\[\[([^\]]+)\]\]/) do |match|
            links << Link.new(
              type: :wiki,
              name: match[0].strip,
              text: match[0].strip,
              url: nil
            )
          end

          # Markdown links: [text](note.md) or [text](folder/note.md)
          content.to_s.scan(/\[([^\]]+)\]\(([^)]+)\)/) do |text, url|
            note_name = File.basename(url, '.md')
            links << Link.new(
              type: :markdown,
              name: note_name,
              text: text,
              url: url
            )
          end

          links.uniq
        end
      end
    end
  end
end
