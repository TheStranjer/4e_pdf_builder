# frozen_string_literal: true

require_relative "section"
require_relative "defenses_section"
require_relative "action_points_section"
require_relative "race_features_section"

module PdfBuilder
  class Renderer
    class CenterColumn < Section
      GAP = 6

      SECTIONS = [DefensesSection, ActionPointsSection, RaceFeaturesSection].freeze

      def draw(rect)
        cur = rect
        SECTIONS.each do |klass|
          consumed = klass.new(@ch, @canvas, @cells).draw(cur)
          cur = cur.shifted(dy: -consumed - GAP)
        end
      end
    end
  end
end
