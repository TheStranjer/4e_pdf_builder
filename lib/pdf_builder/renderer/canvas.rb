# frozen_string_literal: true

require "prawn"
require_relative "rect"

module PdfBuilder
  class Renderer
    # Drawing primitives over a Prawn::Document. Geometry comes in as Rects
    # with top-left anchoring; the rect's height is implied for things like
    # bands (always 14 pt) so call sites don't need to repeat the magic.
    class Canvas
      BAND_BG     = "1A1A1A"
      BAND_FG     = "FFFFFF"
      BORDER      = "000000"
      SUBLABEL_FG = "555555"

      SUBLABEL_SIZE     = 5
      VALUE_SIZE        = 10
      BIG_VALUE_SIZE    = 13
      BAND_TITLE_SIZE   = 9

      attr_reader :page_width, :page_height

      def initialize(pdf)
        @pdf = pdf
        @page_width  = pdf.bounds.width
        @page_height = pdf.bounds.height
      end

      def filled_rect(rect, color)
        @pdf.fill_color(color)
        @pdf.fill_rectangle([rect.x, rect.y], rect.width, rect.height)
        @pdf.fill_color(BORDER)
      end

      def stroke_rect(rect, line_width: 0.5)
        @pdf.stroke_color(BORDER)
        @pdf.line_width(line_width)
        @pdf.stroke_rectangle([rect.x, rect.y], rect.width, rect.height)
      end

      def stroke_segment(point_a, point_b, line_width: 0.4)
        @pdf.stroke_color(BORDER)
        @pdf.line_width(line_width)
        @pdf.stroke_line(point_a, point_b)
      end

      def stroke_circle(center, radius, line_width: 0.6)
        @pdf.stroke_color(BORDER)
        @pdf.line_width(line_width)
        @pdf.stroke_circle(center, radius)
      end

      def with_color(hex)
        prev = @pdf.fill_color
        @pdf.fill_color(hex)
        yield
      ensure
        @pdf.fill_color(prev) if prev
      end

      def styled_text(text, x, y, **opts)
        size = opts[:size] || VALUE_SIZE
        @pdf.formatted_text_box(
          [{ text: text.to_s, styles: text_styles(opts[:style]), size: }],
          at: [x, y],
          width: opts[:width] || (@page_width - x),
          height: size + 6,
          align: opts.fetch(:align, :left),
          leading: opts.fetch(:leading, 0),
          overflow: :shrink_to_fit,
          min_font_size: 4
        )
      rescue Prawn::Errors::CannotFit
        # Best-effort — silently drop a value that won't fit.
      end

      def text_styles(style)
        case style
        when :bold then [:bold]
        when :italic then [:italic]
        when :bold_italic then %i[bold italic]
        else []
        end
      end
    end
  end
end
