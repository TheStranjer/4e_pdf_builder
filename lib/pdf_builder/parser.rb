# frozen_string_literal: true

require "nokogiri"
require_relative "character"

module PdfBuilder
  # Parses a D&D Insider Character Builder save file (.dnd4e XML)
  # into a Character value object.
  class Parser
    class ParseError < StandardError; end

    DETAIL_FIELDS = {
      name: "name",
      player: "Player",
      height: "Height",
      weight: "Weight",
      gender: "Gender",
      age: "Age",
      alignment: "Alignment",
      company: "Company",
      carried_money: "CarriedMoney",
      portrait_path: "Portrait",
    }.freeze

    RULES_ELEMENT_HANDLERS = {
      "Race" => ->(ch, name, _desc) { ch.race = name },
      "Class" => ->(ch, name, _desc) { ch.class_name = name },
      "Size" => ->(ch, name, _desc) { ch.size = name unless ch.size && !ch.size.empty? },
      "Gender" => lambda do |ch, name, _desc|
        ch.gender = name if ch.gender.nil? || ch.gender.empty?
      end,
      "Alignment" => lambda do |ch, name, _desc|
        ch.alignment = name if ch.alignment.nil? || ch.alignment.empty?
      end,
      "Racial Trait" => lambda do |ch, name, desc|
        ch.race_features << Character::RaceFeature.new(name:, description: desc)
      end,
      "Class Feature" => lambda do |ch, name, desc|
        ch.class_features << Character::RaceFeature.new(name:, description: desc)
      end,
      "Feat" => lambda do |ch, name, desc|
        ch.feats << Character::RaceFeature.new(name:, description: desc)
      end,
      "Language" => ->(ch, name, _desc) { ch.languages << name },
      "Proficiency" => ->(ch, name, _desc) { ch.proficiencies << name },
    }.freeze

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

      DETAIL_FIELDS.each do |attr, xml_name|
        ch.public_send(:"#{attr}=", text_at(details, xml_name))
      end
      ch.level = text_at(details, "Level").to_i
      ch.total_xp = text_at(details, "Experience").to_i
    end

    def parse_abilities(sheet, ch)
      block = sheet.at_xpath("./AbilityScores") or return

      Character::ABILITIES.each do |ability|
        node = block.at_xpath("./#{ability.to_s.capitalize}")
        next unless node

        ch.base_abilities[ability] = node["score"].to_i
      end
    end

    def parse_stats(sheet, ch)
      sheet.xpath("./StatBlock/Stat").each do |stat_node|
        aliases = stat_node.xpath("./alias").filter_map { |n| n["name"] }
        next if aliases.empty?

        adds = stat_node.xpath("./statadd").map { |add| stat_add_hash(add) }
        ch.store_stat(stat_node["value"].to_i, aliases, adds)
      end

      materialize_ability_scores(ch)
    end

    def stat_add_hash(add)
      {
        type: add["type"],
        level: add["Level"]&.to_i,
        value: add["value"].to_i,
        statlink: add["statlink"],
        requires: add["requires"],
        conditional: add["conditional"],
        wearing: add["wearing"],
        not_wearing: add["not-wearing"],
        abilmod: add["abilmod"] == "true",
        string: add["String"],
      }
    end

    def materialize_ability_scores(ch)
      Character::ABILITIES.each do |ability|
        stat = ch.stat(ability.to_s.capitalize) || ch.stat(ability.to_s)
        score = stat ? stat.value : (ch.base_abilities[ability] || 10)
        ch.ability_scores[ability] = Character::Ability.new(ability, score)
      end
    end

    def parse_rules_elements(sheet, ch)
      tally = sheet.at_xpath("./RulesElementTally") or return

      tally.xpath("./RulesElement").each { |re| apply_rules_element(ch, re) }
    end

    def apply_rules_element(ch, node)
      name = node["name"]&.strip
      return if name.nil? || name.empty?

      handler = RULES_ELEMENT_HANDLERS[node["type"]]
      return unless handler

      desc = node.at_xpath("./specific[@name='Short Description']")&.text&.strip
      handler.call(ch, name, desc)
    end

    def parse_loot(sheet, ch)
      sheet.xpath("./LootTally/loot").each do |loot|
        re = loot.at_xpath("./RulesElement")
        next unless re

        ch.loot << Character::LootItem.new(
          name: re["name"]&.strip,
          type: re["type"],
          quantity: loot["count"].to_i,
          equipped: loot["equip-count"].to_i.positive?
        )
      end
    end

    def parse_powers(sheet, ch)
      sheet.xpath("./PowerStats/Power").each do |power_node|
        weapons = power_node.xpath("./Weapon").map { |w| weapon_from(w) }
        ch.powers << Character::Power.new(
          name: power_node["name"],
          usage: text_at(power_node, "specific[@name='Power Usage']"),
          action_type: text_at(power_node, "specific[@name='Action Type']"),
          weapons:
        )
      end
    end

    def weapon_from(node)
      Character::Weapon.new(
        name: node["name"],
        attack_bonus: text_at(node, "AttackBonus").to_i,
        damage: text_at(node, "Damage"),
        defense: text_at(node, "Defense"),
        attack_stat: text_at(node, "AttackStat")
      )
    end

    def text_at(node, xpath)
      n = node.at_xpath("./#{xpath}")
      return "" unless n

      n.text.to_s.gsub(/\s+/, " ").strip
    end
  end
end
