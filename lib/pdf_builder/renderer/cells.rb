# frozen_string_literal: true

require_relative "canvas"

module PdfBuilder
  class Renderer
    # Higher-level cell primitives composed from Canvas calls. These are
    # what the section drawers actually use to lay out the sheet.
    class Cells
      BAND_HEIGHT = 14

      def initialize(canvas)
        @canvas = canvas
      end

      def band(rect, title, title_size: Canvas::BAND_TITLE_SIZE)
        @canvas.filled_rect(rect.with(height: BAND_HEIGHT), Canvas::BAND_BG)
        @canvas.with_color(Canvas::BAND_FG) do
          @canvas.styled_text(title, rect.x, rect.y - 3,
                              size: title_size, style: :bold,
                              width: rect.width, align: :center)
        end
      end

      def tiny_label(rect, label, align: :center)
        @canvas.with_color(Canvas::SUBLABEL_FG) do
          @canvas.styled_text(label.to_s, rect.x, rect.y - 1,
                              size: Canvas::SUBLABEL_SIZE,
                              width: rect.width, align:, style: :bold)
        end
      end

      def tiny_label_row(rect, widths, labels)
        labels.each_with_index do |label, idx|
          tiny_label(rect.column(idx, widths), label)
        end
      end

      def framed_value(rect, value, **opts)
        @canvas.stroke_rect(rect)
        align = opts.fetch(:align, :center)
        @canvas.with_color(Canvas::BORDER) do
          render_framed_text(rect, value, align, opts[:size] || Canvas::VALUE_SIZE)
          render_inside_label(rect, opts[:label_inside], align) if opts[:label_inside]
        end
      end

      def underlined_field(rect, label, value)
        baseline = rect.y - rect.height + 8
        draw_underlined_value(rect, value)
        @canvas.stroke_segment([rect.x, baseline], [rect.x + rect.width - 2, baseline])
        tiny_label(rect.at(y: baseline), label, align: :left)
      end

      def circle_value(rect, value, label)
        @canvas.stroke_circle(circle_center(rect), circle_radius(rect))
        draw_circle_text(rect, value, label)
      end

      def ability_label_box(rect, ability)
        framed_value(rect, "")
        draw_ability_text(rect, ability)
      end

      private

      def render_framed_text(rect, value, align, size)
        return if value.to_s.empty?

        @canvas.styled_text(value.to_s, rect.x + 2, rect.y - 2,
                            size:, width: rect.width - 4, align:)
      end

      def render_inside_label(rect, label, align)
        @canvas.styled_text(label, rect.x + 2, rect.y - rect.height + 8,
                            size: 6, width: rect.width - 4, align:, style: :bold)
      end

      def draw_underlined_value(rect, value)
        return if value.to_s.empty?

        @canvas.with_color(Canvas::BORDER) do
          @canvas.styled_text(value.to_s, rect.x + 2, rect.y - 2,
                              size: 9, width: rect.width - 4, align: :left)
        end
      end

      def circle_center(rect)
        [rect.x + (rect.width / 2.0), rect.y - (rect.height / 2.0)]
      end

      def circle_radius(rect)
        ([rect.width, rect.height].min / 2.0) - 1
      end

      def draw_circle_text(rect, value, label)
        @canvas.with_color(Canvas::BORDER) do
          @canvas.styled_text(value.to_s, rect.x, rect.y - 1,
                              size: Canvas::BIG_VALUE_SIZE, style: :bold,
                              width: rect.width, align: :center)
          @canvas.styled_text(label, rect.x, rect.y - rect.height + 8,
                              size: 7, style: :bold, width: rect.width, align: :center)
        end
      end

      def draw_ability_text(rect, ability)
        text_x = rect.x + 4
        text_w = rect.width - 4
        @canvas.with_color(Canvas::BORDER) do
          @canvas.styled_text(ability.to_s.upcase[0, 3], text_x, rect.y - 2,
                              size: 11, style: :bold, width: text_w)
          @canvas.styled_text(ability.to_s.capitalize, text_x, rect.y - rect.height + 9,
                              size: 6, width: text_w)
        end
      end
    end
  end
end
