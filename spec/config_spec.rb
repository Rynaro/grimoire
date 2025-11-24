# frozen_string_literal: true

require "spec_helper"

RSpec.describe Grimoire::Config do
  let(:tmpdir) { Dir.mktmpdir }
  let(:config_path) { File.join(tmpdir, "config.yml") }

  after do
    FileUtils.remove_entry(tmpdir)
  end

  it "falls back to defaults when config is missing" do
    config = described_class.load(config_path:)

    expect(config.notes_root).to eq(Pathname(Grimoire::Config::DEFAULT_NOTES_ROOT))
  end

  it "persists custom settings" do
    config = described_class.new(config_path:, notes_root: "/tmp/grimoire", editor: "vim")
    config.save!

    reloaded = described_class.load(config_path:)

    expect(reloaded.editor).to eq("vim")
    expect(reloaded.notes_root.to_s).to eq("/tmp/grimoire")
  end
end
