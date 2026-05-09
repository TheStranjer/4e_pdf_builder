# frozen_string_literal: true

require "ostruct"

module PdfBuilder
  # In-memory representation of a parsed D&D 4e character.
  #
  # Most fields map 1:1 to entries in the .dnd4e XML; the StatBlock is
  # flattened so any of a Stat's `<alias name="...">` values can be used
  # to look it up via #stat.
  class Character
    ABILITIES = %i[strength constitution dexterity intelligence wisdom charisma].freeze

    Ability = Struct.new(:name, :score) do
      def modifier
        (score - 10).fdiv(2).floor
      end
    end

    StatEntry = Struct.new(:value, :adds, keyword_init: true) do
      def initialize(value:, adds: [])
        super
      end

      # Sum of statadds whose `type` attribute matches one of the requested types.
      # `type` arguments are matched case-insensitively.
      def total_of_type(*types)
        wanted = types.map { |t| t.to_s.downcase }
        adds
          .select { |a| a[:type] && wanted.include?(a[:type].to_s.downcase) }
          .sum { |a| a[:value].to_i }
      end
    end

    Power = Struct.new(:name, :usage, :action_type, :weapons, keyword_init: true)
    Weapon = Struct.new(:name, :attack_bonus, :damage, :defense, :attack_stat, keyword_init: true)
    LootItem = Struct.new(:name, :type, :quantity, :equipped, keyword_init: true)
    RaceFeature = Struct.new(:name, :description, keyword_init: true)

    attr_accessor :name, :player, :level, :class_name, :race, :size, :gender, :age,
                  :height, :weight, :alignment, :deity, :company, :paragon_path,
                  :epic_destiny, :rpga_number, :total_xp, :carried_money, :portrait_path,
                  :base_abilities, :ability_scores, :stats, :race_features, :class_features,
                  :feats, :powers, :loot, :languages, :proficiencies, :saving_throw_mods,
                  :resistances

    def initialize
      @base_abilities    = {}
      @ability_scores    = {}
      @stats             = {}
      @race_features     = []
      @class_features    = []
      @feats             = []
      @powers            = []
      @loot              = []
      @languages         = []
      @proficiencies     = []
      @saving_throw_mods = []
      @resistances       = []
    end

    # Lookup a Stat by any of its aliases (case-insensitive).
    def stat(name)
      key = normalize(name)
      @stats[key]
    end

    # Convenience numeric accessor — returns 0 for unknown stats so the
    # renderer never has to nil-check every cell.
    def stat_value(name, default: 0)
      s = stat(name)
      s ? s.value.to_i : default
    end

    def half_level
      (level.to_i / 2)
    end

    # Each ability surfaces as `Character#strength` etc, returning Ability.
    ABILITIES.each do |a|
      define_method(a) { @ability_scores[a] || Ability.new(a, 10) }
    end

    # Highest of two ability mods — used for AC (Dex/Int), Reflex (Dex/Int)
    # and Will (Wis/Cha).
    def best_mod(*ability_names)
      ability_names.map { |n| public_send(n).modifier }.max
    end

    # The score that's actually displayed in the "ABIL" column of a defense:
    # AC uses the higher of Dex/Int unless wearing heavy armor, in which case
    # the heavy-armor stat overrides — we simplify by reading the
    # `type="Ability"` add-ups directly from the parsed Stat.
    def defense_abil(defense_alias)
      s = stat(defense_alias)
      return 0 unless s

      s.total_of_type("Ability")
    end

    def store_stat(value, aliases, adds)
      entry = StatEntry.new(value:, adds:)
      aliases.each do |a|
        @stats[normalize(a)] = entry
      end
      entry
    end

    private

    def normalize(name)
      name.to_s.strip.downcase
    end
  end
end
