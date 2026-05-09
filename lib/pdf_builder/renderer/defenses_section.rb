# frozen_string_literal: true

require_relative "section"

module PdfBuilder
  class Renderer
    class DefensesSection < Section
      SCORE_WIDTH  = 40
      RATIOS       = [0.18, 0.13, 0.13, 0.13, 0.13, 0.15, 0.15].freeze
      HEADERS      = ["10 + 1/2 LVL", "ABIL", "CLASS", "FEAT", "ENH", "MISC", "MISC"].freeze
      DEFENSES     = [
        ["AC",   "AC"],
        ["FORT", "Fortitude Defense"],
        ["REF",  "Reflex Defense"],
        ["WILL", "Will Defense"],
      ].freeze
      BAND_HEIGHT = 14
      LABEL_H     = 8
      ROW_HEIGHT  = 20

      def draw(rect)
        @cells.band(rect, "DEFENSES")
        widths = proportional_widths(rect.width - SCORE_WIDTH, RATIOS)
        draw_headers(rect, widths)

        cy = rect.y - BAND_HEIGHT - LABEL_H
        DEFENSES.each do |labels|
          draw_defense_row(rect.with(height: ROW_HEIGHT).at(y: cy), widths, labels)
          cy -= ROW_HEIGHT + LABEL_H
        end
        BAND_HEIGHT + LABEL_H + ((ROW_HEIGHT + LABEL_H) * DEFENSES.size)
      end

      private

      def draw_headers(rect, widths)
        breakdown_w = rect.width - SCORE_WIDTH
        labels_rect = Rect.new(rect.x + SCORE_WIDTH, rect.y - BAND_HEIGHT, breakdown_w, LABEL_H)
        @cells.tiny_label_row(labels_rect, widths, HEADERS)
      end

      def draw_defense_row(row_rect, widths, (display_label, alias_name))
        stat = @ch.stat(alias_name)
        score = stat ? stat.value : 0
        @cells.circle_value(row_rect.with(width: SCORE_WIDTH), score, display_label)

        values = breakdown_values(stat, display_label)
        breakdown_rect = row_rect.shifted(dx: SCORE_WIDTH).with(width: row_rect.width - SCORE_WIDTH)
        values.each_with_index do |v, i|
          @cells.framed_value(breakdown_rect.column(i, widths), v.zero? ? "" : v.to_s)
        end
        draw_conditional(row_rect, stat)
      end

      def breakdown_values(stat, display_label)
        ten_half = 10 + @ch.half_level
        abil = (stat ? stat.total_of_type("Ability") : 0) + armor_bonus(stat, display_label)
        [
          ten_half, abil,
          totals_or_zero(stat, "Class"), totals_or_zero(stat, "Feat"),
          enhancement_total(stat),
          totals_or_zero(stat, "Shield", "Defensive"),
          totals_or_zero(stat, "Racial", "Misc"),
        ]
      end

      def totals_or_zero(stat, *types)
        stat ? stat.total_of_type(*types) : 0
      end

      def enhancement_total(stat)
        totals_or_zero(stat, "Enhancement", "Enh")
      end

      def armor_bonus(stat, display_label)
        return 0 unless display_label == "AC" && stat

        stat.total_of_type("Armor")
      end

      def draw_conditional(row_rect, stat)
        text = conditional_text_for(stat)
        label = text.empty? ? "CONDITIONAL BONUSES" : "CONDITIONAL BONUSES  #{text}"
        label_y = row_rect.y - ROW_HEIGHT - 1
        @cells.tiny_label(Rect.new(row_rect.x, label_y, row_rect.width, LABEL_H),
                          label, align: :left)
      end

      def conditional_text_for(stat)
        return "" unless stat

        stat.adds.filter_map { |a| format_conditional(a) }.uniq.join("; ")
      end

      def format_conditional(add)
        cond = add[:conditional].to_s
        return nil if cond.empty?

        sign = add[:value].to_i.negative? ? "" : "+"
        "#{sign}#{add[:value]} #{cond}"
      end
    end
  end
end
