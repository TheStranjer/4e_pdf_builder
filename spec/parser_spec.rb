# frozen_string_literal: true

RSpec.describe PdfBuilder::Parser do
  describe ".parse_file" do
    subject(:character) { described_class.parse_file(joe_rogan_path) }

    it "raises ParseError on malformed XML" do
      expect { described_class.parse("<not-xml") }.to raise_error(PdfBuilder::Parser::ParseError)
    end

    it "extracts top-level character details" do
      expect(character.name).to        eq("Joe Rogan")
      expect(character.player).to      eq("Frostbite")
      expect(character.level).to       eq(2)
      expect(character.height).to      eq("3'10\"")
      expect(character.weight).to      eq("85 lbs")
      expect(character.total_xp).to    eq(1000)
      expect(character.carried_money).to eq("20 gp")
    end

    it "identifies the race and class via RulesElementTally" do
      expect(character.race).to       eq("Halfling")
      expect(character.class_name).to eq("Fighter")
      expect(character.size).to       eq("Small")
      expect(character.alignment).to  eq("Good")
      expect(character.gender).to     eq("Male")
    end

    it "captures base ability scores from <AbilityScores>" do
      expect(character.base_abilities).to include(
        strength: 18,
        constitution: 11,
        dexterity: 10,
        intelligence: 10,
        wisdom: 14,
        charisma: 8
      )
    end

    it "computes adjusted ability scores from the StatBlock" do
      expect(character.strength.score).to     eq(18)
      expect(character.constitution.score).to eq(13) # +2 racial
      expect(character.dexterity.score).to    eq(12) # +2 racial
      expect(character.charisma.score).to     eq(8)
    end

    it "indexes stats by alias" do
      expect(character.stat("AC").value).to                 eq(20)
      expect(character.stat("Armor Class").value).to        eq(20)
      expect(character.stat("Fortitude Defense").value).to  eq(17)
      expect(character.stat("Reflex").value).to             eq(14)
      expect(character.stat("Will").value).to               eq(13)
      expect(character.stat("Hit Points").value).to         eq(39)
      expect(character.stat("Healing Surges").value).to     eq(10)
      expect(character.stat("Initiative").value).to         eq(2)
      expect(character.stat("Speed").value).to              eq(5)
      expect(character.stat("Passive Insight").value).to    eq(13)
      expect(character.stat("Passive Perception").value).to eq(13)
    end

    it "captures racial traits with their short descriptions" do
      names = character.race_features.map(&:name)
      expect(names).to include("Bold", "Second Chance", "Nimble Reaction")

      bold = character.race_features.find { |f| f.name == "Bold" }
      expect(bold.description).to match(/saving throws against fear/i)
    end

    it "captures feats and class features" do
      expect(character.feats.map(&:name)).to include("Weapon Expertise (Light Blade)", "Toughness")
      expect(character.class_features.map(&:name))
        .to include("Combat Challenge", "Combat Superiority", "One-handed Weapon Talent")
    end

    it "captures proficiencies" do
      expect(character.proficiencies).to include(
        "Armor Proficiency (Scale)",
        "Shield Proficiency (Heavy)",
        "Weapon Proficiency (Short sword)"
      )
    end

    it "captures languages" do
      expect(character.languages).to include("Common", "Dwarven")
    end

    it "captures the equipped loot" do
      names = character.loot.map(&:name)
      expect(names).to include("Scale Armor", "Short sword", "Heavy Shield", "Adventurer's Kit")

      shield = character.loot.find { |l| l.name == "Heavy Shield" }
      expect(shield.equipped).to be true
    end

    it "captures powers and their per-weapon attack stats" do
      melee = character.powers.find { |p| p.name == "Melee Basic Attack" }
      expect(melee).not_to be_nil
      expect(melee.usage).to eq("At-Will")

      short_sword = melee.weapons.find { |w| w.name == "Short sword" }
      expect(short_sword.attack_bonus).to eq(10)
      expect(short_sword.damage).to       eq("1d6+4")
      expect(short_sword.defense).to      eq("AC")

      unarmed = melee.weapons.find { |w| w.name == "Unarmed" }
      expect(unarmed.attack_bonus).to eq(6)
      expect(unarmed.damage).to       eq("1d4+4")
    end
  end
end
