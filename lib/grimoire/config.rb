# frozen_string_literal: true

require "fileutils"
require "pathname"
require "yaml"

module Grimoire
  # Handles persistence of user preferences (paths, editor, etc.)
  class Config
    DEFAULT_CONFIG_PATH = File.expand_path("~/.config/grimoire/config.yml", ENV.fetch("HOME", "/"))
    DEFAULT_NOTES_ROOT = File.expand_path("~/Grimoire", ENV.fetch("HOME", "/"))

    attr_reader :config_path, :notes_root, :editor

    def initialize(config_path: DEFAULT_CONFIG_PATH, notes_root: nil, editor: nil)
      @config_path = Pathname(config_path)
      @notes_root = Pathname(notes_root || DEFAULT_NOTES_ROOT)
      @editor = editor || ENV.fetch("EDITOR", "nano")
    end

    def save!
      FileUtils.mkdir_p(config_path.dirname)
      payload = { "notes_root" => notes_root.to_s, "editor" => editor }
      config_path.write(payload.to_yaml)
    end

    def ensure_root!
      FileUtils.mkdir_p(notes_root)
      FileUtils.chmod(0o700, notes_root) if notes_root.exist?
    end

    def to_h
      { config_path: config_path.to_s, notes_root: notes_root.to_s, editor: }
    end

    def self.load(config_path: DEFAULT_CONFIG_PATH)
      path = Pathname(config_path)
      return new(config_path:) unless path.exist?

      raw = YAML.safe_load(path.read, permitted_classes: [Symbol], aliases: false) || {}
      new(
        config_path: path,
        notes_root: raw["notes_root"],
        editor: raw["editor"]
      )
    rescue Psych::Exception => e
      raise ConfigError, "Failed to parse #{path}: #{e.message}"
    end
  end
end
