# frozen_string_literal: true

require_relative "section"

module PdfBuilder
  class Renderer
    class InitiativeSection < Section
      SCORE_WIDTH    = 60
      LABEL_GAP      = 6
      BREAKDOWN_KEYS = ["DEX", "1/2 LVL", "MISC"].freeze
      BAND_HEIGHT    = 14
      LABEL_HEIGHT   = 8
      VALUE_HEIGHT   = 16

      def draw(rect)
        @cells.band(rect, "INITIATIVE")
        breakdown_x = rect.x + SCORE_WIDTH + LABEL_GAP
        breakdown_w = rect.width - SCORE_WIDTH - LABEL_GAP

        draw_labels(rect, breakdown_x, breakdown_w)
        draw_values(rect, breakdown_x, breakdown_w)
        draw_conditional_label(rect)
        BAND_HEIGHT + LABEL_HEIGHT + VALUE_HEIGHT + LABEL_GAP + 2
      end

      private

      def draw_labels(rect, breakdown_x, breakdown_w)
        labels_y = rect.y - BAND_HEIGHT
        @cells.tiny_label(Rect.new(rect.x, labels_y, SCORE_WIDTH, LABEL_HEIGHT),
                          "SCORE", align: :left)
        cell_w = breakdown_w / BREAKDOWN_KEYS.size.to_f
        BREAKDOWN_KEYS.each_with_index do |lbl, i|
          @cells.tiny_label(Rect.new(breakdown_x + (i * cell_w), labels_y, cell_w, LABEL_HEIGHT),
                            lbl)
        end
      end

      def draw_values(rect, breakdown_x, breakdown_w)
        values_y = rect.y - BAND_HEIGHT - LABEL_HEIGHT
        score_rect = Rect.new(rect.x, values_y, SCORE_WIDTH, VALUE_HEIGHT)
        @cells.framed_value(score_rect, @ch.stat_value("Initiative").to_s,
                            size: Canvas::BIG_VALUE_SIZE, label_inside: "Initiative")
        cell_w = breakdown_w / BREAKDOWN_KEYS.size.to_f
        breakdown_values.each_with_index do |v, i|
          cell = Rect.new(breakdown_x + (i * cell_w), values_y, cell_w, VALUE_HEIGHT)
          @cells.framed_value(cell, v.to_s)
        end
      end

      def breakdown_values
        [@ch.dexterity.modifier, @ch.half_level, 0]
      end

      def draw_conditional_label(rect)
        y = rect.y - BAND_HEIGHT - LABEL_HEIGHT - VALUE_HEIGHT - 1
        @cells.tiny_label(Rect.new(rect.x, y, rect.width, LABEL_HEIGHT),
                          "CONDITIONAL MODIFIERS", align: :left)
      end
    end
  end
end
