# frozen_string_literal: true

module Grimoire
  Error = Class.new(StandardError)
  ConfigError = Class.new(Error)
  NoteNotFoundError = Class.new(Error)
  UnsafeOperationError = Class.new(Error)
end
