# frozen_string_literal: true

require_relative "section"
require_relative "movement_section"
require_relative "senses_section"
require_relative "attack_workspace_section"
require_relative "damage_workspace_section"
require_relative "basic_attacks_section"

module PdfBuilder
  class Renderer
    class RightColumn < Section
      GAP = 6

      SECTIONS = [
        MovementSection, SensesSection, AttackWorkspaceSection,
        DamageWorkspaceSection, BasicAttacksSection,
      ].freeze

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
