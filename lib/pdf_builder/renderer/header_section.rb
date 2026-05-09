# frozen_string_literal: true

require_relative "section"

module PdfBuilder
  class Renderer
    class HeaderSection < Section
      BAND_HEIGHT = 32
      ROW_GAP     = 6
      ROW_HEIGHT  = 22
      ROW_OFFSET  = 24

      ROW1_LABELS = ["Character Name", "Level", "Class", "Paragon Path",
                     "Epic Destiny", "Total XP",].freeze
      ROW1_RATIOS = [0.30, 0.07, 0.18, 0.18, 0.16, 0.11].freeze

      ROW2_LABELS = ["Race", "Size", "Age", "Gender", "Height", "Weight",
                     "Alignment", "Deity", "Adventuring Company", "RPGA Number",].freeze
      ROW2_RATIOS = [0.10, 0.07, 0.05, 0.07, 0.08, 0.08,
                     0.10, 0.10, 0.20, 0.15,].freeze

      def draw(rect)
        draw_band(rect)
        rect_below_band = rect.shifted(dy: -BAND_HEIGHT - ROW_GAP).with(height: ROW_HEIGHT)
        draw_field_row(rect_below_band, ROW1_LABELS, row1_values, ROW1_RATIOS)
        draw_field_row(rect_below_band.shifted(dy: -ROW_OFFSET), ROW2_LABELS,
                       row2_values, ROW2_RATIOS)
      end

      private

      def draw_band(rect)
        band_rect = rect.with(height: BAND_HEIGHT)
        @canvas.filled_rect(band_rect, Canvas::BAND_BG)
        @canvas.with_color(Canvas::BAND_FG) do
          draw_band_titles(rect)
        end
      end

      def draw_band_titles(rect)
        right_x = rect.x + rect.width - 150
        @canvas.styled_text("DUNGEONS & DRAGONS", rect.x + 8, rect.y - 6,
                            size: 22, style: :bold)
        @canvas.styled_text("Character Sheet", right_x, rect.y - 6,
                            size: 14, style: :bold, width: 145, align: :right)
        @canvas.styled_text("Player: #{@ch.player}", right_x, rect.y - BAND_HEIGHT + 8,
                            size: 9, style: :bold, width: 145, align: :right)
      end

      def row1_values
        [@ch.name, @ch.level, @ch.class_name, @ch.paragon_path,
         @ch.epic_destiny, @ch.total_xp,]
      end

      def row2_values
        [@ch.race, @ch.size, @ch.age, @ch.gender, @ch.height, @ch.weight,
         @ch.alignment, @ch.deity, @ch.company, @ch.rpga_number,]
      end

      def draw_field_row(rect, labels, values, ratios)
        widths = proportional_widths(rect.width, ratios)
        labels.zip(values).each_with_index do |(label, value), idx|
          cell_rect = rect.column(idx, widths)
          @cells.underlined_field(cell_rect, label, value.to_s)
        end
      end
    end
  end
end
