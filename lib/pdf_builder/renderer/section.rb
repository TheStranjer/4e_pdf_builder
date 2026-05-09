# frozen_string_literal: true

require_relative "rect"
require_relative "cells"

module PdfBuilder
  class Renderer
    # Base class for a vertically-stacked region of the sheet. Concrete
    # sections override #draw and return the height they consumed.
    class Section
      def initialize(character, canvas, cells)
        @ch = character
        @canvas = canvas
        @cells = cells
      end

      def proportional_widths(total, ratios)
        ratios.map { |r| r * total }
      end
    end
  end
end
