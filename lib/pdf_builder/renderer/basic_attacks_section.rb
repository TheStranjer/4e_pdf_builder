# frozen_string_literal: true

require_relative "section"

module PdfBuilder
  class Renderer
    class BasicAttacksSection < Section
      BAND_HEIGHT = 14
      LABEL_H     = 8
      ROW_H       = 16
      RATIOS      = [0.15, 0.15, 0.45, 0.25].freeze
      HEADERS     = ["ATTACK", "DEFENSE", "WEAPON OR POWER", "DAMAGE"].freeze

      def draw(rect)
        @cells.band(rect, "BASIC ATTACKS")
        widths = proportional_widths(rect.width, RATIOS)
        @cells.tiny_label_row(
          Rect.new(rect.x, rect.y - BAND_HEIGHT, rect.width, LABEL_H),
          widths, HEADERS
        )

        cy = rect.y - BAND_HEIGHT - LABEL_H
        all_rows = rows
        all_rows.each do |row|
          draw_row(rect, cy, widths, row)
          cy -= ROW_H
        end
        BAND_HEIGHT + LABEL_H + (ROW_H * all_rows.size)
      end

      private

      def draw_row(rect, cy, widths, row)
        row_rect = Rect.new(rect.x, cy, rect.width, ROW_H)
        row.each_with_index do |val, i|
          align = i == 2 ? :left : :center
          @cells.framed_value(row_rect.column(i, widths), val.to_s, align:)
        end
      end

      def rows
        result = []
        result.concat(weapon_rows("Melee Basic Attack"))
        result.concat(weapon_rows("Ranged Basic Attack", relabel_unarmed: true))
        result << ["", "", "", ""] while result.size < 4
        result.first(4)
      end

      def weapon_rows(power_name, relabel_unarmed: false)
        power = @ch.powers.find { |p| p.name == power_name }
        return [] unless power

        power.weapons.map { |w| weapon_row(w, relabel_unarmed:) }
      end

      def weapon_row(weapon, relabel_unarmed:)
        label = weapon.name.to_s
        label = "Unarmed (Range)" if relabel_unarmed && weapon.name == "Unarmed"
        [weapon.attack_bonus.to_s, weapon.defense.to_s, label, weapon.damage.to_s]
      end
    end
  end
end
