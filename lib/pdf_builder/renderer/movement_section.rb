# frozen_string_literal: true

require_relative "section"

module PdfBuilder
  class Renderer
    class MovementSection < Section
      SCORE_WIDTH  = 60
      LABEL_GAP    = 6
      HEADERS      = %w[BASE ARMOR ITEM MISC].freeze
      BAND_HEIGHT  = 14
      LABEL_H      = 8
      VALUE_H      = 18

      def draw(rect)
        @cells.band(rect, "MOVEMENT")
        breakdown_x = rect.x + SCORE_WIDTH + LABEL_GAP
        breakdown_w = rect.width - SCORE_WIDTH - LABEL_GAP

        draw_labels(rect, breakdown_x, breakdown_w)
        draw_values(rect, breakdown_x, breakdown_w)
        draw_special_movement_label(rect)
        BAND_HEIGHT + LABEL_H + VALUE_H + LABEL_H
      end

      def draw_special_movement_label(rect)
        label_rect = Rect.new(rect.x, rect.y - BAND_HEIGHT - LABEL_H - VALUE_H - 2,
                              rect.width, LABEL_H)
        @cells.tiny_label(label_rect, "SPECIAL MOVEMENT", align: :left)
      end

      private

      def draw_labels(rect, breakdown_x, breakdown_w)
        labels_y = rect.y - BAND_HEIGHT
        @cells.tiny_label(Rect.new(rect.x, labels_y, SCORE_WIDTH, LABEL_H),
                          "SCORE", align: :left)
        cell_w = breakdown_w / HEADERS.size.to_f
        HEADERS.each_with_index do |hd, i|
          @cells.tiny_label(Rect.new(breakdown_x + (i * cell_w), labels_y, cell_w, LABEL_H), hd)
        end
      end

      def draw_values(rect, breakdown_x, breakdown_w)
        values_y = rect.y - BAND_HEIGHT - LABEL_H
        draw_score_box(rect, values_y)
        draw_breakdown_values(breakdown_x, breakdown_w, values_y)
      end

      def draw_score_box(rect, values_y)
        score_rect = Rect.new(rect.x, values_y, SCORE_WIDTH, VALUE_H)
        @cells.framed_value(score_rect, @ch.stat_value("Speed").to_s,
                            size: Canvas::BIG_VALUE_SIZE, label_inside: "Speed (Squares)")
      end

      def draw_breakdown_values(breakdown_x, breakdown_w, values_y)
        cell_w = breakdown_w / HEADERS.size.to_f
        speed_breakdown.each_with_index do |v, i|
          cell = Rect.new(breakdown_x + (i * cell_w), values_y, cell_w, VALUE_H)
          @cells.framed_value(cell, v.zero? ? "" : v.to_s)
        end
      end

      def speed_breakdown
        speed = @ch.stat("Speed")
        base  = base_speed_value
        armor = speed ? speed.total_of_type("Armor") : 0
        item  = speed ? speed.total_of_type("Item") : 0
        misc  = speed ? (speed.value - base - armor - item) : 0
        [base, armor, item, misc]
      end

      def base_speed_value
        speed = @ch.stat("Speed")
        return 0 unless speed

        base = speed.adds.find { |a| a[:type].nil? && a[:level] == 1 && a[:statlink].nil? }
        base ? base[:value].to_i : 0
      end
    end
  end
end
