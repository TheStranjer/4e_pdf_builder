RSpec.describe PdfBuilder::Character do
  describe "#stat" do
    let(:ch) { described_class.new }

    it "returns nil for unknown stats" do
      expect(ch.stat("Mystery")).to be_nil
    end

    it "indexes the stat under all of its aliases" do
      ch.store_stat(20, ["AC", "Armor Class"], [])
      expect(ch.stat("AC").value).to            eq(20)
      expect(ch.stat("Armor Class").value).to   eq(20)
      expect(ch.stat("ARMOR CLASS").value).to   eq(20)
    end
  end

  describe "Ability#modifier" do
    it "follows the standard 4e ability mod formula" do
      ability = described_class::Ability.new(:strength, 18)
      expect(ability.modifier).to eq(4)
    end

    it "uses floor for odd negative values" do
      ability = described_class::Ability.new(:charisma, 7)
      expect(ability.modifier).to eq(-2)
    end
  end

  describe "StatEntry#total_of_type" do
    it "sums adds whose type matches one of the requested types" do
      entry = described_class::StatEntry.new(
        value: 0,
        adds: [
          { type: "Class",   value: 1 },
          { type: "Class",   value: 2 },
          { type: "Feat",    value: 1 },
          { type: "Ability", value: 4 },
        ],
      )
      expect(entry.total_of_type("Class")).to eq(3)
      expect(entry.total_of_type("Feat", "Ability")).to eq(5)
      expect(entry.total_of_type("Enhancement")).to eq(0)
    end
  end

  describe "computed convenience accessors" do
    let(:ch) { joe_rogan_character }

    it "exposes ability mods via dot syntax" do
      expect(ch.strength.modifier).to eq(4)
      expect(ch.dexterity.modifier).to eq(1)
    end

    it "knows half-level" do
      expect(ch.half_level).to eq(1)
    end
  end
end
