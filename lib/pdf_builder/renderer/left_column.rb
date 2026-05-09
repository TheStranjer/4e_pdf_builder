# frozen_string_literal: true

require_relative "section"
require_relative "initiative_section"
require_relative "ability_scores_section"
require_relative "hit_points_section"

module PdfBuilder
  class Renderer
    class LeftColumn < Section
      GAP = 6

      SECTIONS = [InitiativeSection, AbilityScoresSection, HitPointsSection].freeze

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
