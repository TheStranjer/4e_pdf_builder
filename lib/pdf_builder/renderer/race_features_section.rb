# frozen_string_literal: true

require_relative "section"

module PdfBuilder
  class Renderer
    class RaceFeaturesSection < Section
      BAND_HEIGHT = 14
      ROW_HEIGHT  = 14

      def draw(rect)
        @cells.band(rect, "RACE FEATURES")
        cy = rect.y - BAND_HEIGHT - 4
        @canvas.with_color(Canvas::BORDER) do
          @ch.race_features.each do |feature|
            @canvas.styled_text(feature_line(feature), rect.x + 2, cy,
                                size: 7, width: rect.width - 4)
            cy -= ROW_HEIGHT
          end
        end
        BAND_HEIGHT + 4 + (ROW_HEIGHT * @ch.race_features.size)
      end

      private

      def feature_line(feature)
        line = feature.name.to_s
        line += " — #{feature.description.gsub(/\s+/, " ").strip}" if feature.description
        line
      end
    end
  end
end
