require "nokogiri"
require_relative "character"

module PdfBuilder
  # Parses a D&D Insider Character Builder save file (.dnd4e XML)
  # into a Character value object.
  class Parser
    class ParseError < StandardError; end

    def self.parse_file(path)
      new(File.read(path, mode: "rb")).parse
    end

    def self.parse(xml)
      new(xml).parse
    end

    def initialize(xml)
      @doc = Nokogiri::XML(xml) { |c| c.strict.noblanks }
    rescue Nokogiri::XML::SyntaxError => e
      raise ParseError, "Invalid XML: #{e.message}"
    end

    def parse
      sheet = @doc.at_xpath("//CharacterSheet")
      raise ParseError, "Missing <CharacterSheet> in XML" unless sheet

      ch = Character.new
      parse_details(sheet, ch)
      parse_abilities(sheet, ch)
      parse_stats(sheet, ch)
      parse_rules_elements(sheet, ch)
      parse_loot(sheet, ch)
      parse_powers(sheet, ch)
      ch
    end

    private

    def parse_details(sheet, ch)
      details = sheet.at_xpath("./Details") or return

      ch.name         = text_at(details, "name")
      ch.level        = text_at(details, "Level").to_i
      ch.player       = text_at(details, "Player")
      ch.height       = text_at(details, "Height")
      ch.weight       = text_at(details, "Weight")
      ch.gender       = text_at(details, "Gender")
      ch.age          = text_at(details, "Age")
      ch.alignment    = text_at(details, "Alignment")
      ch.company      = text_at(details, "Company")
      ch.deity        = nil # Not present in the sample; reserved for future use.
      ch.paragon_path = nil
      ch.epic_destiny = nil
      ch.rpga_number  = nil
      ch.total_xp     = text_at(details, "Experience").to_i
      ch.carried_money = text_at(details, "CarriedMoney")
      ch.portrait_path = text_at(details, "Portrait")
    end

    def parse_abilities(sheet, ch)
      block = sheet.at_xpath("./AbilityScores") or return

      Character::ABILITIES.each do |a|
        node = block.at_xpath("./#{a.to_s.capitalize}")
        next unless node

        score = node["score"].to_i
        ch.base_abilities[a] = score
      end
    end

    def parse_stats(sheet, ch)
      sheet.xpath("./StatBlock/Stat").each do |stat_node|
        value   = stat_node["value"].to_i
        aliases = stat_node.xpath("./alias").map { |n| n["name"] }.compact
        next if aliases.empty?

        adds = stat_node.xpath("./statadd").map do |add|
          {
            type:        add["type"],
            level:       add["Level"]&.to_i,
            value:       add["value"].to_i,
            statlink:    add["statlink"],
            requires:    add["requires"],
            conditional: add["conditional"],
            wearing:     add["wearing"],
            not_wearing: add["not-wearing"],
            abilmod:     add["abilmod"] == "true",
            string:      add["String"],
          }
        end

        ch.store_stat(value, aliases, adds)
      end

      # Materialize ability scores from the StatBlock so they reflect racial bonuses.
      Character::ABILITIES.each do |a|
        s = ch.stat(a.to_s.capitalize) || ch.stat(a.to_s)
        score = s ? s.value : (ch.base_abilities[a] || 10)
        ch.ability_scores[a] = Character::Ability.new(a, score)
      end
    end

    def parse_rules_elements(sheet, ch)
      tally = sheet.at_xpath("./RulesElementTally") or return

      tally.xpath("./RulesElement").each do |re|
        type = re["type"]
        name = re["name"]&.strip
        next if name.nil? || name.empty?

        desc = re.at_xpath("./specific[@name='Short Description']")&.text&.strip

        case type
        when "Race"
          ch.race = name
        when "Class"
          ch.class_name = name
        when "Size"
          ch.size = name unless ch.size && !ch.size.empty?
        when "Gender"
          ch.gender = name if ch.gender.nil? || ch.gender.empty?
        when "Alignment"
          ch.alignment = name if ch.alignment.nil? || ch.alignment.empty?
        when "Racial Trait"
          ch.race_features << Character::RaceFeature.new(name: name, description: desc)
        when "Class Feature"
          ch.class_features << Character::RaceFeature.new(name: name, description: desc)
        when "Feat"
          ch.feats << Character::RaceFeature.new(name: name, description: desc)
        when "Language"
          ch.languages << name
        when "Proficiency"
          ch.proficiencies << name
        end
      end
    end

    def parse_loot(sheet, ch)
      sheet.xpath("./LootTally/loot").each do |loot|
        re = loot.at_xpath("./RulesElement")
        next unless re

        ch.loot << Character::LootItem.new(
          name:     re["name"]&.strip,
          type:     re["type"],
          count:    loot["count"].to_i,
          equipped: loot["equip-count"].to_i.positive?,
        )
      end
    end

    def parse_powers(sheet, ch)
      sheet.xpath("./PowerStats/Power").each do |power_node|
        weapons = power_node.xpath("./Weapon").map do |w|
          Character::Weapon.new(
            name:         w["name"],
            attack_bonus: text_at(w, "AttackBonus").to_i,
            damage:       text_at(w, "Damage"),
            defense:      text_at(w, "Defense"),
            attack_stat:  text_at(w, "AttackStat"),
          )
        end

        ch.powers << Character::Power.new(
          name:        power_node["name"],
          usage:       text_at(power_node, "specific[@name='Power Usage']"),
          action_type: text_at(power_node, "specific[@name='Action Type']"),
          weapons:     weapons,
        )
      end
    end

    def text_at(node, xpath)
      n = node.at_xpath("./#{xpath}")
      return "" unless n

      n.text.to_s.gsub(/\s+/, " ").strip
    end
  end
end
