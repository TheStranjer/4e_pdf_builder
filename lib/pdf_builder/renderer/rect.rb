# frozen_string_literal: true

module PdfBuilder
  class Renderer
    # Top-left anchored rectangle in Prawn coordinates (y decreases moving down).
    Rect = Struct.new(:x, :y, :width, :height) do
      def with(width: self.width, height: self.height)
        Rect.new(x, y, width, height)
      end

      def at(x: self.x, y: self.y)
        Rect.new(x, y, width, height)
      end

      def shifted(dx: 0, dy: 0)
        Rect.new(x + dx, y + dy, width, height)
      end

      def inset(top: 0, left: 0)
        Rect.new(x + left, y - top, width - left, height - top)
      end

      def column(index, widths)
        Rect.new(x + widths[0...index].sum, y, widths[index], height)
      end
    end
  end
end
