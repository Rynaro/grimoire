# frozen_string_literal: true

require_relative '../../domain/repositories/folder_repository'
require_relative '../../domain/entities/folder'
require_relative '../../domain/value_objects/folder_name'
require 'fileutils'

module Grimoire
  module Infrastructure
    module Repositories
      class FileSystemFolderRepository < Domain::Repositories::FolderRepository
        def initialize(base_directory)
          @base_directory = base_directory
          ensure_directory_exists
        end

        def find_all
          Dir.glob(File.join(@base_directory, '*/')).map do |path|
            folder_name = File.basename(path)
            Domain::Entities::Folder.new(
              name: Domain::ValueObjects::FolderName.new(folder_name),
              path: path
            )
          end.sort_by { |f| f.name.to_s }
        end

        def find_by_name(name)
          folder_name = name.is_a?(Domain::ValueObjects::FolderName) ? name : Domain::ValueObjects::FolderName.new(name)
          folder_path = File.join(@base_directory, folder_name.to_s)
          
          return nil unless Dir.exist?(folder_path)

          Domain::Entities::Folder.new(
            name: folder_name,
            path: folder_path
          )
        end

        def save(folder)
          folder_name = folder.name.is_a?(Domain::ValueObjects::FolderName) ? folder.name : Domain::ValueObjects::FolderName.new(folder.name)
          folder_path = File.join(@base_directory, folder_name.to_s)
          FileUtils.mkdir_p(folder_path) unless Dir.exist?(folder_path)

          Domain::Entities::Folder.new(
            name: folder_name,
            path: folder_path
          )
        end

        def delete(name)
          folder_name = name.is_a?(Domain::ValueObjects::FolderName) ? name : Domain::ValueObjects::FolderName.new(name)
          folder_path = File.join(@base_directory, folder_name.to_s)
          FileUtils.rm_rf(folder_path) if Dir.exist?(folder_path)
        end

        def exists?(name)
          folder_name = name.is_a?(Domain::ValueObjects::FolderName) ? name : Domain::ValueObjects::FolderName.new(name)
          folder_path = File.join(@base_directory, folder_name.to_s)
          Dir.exist?(folder_path)
        end

        private

        def ensure_directory_exists
          FileUtils.mkdir_p(@base_directory) unless Dir.exist?(@base_directory)
        end
      end
    end
  end
end
