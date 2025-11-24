# frozen_string_literal: true

require "spec_helper"

RSpec.describe Grimoire::Infrastructure::Filesystem::NotesRepository do
  let(:tmpdir) { Dir.mktmpdir }
  let(:repository) { described_class.new(tmpdir) }

  after do
    FileUtils.remove_entry(tmpdir)
  end

  describe "#create_note_in" do
    it "creates markdown files with the requested title" do
      note = repository.create_note_in(folder: "", title: "Inbox Zero")

      expect(note.path).to exist_on_fs
      expect(note.content).to include("# Inbox Zero")
    end

    it "prevents overwriting an existing note" do
      repository.create_note_in(folder: "", title: "Daily Log")

      expect do
        repository.create_note_in(folder: "", title: "Daily Log")
      end.to raise_error(Grimoire::UnsafeOperationError)
    end
  end

  describe "#resolve_link" do
    it "prefers notes in the current folder when duplicates exist" do
      repository.create_note_in(folder: "", title: "Roadmap")
      current = repository.create_note_in(folder: "projects", title: "Roadmap")

      resolved = repository.resolve_link("Roadmap", current_folder: "projects")

      expect(resolved.id).to eq(current.id)
    end

    it "returns nil when nothing matches" do
      expect(repository.resolve_link("Missing")).to be_nil
    end
  end

  describe "#delete_note" do
    it "cleans up empty folders after removing the file" do
      repository.create_note_in(folder: "scratch", title: "Temp")
      repository.delete_note("scratch/temp.md")

      expect(repository.subfolders).not_to include("scratch")
    end
  end
end

RSpec::Matchers.define :exist_on_fs do
  match do |path|
    File.exist?(path)
  end

  failure_message do |path|
    "expected #{path} to exist on disk"
  end
end
