# frozen_string_literal: true

require "optparse"

module Grimoire
  # Entry point invoked by bin/grimoire
  class CLI
    def self.start(argv)
      new(argv).run
    end

    def initialize(argv)
      @argv = argv
      @options = {
        root: nil,
        editor: nil,
        config_path: Grimoire::Config::DEFAULT_CONFIG_PATH,
        init_only: false,
        version: false
      }
    end

    def run
      parser.parse!(argv)

      return puts(Grimoire::VERSION) if options[:version]

      config = load_config
      config.ensure_root!

      if options[:init_only]
        config.save!
        puts "Config saved to #{config.config_path}"
        return
      end

      repository = Repository.new(config.notes_root)
      search = Search.new(repository)
      tui = TUI.new(repository:, config:, search:)
      tui.start
    rescue OptionParser::ParseError => e
      warn e.message
      warn parser
      exit 1
    rescue Error => e
      warn "grimoire: #{e.message}"
      exit 1
    end

    private

    attr_reader :argv, :options

    def load_config
      config = Config.load(config_path: options[:config_path])
      notes_root = options[:root] || config.notes_root
      editor = options[:editor] || config.editor

      Config.new(config_path: config.config_path, notes_root:, editor:)
    end

    def parser
      @parser ||= OptionParser.new do |opt|
        opt.banner = "Usage: grimoire [options]"
        opt.on("--root PATH", "Override notes root directory") { |path| options[:root] = path }
        opt.on("--editor CMD", "Command used for editing (defaults to $EDITOR)") { |cmd| options[:editor] = cmd }
        opt.on("--config PATH", "Custom config file location") { |path| options[:config_path] = path }
        opt.on("--init", "Write config file and exit") { options[:init_only] = true }
        opt.on("-v", "--version", "Print version") { options[:version] = true }
        opt.on("-h", "--help", "Show this help") do
          puts opt
          exit
        end
      end
    end
  end
end
