# frozen_string_literal: true

require "prawn"
require_relative "character"
require_relative "renderer/canvas"
require_relative "renderer/cells"
require_relative "renderer/rect"
require_relative "renderer/header_section"
require_relative "renderer/left_column"
require_relative "renderer/center_column"
require_relative "renderer/right_column"

module PdfBuilder
  # Draws a Character onto a single landscape-letter PDF page that mirrors
  # the canonical 4e character-sheet layout: a header strip plus three data
  # columns of dark section bands, breakdown grids, and bordered value
  # cells. Coordinates are in PDF points and use Prawn's bottom-left origin
  # so y values *decrease* going down.
  class Renderer
    PAGE_SIZE   = "LETTER"
    PAGE_LAYOUT = :landscape
    MARGIN      = 18

    HEADER_HEIGHT = 80
    BODY_GAP      = 4
    COLUMN_GAP    = 6

    def self.render(character, output_path)
      new(character).render(output_path)
    end

    def initialize(character)
      @ch = character
    end

    def render(output_path)
      Prawn::Document.generate(
        output_path,
        page_size: PAGE_SIZE,
        page_layout: PAGE_LAYOUT,
        margin: MARGIN
      ) do |pdf|
        draw_layout(pdf)
      end
      output_path
    end

    private

    def draw_layout(pdf)
      canvas = Canvas.new(pdf)
      cells = Cells.new(canvas)
      page_rect = Rect.new(0, canvas.page_height, canvas.page_width, canvas.page_height)
      HeaderSection.new(@ch, canvas, cells).draw(page_rect.with(height: HEADER_HEIGHT))
      draw_columns(canvas, cells, page_rect)
    end

    def draw_columns(canvas, cells, page_rect)
      body_top = page_rect.y - HEADER_HEIGHT - BODY_GAP
      col_w = (page_rect.width - (2 * COLUMN_GAP)) / 3.0
      column_classes = [LeftColumn, CenterColumn, RightColumn]
      column_classes.each_with_index do |klass, idx|
        col_rect = Rect.new(idx * (col_w + COLUMN_GAP), body_top,
                            col_w, body_top - MARGIN)
        klass.new(@ch, canvas, cells).draw(col_rect)
      end
    end
  end
end
