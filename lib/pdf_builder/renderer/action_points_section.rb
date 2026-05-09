# frozen_string_literal: true

require_relative "section"

module PdfBuilder
  class Renderer
    class ActionPointsSection < Section
      BAND_HEIGHT = 14
      BOX_WIDTH   = 60
      BOX_HEIGHT  = 22
      INFO_GAP    = 8

      def draw(rect)
        @cells.band(rect, "ACTION POINTS")
        cy = rect.y - BAND_HEIGHT
        draw_main_box(rect, cy)
        draw_milestones(rect, cy)
        @cells.tiny_label(Rect.new(rect.x, cy - 36, rect.width, 8),
                          "ADDITIONAL EFFECTS FOR SPENDING ACTION POINTS", align: :left)
        BAND_HEIGHT + 36 + 8
      end

      private

      def draw_main_box(rect, cy)
        @cells.framed_value(Rect.new(rect.x, cy, BOX_WIDTH, BOX_HEIGHT), "",
                            size: Canvas::BIG_VALUE_SIZE)
        @canvas.with_color(Canvas::BORDER) do
          @canvas.styled_text("Action Points", rect.x + 2, cy - 6,
                              size: 8, style: :bold)
        end
      end

      def draw_milestones(rect, cy)
        info_x = rect.x + BOX_WIDTH + INFO_GAP
        info_w = rect.width - BOX_WIDTH - INFO_GAP
        half = info_w / 2.0
        @cells.tiny_label(Rect.new(info_x, cy, half, 8), "MILESTONES", align: :left)
        @cells.tiny_label(Rect.new(info_x + half, cy, half, 8), "ACTION POINTS", align: :left)
        @canvas.with_color(Canvas::BORDER) do
          @canvas.styled_text("0\n1\n2", info_x, cy - 10,
                              size: 7, leading: 1, width: half)
          @canvas.styled_text("1\n2\n3", info_x + half, cy - 10,
                              size: 7, leading: 1, width: half)
        end
      end
    end
  end
end
