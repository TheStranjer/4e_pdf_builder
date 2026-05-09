# frozen_string_literal: true

require_relative "section"

module PdfBuilder
  class Renderer
    class AttackWorkspaceSection < Section
      BAND_HEIGHT = 14
      LABEL_H     = 8
      ROW_H       = 16
      SCORE_W     = 40
      BREAKDOWN   = ["1/2 LVL", "ABIL", "CLASS", "PROF", "FEAT", "ENH", "MISC"].freeze

      def draw(rect)
        @cells.band(rect, "ATTACK WORKSPACE")
        cy = rect.y - BAND_HEIGHT
        consumed = BAND_HEIGHT
        weapons.each do |wpn|
          consumed += draw_weapon_row(rect, cy - consumed + BAND_HEIGHT, wpn)
        end
        consumed
      end

      private

      def weapons
        basic = @ch.powers.find { |p| p.name == "Melee Basic Attack" }
        basic ? basic.weapons.first(2) : []
      end

      def draw_weapon_row(rect, cy, wpn)
        draw_caption(rect, cy, wpn)
        cy -= LABEL_H
        bw = (rect.width - SCORE_W) / BREAKDOWN.size.to_f
        draw_breakdown_labels(rect, cy, bw)
        cy -= LABEL_H
        draw_breakdown_values(rect, cy, bw, wpn)
        LABEL_H + LABEL_H + ROW_H + 4
      end

      def draw_caption(rect, cy, wpn)
        @canvas.with_color(Canvas::BORDER) do
          @canvas.styled_text("ABILITY: Melee Basic Attack — #{wpn.name}",
                              rect.x + 2, cy, size: 7, style: :italic, width: rect.width - 4)
        end
      end

      def draw_breakdown_labels(rect, cy, bw)
        @cells.tiny_label(Rect.new(rect.x, cy, SCORE_W, LABEL_H), "ATT BONUS", align: :left)
        BREAKDOWN.each_with_index do |hd, i|
          @cells.tiny_label(Rect.new(rect.x + SCORE_W + (i * bw), cy, bw, LABEL_H), hd)
        end
      end

      def draw_breakdown_values(rect, cy, bw, wpn)
        @cells.framed_value(Rect.new(rect.x, cy, SCORE_W, ROW_H), "+#{wpn.attack_bonus}")
        breakdown_attack(wpn).each_with_index do |v, i|
          @cells.framed_value(Rect.new(rect.x + SCORE_W + (i * bw), cy, bw, ROW_H), v.to_s)
        end
      end

      def breakdown_attack(weapon)
        return [""] * BREAKDOWN.size unless weapon

        components = attack_components(weapon)
        half_level, abil, class_bon, prof, feat, misc = components.values_at(
          :half_level, :abil, :class_bon, :prof, :feat, :misc
        )
        [half_level, abil, class_bon, prof, feat, 0, misc].map { |n| n.zero? ? "" : n.to_s }
      end

      def attack_components(weapon)
        half_level = @ch.half_level
        abil = ability_modifier_for(weapon.attack_stat)
        prof = weapon.name.to_s == "Unarmed" ? 0 : 3
        remainder = weapon.attack_bonus - half_level - abil
        meets_prof = remainder >= prof ? 1 : 0
        misc = remainder - prof - (2 * meets_prof)
        { half_level:, abil:, prof:, feat: meets_prof, class_bon: meets_prof, misc: }
      end

      def ability_modifier_for(stat_name)
        ability = stat_name.to_s.downcase.to_sym
        return 0 unless Character::ABILITIES.include?(ability)

        @ch.public_send(ability).modifier
      end
    end
  end
end
