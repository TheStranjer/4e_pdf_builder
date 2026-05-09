# frozen_string_literal: true

require_relative "section"

module PdfBuilder
  class Renderer
    class HitPointsSection < Section
      BAND_HEIGHT = 14
      LABEL_H     = 8
      VALUE_H     = 18
      SLOT_H      = 12
      INPUT_H     = 14

      def draw(rect)
        @cells.band(rect, "HIT POINTS")
        cy = rect.y - BAND_HEIGHT
        cy = draw_summary(rect, cy)
        cy = draw_current(rect, cy)
        cy = draw_second_wind(rect, cy)
        draw_death_section(rect, cy)
      end

      private

      def draw_summary(rect, cy)
        cell_w = rect.width / 4.0
        labels = ["MAX HP", "BLOODIED", "SURGE VALUE", "SURGES/DAY"]
        @cells.tiny_label_row(Rect.new(rect.x, cy, rect.width, LABEL_H),
                              [cell_w] * 4, labels)
        cy -= LABEL_H
        draw_summary_values(rect, cy, cell_w)
        cy - VALUE_H - 4
      end

      def draw_summary_values(rect, cy, cell_w)
        max_hp = @ch.stat_value("Hit Points")
        values = [max_hp, max_hp / 2, (max_hp / 4.0).floor, @ch.stat_value("Healing Surges")]
        values.each_with_index do |v, i|
          @cells.framed_value(Rect.new(rect.x + (i * cell_w), cy, cell_w, VALUE_H), v.to_s)
        end
      end

      def draw_current(rect, cy)
        half = rect.width / 2.0
        @cells.tiny_label_row(Rect.new(rect.x, cy, rect.width, LABEL_H),
                              [half, half], ["CURRENT HIT POINTS", "CURRENT SURGE USES"])
        cy -= LABEL_H
        @cells.framed_value(Rect.new(rect.x, cy, half, INPUT_H), "")
        @cells.framed_value(Rect.new(rect.x + half, cy, half, INPUT_H), "")
        cy - INPUT_H - 6
      end

      def draw_second_wind(rect, cy)
        @cells.band(Rect.new(rect.x, cy, rect.width, BAND_HEIGHT),
                    "SECOND WIND  1/ENCOUNTER", title_size: 7)
        cy -= BAND_HEIGHT
        @cells.tiny_label(Rect.new(rect.x, cy, rect.width, LABEL_H),
                          "TEMPORARY HIT POINTS", align: :left)
        cy -= LABEL_H
        @cells.framed_value(Rect.new(rect.x, cy, rect.width, SLOT_H), "")
        cy - SLOT_H - 6
      end

      def draw_death_section(rect, cy)
        @cells.band(Rect.new(rect.x, cy, rect.width, BAND_HEIGHT),
                    "DEATH SAVING THROW FAILURES", title_size: 7)
        cy -= BAND_HEIGHT
        cy = draw_labelled_slot(slot_rect(rect, cy), "SAVING THROW MODS",
                                saving_throw_text, size: 7, align: :left)
        cy = draw_labelled_slot(slot_rect(rect, cy), "RESISTANCES", "")
        draw_labelled_slot(slot_rect(rect, cy), "CURRENT CONDITIONS AND EFFECTS", "")
      end

      def slot_rect(rect, cy)
        Rect.new(rect.x, cy, rect.width, LABEL_H + SLOT_H)
      end

      def draw_labelled_slot(rect, label, value, **)
        @cells.tiny_label(rect.with(height: LABEL_H), label, align: :left)
        value_rect = Rect.new(rect.x, rect.y - LABEL_H, rect.width, SLOT_H)
        @cells.framed_value(value_rect, value, **)
        rect.y - LABEL_H - SLOT_H - 4
      end

      def saving_throw_text
        text = @ch.saving_throw_mods.join(", ")
        return "+5 Racial bonus against fear" if text.empty? && halfling?

        text
      end

      def halfling?
        @ch.race.to_s.downcase.include?("halfling")
      end
    end
  end
end
