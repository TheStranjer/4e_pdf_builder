# frozen_string_literal: true

require_relative "section"

module PdfBuilder
  class Renderer
    class SensesSection < Section
      BAND_HEIGHT = 14
      LABEL_H     = 8
      ROW_H       = 16
      SCORE_W     = 36
      BASE_W      = 30
      SKILL_W     = 30
      SENSE_GAP   = 64

      SENSES = [["Passive Insight", "Insight"], ["Passive Perception", "Perception"]].freeze
      HEADERS = ["SCORE", "PASSIVE SENSE", "BASE", "SKILL BONUS"].freeze

      def draw(rect)
        @cells.band(rect, "SENSES")
        sense_w = rect.width - SCORE_W - SENSE_GAP
        draw_headers(rect, sense_w)
        cy = draw_rows(rect, sense_w)
        @cells.tiny_label(Rect.new(rect.x, cy - 2, rect.width, LABEL_H),
                          "SPECIAL SENSES", align: :left)
        BAND_HEIGHT + LABEL_H + (ROW_H * SENSES.size) + LABEL_H
      end

      private

      def draw_headers(rect, sense_w)
        @cells.tiny_label_row(
          Rect.new(rect.x, rect.y - BAND_HEIGHT, rect.width, LABEL_H),
          [SCORE_W, sense_w, BASE_W, SKILL_W],
          HEADERS
        )
      end

      def draw_rows(rect, sense_w)
        cy = rect.y - BAND_HEIGHT - LABEL_H
        SENSES.each do |label, src|
          draw_row(Rect.new(rect.x, cy, rect.width, ROW_H), sense_w, label, src)
          cy -= ROW_H
        end
        cy
      end

      def draw_row(row_rect, sense_w, label, src)
        @cells.framed_value(row_rect.with(width: SCORE_W), @ch.stat_value(label).to_s)
        draw_row_label(row_rect, label)
        draw_passive_columns(row_rect, sense_w, src)
      end

      def draw_passive_columns(row_rect, sense_w, src)
        base_rect = Rect.new(row_rect.x + SCORE_W + sense_w, row_rect.y, BASE_W, ROW_H)
        skill_x = row_rect.x + SCORE_W + sense_w + BASE_W + 4
        @cells.framed_value(base_rect, "10")
        @cells.framed_value(Rect.new(skill_x, row_rect.y, SKILL_W, ROW_H),
                            @ch.stat_value(src).to_s)
      end

      def draw_row_label(row_rect, label)
        @canvas.with_color(Canvas::BORDER) do
          @canvas.styled_text(label, row_rect.x + SCORE_W + 2, row_rect.y - 4,
                              size: 8, style: :bold)
        end
      end
    end
  end
end
