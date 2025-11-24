# frozen_string_literal: true

require "spec_helper"

RSpec.describe Grimoire::Application::Services::SearchNotes do
  let(:tmpdir) { Dir.mktmpdir }
  let(:repository) { Grimoire::Infrastructure::Filesystem::NotesRepository.new(tmpdir) }
  let(:search) { described_class.new(repository) }

  before do
    repository.create_note_in(folder: "", title: "Inbox")
    repository.create_note_in(folder: "", title: "Ideas")

    idea = repository.find_note("ideas.md")
    idea.write("# Ideas\n\n- Build [[Inbox]] sync\n- Explore Graph\n")
  end

  after do
    FileUtils.remove_entry(tmpdir)
  end

  describe "#by_title" do
    it "matches both titles and relative paths" do
      results = search.by_title("inb")

      expect(results.map(&:id)).to include("inbox.md")
    end
  end

  describe "#by_content" do
    it "returns line numbers and snippets" do
      matches = search.by_content("Graph")

      expect(matches.length).to eq(1)
      expect(matches.first.line_number).to be > 0
      expect(matches.first.line).to include("Graph")
    end
  end
end
