# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = 'grimoire'
  spec.version       = '0.1.0'
  spec.authors       = ['Grimoire Team']
  spec.email         = ['grimoire@example.com']

  spec.summary       = 'A beautiful terminal-based notes application'
  spec.description   = 'Grimoire is a terminal-based notes app with markdown support, note linking, and a beautiful TUI'
  spec.homepage      = 'https://github.com/grimoire/grimoire'
  spec.license       = 'MIT'

  spec.files         = Dir['lib/**/*', 'bin/*', 'README.md', 'LICENSE']
  spec.bindir        = 'bin'
  spec.executables   = ['grimoire']
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 3.0'

  spec.add_dependency 'curses', '~> 1.4'
  spec.add_dependency 'pastel', '~> 0.8'
  spec.add_dependency 'rouge', '~> 4.2'
  spec.add_dependency 'kramdown', '~> 2.4'
  spec.add_dependency 'kramdown-parser-gfm', '~> 1.1'
end
