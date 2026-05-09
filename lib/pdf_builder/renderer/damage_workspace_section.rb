# frozen_string_literal: true

require_relative "section"

module PdfBuilder
  class Renderer
    class DamageWorkspaceSection < Section
      BAND_HEIGHT = 14
      LABEL_H     = 8
      ROW_H       = 16
      DAMAGE_W    = 70
      BREAKDOWN   = %w[ABIL FEAT ENH MISC MISC].freeze

      def draw(rect)
        @cells.band(rect, "DAMAGE WORKSPACE")
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
        bw = (rect.width - DAMAGE_W) / BREAKDOWN.size.to_f
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
        @cells.tiny_label(Rect.new(rect.x, cy, DAMAGE_W, LABEL_H), "DAMAGE", align: :left)
        BREAKDOWN.each_with_index do |hd, i|
          @cells.tiny_label(Rect.new(rect.x + DAMAGE_W + (i * bw), cy, bw, LABEL_H), hd)
        end
      end

      def draw_breakdown_values(rect, cy, bw, wpn)
        @cells.framed_value(Rect.new(rect.x, cy, DAMAGE_W, ROW_H), wpn.damage.to_s)
        values = [parse_damage_mod(wpn.damage), 0, 0, 0, 0]
        values.each_with_index do |v, i|
          cell = Rect.new(rect.x + DAMAGE_W + (i * bw), cy, bw, ROW_H)
          @cells.framed_value(cell, v.zero? ? "" : v.to_s)
        end
      end

      def parse_damage_mod(damage_str)
        return 0 if damage_str.to_s.empty?

        m = damage_str.to_s.match(/([+-])\s*(\d+)\s*$/)
        return 0 unless m

        (m[1] == "-" ? -1 : 1) * m[2].to_i
      end
    end
  end
end
