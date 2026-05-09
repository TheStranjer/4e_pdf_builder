# frozen_string_literal: true

require_relative "section"
require_relative "../character"

module PdfBuilder
  class Renderer
    class AbilityScoresSection < Section
      RATIOS       = [0.20, 0.34, 0.20, 0.26].freeze
      HEADERS      = ["SCORE", "ABILITY", "ABIL MOD", "MOD + 1/2 LVL"].freeze
      BAND_HEIGHT  = 14
      LABEL_HEIGHT = 8
      ROW_HEIGHT   = 18

      def draw(rect)
        @cells.band(rect, "ABILITY SCORES")
        widths = proportional_widths(rect.width, RATIOS)
        @cells.tiny_label_row(
          Rect.new(rect.x, rect.y - BAND_HEIGHT, rect.width, LABEL_HEIGHT),
          widths, HEADERS
        )

        cy = rect.y - BAND_HEIGHT - LABEL_HEIGHT
        Character::ABILITIES.each do |a|
          draw_row(rect, a, cy, widths)
          cy -= ROW_HEIGHT
        end
        BAND_HEIGHT + LABEL_HEIGHT + (ROW_HEIGHT * Character::ABILITIES.size)
      end

      private

      def draw_row(rect, ability, cy, widths)
        ability_obj = @ch.public_send(ability)
        row = Rect.new(rect.x, cy, rect.width, ROW_HEIGHT)
        modlvl = ability_obj.modifier + @ch.half_level
        cells = [ability_obj.score.to_s, nil, ability_obj.modifier.to_s, modlvl.to_s]
        cells.each_with_index do |value, idx|
          draw_cell(row.column(idx, widths), idx, value, ability)
        end
      end

      def draw_cell(cell_rect, idx, value, ability)
        if idx == 1
          @cells.ability_label_box(cell_rect, ability)
        else
          @cells.framed_value(cell_rect, value)
        end
      end
    end
  end
end
