# frozen_string_literal: true

require "pathname"

module Grimoire
  # Represents a single markdown note on disk
  class Note
    LINK_PATTERN = /\[\[([^\]]+)\]\]/.freeze

    attr_reader :path, :root

    def initialize(path, root:)
      @path = Pathname(path).expand_path
      @root = Pathname(root).expand_path
    end

    def id
      path.relative_path_from(root).to_s
    end

    def folder
      path.dirname.relative_path_from(root).to_s
    end

    def exists?
      path.exist?
    end

    def title
      heading = metadata[:heading]
      return heading unless heading.to_s.empty?

      fallback = File.basename(path, path.extname)
      fallback.tr("_-", " ").split.map(&:capitalize).join(" ")
    end

    def content
      path.read
    end

    def lines
      content.lines
    end

    def links
      content.scan(LINK_PATTERN).flatten.uniq
    end

    def write(content)
      path.dirname.mkpath
      path.write(content)
      @metadata = nil
    end

    def delete
      path.delete if path.exist?
    end

    def to_h
      { id:, title:, folder:, path: path.to_s }
    end

    private

    def metadata
      @metadata ||= extract_metadata
    end

    def extract_metadata
      heading = nil
      return { heading: nil } unless path.exist?

      path.open do |io|
        io.each_line do |line|
          next unless line.start_with?("#")

          heading = line.split("#", 2).last&.strip
          break
        end
      end
      { heading: heading }
    end
  end
end
