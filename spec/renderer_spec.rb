# frozen_string_literal: true

require "pdf-reader"
require "tmpdir"

RSpec.describe PdfBuilder::Renderer do
  let(:character) { joe_rogan_character }

  around do |ex|
    Dir.mktmpdir("pdf_builder_spec") do |dir|
      @output = File.join(dir, "joe_rogan.pdf")
      ex.run
    end
  end

  it "writes a PDF file to the requested path" do
    described_class.render(character, @output)
    expect(File.exist?(@output)).to be true
    expect(File.size(@output)).to be > 0
  end

  it "produces a single-page document" do
    described_class.render(character, @output)
    reader = PDF::Reader.new(@output)
    expect(reader.page_count).to eq(1)
  end

  context "with the rendered PDF text" do
    subject(:text) do
      described_class.render(character, @output)
      PDF::Reader.new(@output).pages.first.text
    end

    it "contains the title and field labels" do
      expect(text).to include("DUNGEONS & DRAGONS")
      expect(text).to include("Character Sheet")
      expect(text).to include("INITIATIVE")
      expect(text).to include("ABILITY SCORES")
      expect(text).to include("DEFENSES")
      expect(text).to include("HIT POINTS")
      expect(text).to include("MOVEMENT")
      expect(text).to include("SENSES")
      expect(text).to include("BASIC ATTACKS")
      expect(text).to include("RACE FEATURES")
    end

    it "contains the character details" do
      expect(text).to include("Joe Rogan")
      expect(text).to include("Frostbite")
      expect(text).to include("Halfling")
      expect(text).to include("Fighter")
      expect(text).to include("Small")
      expect(text).to include("Male")
      expect(text).to include("Good")
    end

    it "contains the ability score numbers" do
      # Strength = 18, Con = 13, Dex = 12, Int = 10, Wis = 14, Cha = 8
      %w[18 13 12 10 14 8].each do |score|
        expect(text).to include(score)
      end
    end

    it "contains the basic attack lines" do
      expect(text).to include("Short sword")
      expect(text).to include("1d6+4")
      expect(text).to include("1d4+4")
    end

    it "contains the race features" do
      expect(text).to include("Bold")
      expect(text).to include("Second Chance")
      expect(text).to include("Nimble Reaction")
    end
  end
end
