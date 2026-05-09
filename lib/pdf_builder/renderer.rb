require "prawn"
require_relative "character"

module PdfBuilder
  # Draws a Character onto a single landscape-letter PDF page that
  # mirrors the canonical 4e character-sheet layout: a header strip
  # plus three data columns of dark section bands, breakdown grids,
  # and bordered value cells.
  #
  # All coordinates are in PDF points and use Prawn's default
  # bottom-left origin (so y values *decrease* moving down). Each
  # `draw_*` helper takes the TOP-LEFT corner of its region and
  # returns the height it consumed; the column drivers use that
  # to advance their cursor.
  class Renderer
    PAGE_SIZE   = "LETTER"
    PAGE_LAYOUT = :landscape
    MARGIN      = 18

    BAND_BG     = "1A1A1A"
    BAND_FG     = "FFFFFF"
    BORDER      = "000000"
    SUBLABEL_FG = "555555"

    SUBLABEL_SIZE     = 5
    VALUE_SIZE        = 10
    BIG_VALUE_SIZE    = 13
    BAND_TITLE_SIZE   = 9
    HEADER_TITLE_SIZE = 22

    def self.render(character, output_path)
      new(character).render(output_path)
    end

    def initialize(character)
      @ch = character
    end

    def render(output_path)
      Prawn::Document.generate(
        output_path,
        page_size:   PAGE_SIZE,
        page_layout: PAGE_LAYOUT,
        margin:      MARGIN,
      ) do |pdf|
        @pdf    = pdf
        @page_w = pdf.bounds.width
        @page_h = pdf.bounds.height
        layout
      end
      output_path
    end

    private

    # ------------------------------------------------------------------
    # Top-level layout
    # ------------------------------------------------------------------

    def layout
      header_h = 80
      draw_header(0, @page_h, @page_w, header_h)

      body_top = @page_h - header_h - 4
      gap      = 6
      col_w    = (@page_w - 2 * gap) / 3.0

      draw_left_column(0,                       body_top, col_w)
      draw_center_column(col_w + gap,           body_top, col_w)
      draw_right_column((col_w + gap) * 2,      body_top, col_w)
    end

    # ------------------------------------------------------------------
    # Header band
    # ------------------------------------------------------------------

    def draw_header(x, y, w, _h)
      band_h = 32
      filled_rect(x, y, w, band_h, BAND_BG)

      with_color(BAND_FG) do
        styled_text("DUNGEONS & DRAGONS", x + 8, y - 6,
                    size: HEADER_TITLE_SIZE, style: :bold)
        styled_text("Character Sheet", x + w - 150, y - 6,
                    size: 14, style: :bold, width: 145, align: :right)
      end

      # Player Name rendered in white inside the dark band, right side.
      with_color(BAND_FG) do
        styled_text("Player: #{@ch.player}", x + w - 150, y - band_h + 8,
                    size: 9, style: :bold, width: 145, align: :right)
      end

      row_y = y - band_h - 6
      char_fields_row1(x, row_y, w, 22)

      row_y -= 24
      char_fields_row2(x, row_y, w, 22)
    end

    def char_fields_row1(x, y, w, h)
      widths = proportional_widths(w, [0.30, 0.07, 0.18, 0.18, 0.16, 0.11])
      labels = ["Character Name", "Level", "Class", "Paragon Path", "Epic Destiny", "Total XP"]
      values = [@ch.name, @ch.level, @ch.class_name, @ch.paragon_path, @ch.epic_destiny, @ch.total_xp]
      draw_field_row(x, y, widths, h, labels, values)
    end

    def char_fields_row2(x, y, w, h)
      widths = proportional_widths(w, [0.10, 0.07, 0.05, 0.07, 0.08, 0.08, 0.10, 0.10, 0.20, 0.15])
      labels = ["Race", "Size", "Age", "Gender", "Height", "Weight",
                "Alignment", "Deity", "Adventuring Company", "RPGA Number"]
      values = [@ch.race, @ch.size, @ch.age, @ch.gender, @ch.height, @ch.weight,
                @ch.alignment, @ch.deity, @ch.company, @ch.rpga_number]
      draw_field_row(x, y, widths, h, labels, values)
    end

    def proportional_widths(total, ratios)
      ratios.map { |r| r * total }
    end

    def draw_field_row(x, y, widths, h, labels, values)
      cx = x
      labels.zip(values, widths).each do |label, value, w|
        underlined_field(cx, y, w, h, label, value.to_s)
        cx += w
      end
    end

    # ------------------------------------------------------------------
    # Left column
    # ------------------------------------------------------------------

    def draw_left_column(x, y, w)
      cur = y
      cur -= draw_initiative(x, cur, w)        + 6
      cur -= draw_ability_scores(x, cur, w)    + 6
      draw_hit_points(x, cur, w)
    end

    def draw_initiative(x, y, w)
      band(x, y, w, "INITIATIVE")
      cy = y - 14

      score_w  = 60
      label_h  = 8
      box_h    = 16

      # Header labels above the boxes.
      tiny_label(x, cy, score_w, "SCORE", align: :left)
      breakdown_x = x + score_w + 6
      breakdown_w = w - score_w - 6
      cell_w = breakdown_w / 3.0
      ["DEX", "1/2 LVL", "MISC"].each_with_index do |lbl, i|
        tiny_label(breakdown_x + i * cell_w, cy, cell_w, lbl)
      end

      cy -= label_h

      framed_value(x, cy, score_w, box_h,
                   @ch.stat_value("Initiative").to_s,
                   size: BIG_VALUE_SIZE, label_inside: "Initiative")
      values = [@ch.dexterity.modifier, @ch.half_level, 0]
      values.each_with_index do |v, i|
        framed_value(breakdown_x + i * cell_w, cy, cell_w, box_h, v.to_s)
      end

      cy -= box_h
      tiny_label(x, cy - 1, w, "CONDITIONAL MODIFIERS", align: :left)

      14 + label_h + box_h + 8
    end

    def draw_ability_scores(x, y, w)
      band(x, y, w, "ABILITY SCORES")
      cy = y - 14

      header_widths = proportional_widths(w, [0.20, 0.34, 0.20, 0.26])
      tiny_label_row(x, cy, header_widths,
                     ["SCORE", "ABILITY", "ABIL MOD", "MOD + 1/2 LVL"])
      cy -= 8

      row_h = 18
      Character::ABILITIES.each do |a|
        ability = @ch.public_send(a)
        modlvl  = ability.modifier + @ch.half_level

        cur_x = x
        framed_value(cur_x, cy, header_widths[0], row_h, ability.score.to_s)
        cur_x += header_widths[0]

        ability_label_box(cur_x, cy, header_widths[1], row_h, a)
        cur_x += header_widths[1]

        framed_value(cur_x, cy, header_widths[2], row_h, ability.modifier.to_s)
        cur_x += header_widths[2]

        framed_value(cur_x, cy, header_widths[3], row_h, modlvl.to_s)
        cy -= row_h
      end

      14 + 8 + (row_h * Character::ABILITIES.size)
    end

    def draw_hit_points(x, y, w)
      band(x, y, w, "HIT POINTS")
      cy = y - 14

      max_hp     = @ch.stat_value("Hit Points")
      bloodied   = max_hp / 2
      surge_val  = (max_hp / 4.0).floor
      surges_day = @ch.stat_value("Healing Surges")

      cell_w = w / 4.0
      tiny_label_row(x, cy, [cell_w] * 4, ["MAX HP", "BLOODIED", "SURGE VALUE", "SURGES/DAY"])
      cy -= 8
      [max_hp, bloodied, surge_val, surges_day].each_with_index do |v, i|
        framed_value(x + i * cell_w, cy, cell_w, 18, v.to_s)
      end
      cy -= 18 + 4

      tiny_label_row(x, cy, [cell_w * 2, cell_w * 2],
                     ["CURRENT HIT POINTS", "CURRENT SURGE USES"])
      cy -= 8
      box(x, cy, cell_w * 2, 14)
      box(x + cell_w * 2, cy, cell_w * 2, 14)
      cy -= 14 + 6

      band(x, cy, w, "SECOND WIND  1/ENCOUNTER", title_size: 7)
      cy -= 14
      tiny_label(x, cy, w, "TEMPORARY HIT POINTS", align: :left)
      cy -= 8
      box(x, cy, w, 12)
      cy -= 12 + 6

      band(x, cy, w, "DEATH SAVING THROW FAILURES", title_size: 7)
      cy -= 14

      tiny_label(x, cy, w, "SAVING THROW MODS", align: :left)
      cy -= 8
      sval = @ch.saving_throw_mods.join(", ")
      sval = "+5 Racial bonus against fear" if sval.empty? && halfling?
      framed_value(x, cy, w, 12, sval, size: 7, align: :left)
      cy -= 12 + 4

      tiny_label(x, cy, w, "RESISTANCES", align: :left)
      cy -= 8
      box(x, cy, w, 12)
      cy -= 12 + 4

      tiny_label(x, cy, w, "CURRENT CONDITIONS AND EFFECTS", align: :left)
      cy -= 8
      box(x, cy, w, 12)
    end

    def halfling?
      @ch.race.to_s.downcase.include?("halfling")
    end

    # ------------------------------------------------------------------
    # Center column
    # ------------------------------------------------------------------

    def draw_center_column(x, y, w)
      cur = y
      cur -= draw_defenses(x, cur, w)        + 6
      cur -= draw_action_points(x, cur, w)   + 6
      draw_race_features(x, cur, w)
    end

    def draw_defenses(x, y, w)
      band(x, y, w, "DEFENSES")
      cy = y - 14

      score_w   = 40
      remaining = w - score_w
      breakdown_widths = proportional_widths(remaining,
                                             [0.18, 0.13, 0.13, 0.13, 0.13, 0.15, 0.15])
      headers = ["10 + 1/2 LVL", "ABIL", "CLASS", "FEAT", "ENH", "MISC", "MISC"]

      sub_x = x + score_w
      headers.each_with_index do |hd, i|
        tiny_label(sub_x + breakdown_widths[0...i].sum, cy, breakdown_widths[i], hd)
      end
      cy -= 8

      defs = [
        ["AC",   "AC"],
        ["FORT", "Fortitude Defense"],
        ["REF",  "Reflex Defense"],
        ["WILL", "Will Defense"],
      ]

      row_h = 20
      defs.each do |display_label, alias_name|
        s = @ch.stat(alias_name)
        score = s ? s.value : 0

        circle_value(x, cy, score_w, row_h, score, display_label)

        ten_half    = 10 + @ch.half_level
        abil_total  = s ? s.total_of_type("Ability") : 0
        if display_label == "AC"
          abil_total += s ? s.total_of_type("Armor") : 0
        end
        class_total = s ? s.total_of_type("Class") : 0
        feat_total  = s ? s.total_of_type("Feat") : 0
        enh_total   = s ? s.total_of_type("Enhancement", "Enh") : 0
        misc1       = s ? s.total_of_type("Shield", "Defensive") : 0
        misc2       = s ? s.total_of_type("Racial", "Misc") : 0

        values = [ten_half, abil_total, class_total, feat_total, enh_total, misc1, misc2]
        values.each_with_index do |v, i|
          framed_value(sub_x + breakdown_widths[0...i].sum, cy,
                       breakdown_widths[i], row_h,
                       v.zero? ? "" : v.to_s)
        end

        cond = conditional_text_for(s)
        if !cond.empty?
          tiny_label(x, cy - row_h - 1, w,
                     "CONDITIONAL BONUSES  #{cond}", align: :left)
        else
          tiny_label(x, cy - row_h - 1, w, "CONDITIONAL BONUSES", align: :left)
        end
        cy -= row_h + 8
      end

      14 + 8 + (row_h + 8) * defs.size
    end

    def conditional_text_for(stat)
      return "" unless stat

      stat.adds.filter_map do |a|
        cond = a[:conditional].to_s
        next nil if cond.empty?
        sign = a[:value].to_i >= 0 ? "+" : ""
        "#{sign}#{a[:value]} #{cond}"
      end.uniq.join("; ")
    end

    def draw_action_points(x, y, w)
      band(x, y, w, "ACTION POINTS")
      cy = y - 14

      box_w = 60
      framed_value(x, cy, box_w, 22, "", size: BIG_VALUE_SIZE)
      with_color(BORDER) do
        styled_text("Action Points", x + 2, cy - 6, size: 8, style: :bold)
      end

      info_x = x + box_w + 8
      info_w = w - box_w - 8
      tiny_label(info_x, cy, info_w / 2.0, "MILESTONES", align: :left)
      tiny_label(info_x + info_w / 2.0, cy, info_w / 2.0, "ACTION POINTS", align: :left)

      with_color(BORDER) do
        styled_text("0\n1\n2", info_x, cy - 10, size: 7, leading: 1, width: info_w / 2.0)
        styled_text("1\n2\n3", info_x + info_w / 2.0, cy - 10,
                    size: 7, leading: 1, width: info_w / 2.0)
      end

      cy -= 36
      tiny_label(x, cy, w, "ADDITIONAL EFFECTS FOR SPENDING ACTION POINTS", align: :left)
      14 + 36 + 8
    end

    def draw_race_features(x, y, w)
      band(x, y, w, "RACE FEATURES")
      cy = y - 14 - 4

      with_color(BORDER) do
        @ch.race_features.each do |rf|
          line = rf.name.to_s
          line += " — #{rf.description.gsub(/\s+/, ' ').strip}" if rf.description
          styled_text(line, x + 2, cy, size: 7, width: w - 4)
          cy -= 14
        end
      end
    end

    # ------------------------------------------------------------------
    # Right column
    # ------------------------------------------------------------------

    def draw_right_column(x, y, w)
      cur = y
      cur -= draw_movement(x, cur, w)            + 6
      cur -= draw_senses(x, cur, w)              + 6
      cur -= draw_attack_workspace(x, cur, w)    + 6
      cur -= draw_damage_workspace(x, cur, w)    + 6
      draw_basic_attacks(x, cur, w)
    end

    def draw_movement(x, y, w)
      band(x, y, w, "MOVEMENT")
      cy = y - 14

      score_w = 60
      tiny_label(x, cy, score_w, "SCORE", align: :left)

      bx = x + score_w + 6
      bw = w - score_w - 6
      headers = ["BASE", "ARMOR", "ITEM", "MISC"]
      cell_w = bw / headers.size.to_f
      headers.each_with_index do |hd, i|
        tiny_label(bx + i * cell_w, cy, cell_w, hd)
      end
      cy -= 8

      framed_value(x, cy, score_w, 18, @ch.stat_value("Speed").to_s,
                   size: BIG_VALUE_SIZE, label_inside: "Speed (Squares)")

      speed = @ch.stat("Speed")
      base  = base_value("Speed")
      armor = speed ? speed.total_of_type("Armor") : 0
      item  = speed ? speed.total_of_type("Item") : 0
      misc  = speed ? (speed.value - base - armor - item) : 0
      values = [base, armor, item, misc]

      values.each_with_index do |v, i|
        framed_value(bx + i * cell_w, cy, cell_w, 18, v.zero? ? "" : v.to_s)
      end

      cy -= 18 + 2
      tiny_label(x, cy, w, "SPECIAL MOVEMENT", align: :left)
      14 + 8 + 18 + 8
    end

    def draw_senses(x, y, w)
      band(x, y, w, "SENSES")
      cy = y - 14

      score_w   = 36
      sense_w   = w - score_w - 64
      base_w    = 30
      skill_w   = 30
      tiny_label_row(x, cy, [score_w, sense_w, base_w, skill_w],
                     ["SCORE", "PASSIVE SENSE", "BASE", "SKILL BONUS"])
      cy -= 8

      [["Passive Insight", "Insight"], ["Passive Perception", "Perception"]].each do |label, src|
        score = @ch.stat_value(label)
        skill = @ch.stat_value(src)

        framed_value(x, cy, score_w, 16, score.to_s)
        with_color(BORDER) do
          styled_text(label, x + score_w + 2, cy - 4, size: 8, style: :bold)
        end
        framed_value(x + score_w + sense_w, cy, base_w, 16, "10")
        framed_value(x + score_w + sense_w + base_w + 4, cy, skill_w, 16, skill.to_s)
        cy -= 16
      end

      cy -= 2
      tiny_label(x, cy, w, "SPECIAL SENSES", align: :left)
      14 + 8 + 32 + 8
    end

    def draw_attack_workspace(x, y, w)
      band(x, y, w, "ATTACK WORKSPACE")
      cy = y - 14

      basic = @ch.powers.find { |p| p.name == "Melee Basic Attack" }
      weapons = basic ? basic.weapons.first(2) : []
      consumed = 14

      weapons.each do |wpn|
        with_color(BORDER) do
          styled_text("ABILITY: Melee Basic Attack — #{wpn.name}",
                      x + 2, cy, size: 7, style: :italic, width: w - 4)
        end
        cy -= 8

        score_w = 40
        breakdown = ["1/2 LVL", "ABIL", "CLASS", "PROF", "FEAT", "ENH", "MISC"]
        bw = (w - score_w) / breakdown.size.to_f

        tiny_label(x, cy, score_w, "ATT BONUS", align: :left)
        breakdown.each_with_index do |hd, i|
          tiny_label(x + score_w + i * bw, cy, bw, hd)
        end
        cy -= 8

        framed_value(x, cy, score_w, 16, "+#{wpn.attack_bonus}")
        components = breakdown_attack(wpn)
        components.each_with_index do |v, i|
          framed_value(x + score_w + i * bw, cy, bw, 16, v.to_s)
        end
        cy -= 16 + 4

        consumed += 8 + 8 + 16 + 4
      end

      consumed
    end

    def breakdown_attack(weapon)
      return [""] * 7 unless weapon

      half_level = @ch.half_level
      abil = case weapon.attack_stat.to_s.downcase
             when "strength"     then @ch.strength.modifier
             when "dexterity"    then @ch.dexterity.modifier
             when "constitution" then @ch.constitution.modifier
             when "intelligence" then @ch.intelligence.modifier
             when "wisdom"       then @ch.wisdom.modifier
             when "charisma"     then @ch.charisma.modifier
             else 0
             end

      total     = weapon.attack_bonus
      remainder = total - half_level - abil
      prof      = weapon.name.to_s == "Unarmed" ? 0 : 3
      feat      = remainder >= prof ? 1 : 0
      class_bon = remainder >= prof ? 1 : 0
      misc      = remainder - prof - feat - class_bon

      [half_level, abil, class_bon, prof, feat, 0, misc].map { |n| n.zero? ? "" : n.to_s }
    end

    def draw_damage_workspace(x, y, w)
      band(x, y, w, "DAMAGE WORKSPACE")
      cy = y - 14

      basic = @ch.powers.find { |p| p.name == "Melee Basic Attack" }
      weapons = basic ? basic.weapons.first(2) : []
      consumed = 14

      weapons.each do |wpn|
        with_color(BORDER) do
          styled_text("ABILITY: Melee Basic Attack — #{wpn.name}",
                      x + 2, cy, size: 7, style: :italic, width: w - 4)
        end
        cy -= 8

        damage_w = 70
        breakdown = ["ABIL", "FEAT", "ENH", "MISC", "MISC"]
        bw = (w - damage_w) / breakdown.size.to_f

        tiny_label(x, cy, damage_w, "DAMAGE", align: :left)
        breakdown.each_with_index do |hd, i|
          tiny_label(x + damage_w + i * bw, cy, bw, hd)
        end
        cy -= 8

        framed_value(x, cy, damage_w, 16, wpn.damage.to_s)
        damage_mod = parse_damage_mod(wpn.damage)
        values = [damage_mod, 0, 0, 0, 0]
        values.each_with_index do |v, i|
          framed_value(x + damage_w + i * bw, cy, bw, 16, v.zero? ? "" : v.to_s)
        end
        cy -= 16 + 4

        consumed += 8 + 8 + 16 + 4
      end

      consumed
    end

    def parse_damage_mod(damage_str)
      return 0 if damage_str.to_s.empty?

      m = damage_str.to_s.match(/([+-])\s*(\d+)\s*$/)
      return 0 unless m

      (m[1] == "-" ? -1 : 1) * m[2].to_i
    end

    def draw_basic_attacks(x, y, w)
      band(x, y, w, "BASIC ATTACKS")
      cy = y - 14

      headers = ["ATTACK", "DEFENSE", "WEAPON OR POWER", "DAMAGE"]
      hw = proportional_widths(w, [0.15, 0.15, 0.45, 0.25])
      tiny_label_row(x, cy, hw, headers)
      cy -= 8

      basic_attack_rows.each do |row|
        cur_x = x
        row.each_with_index do |val, i|
          framed_value(cur_x, cy, hw[i], 16, val.to_s, align: i == 2 ? :left : :center)
          cur_x += hw[i]
        end
        cy -= 16
      end
    end

    def basic_attack_rows
      melee  = @ch.powers.find { |p| p.name == "Melee Basic Attack" }
      ranged = @ch.powers.find { |p| p.name == "Ranged Basic Attack" }
      rows = []
      if melee
        melee.weapons.each do |w|
          rows << [w.attack_bonus.to_s, w.defense.to_s, w.name.to_s, w.damage.to_s]
        end
      end
      if ranged
        ranged.weapons.each do |w|
          label = w.name == "Unarmed" ? "Unarmed (Range)" : w.name
          rows << [w.attack_bonus.to_s, w.defense.to_s, label, w.damage.to_s]
        end
      end
      rows << ["", "", "", ""] while rows.size < 4
      rows.first(4)
    end

    # ------------------------------------------------------------------
    # Drawing primitives
    # ------------------------------------------------------------------

    def band(x, y, w, title, title_size: BAND_TITLE_SIZE)
      filled_rect(x, y, w, 14, BAND_BG)
      with_color(BAND_FG) do
        styled_text(title, x, y - 3, size: title_size, style: :bold,
                    width: w, align: :center)
      end
    end

    def circle_value(x, y, w, h, value, label)
      cx = x + w / 2.0
      cy = y - h / 2.0
      r  = [w, h].min / 2.0 - 1

      @pdf.stroke_color BORDER
      @pdf.line_width 0.6
      @pdf.stroke_circle [cx, cy], r

      with_color(BORDER) do
        styled_text(value.to_s, x, y - 1, size: BIG_VALUE_SIZE, style: :bold,
                    width: w, align: :center)
        styled_text(label, x, y - h + 8, size: 7, style: :bold,
                    width: w, align: :center)
      end
    end

    def framed_value(x, y, w, h, value, size: VALUE_SIZE, align: :center, label_inside: nil)
      @pdf.stroke_color BORDER
      @pdf.line_width 0.5
      @pdf.stroke_rectangle [x, y], w, h

      with_color(BORDER) do
        unless value.to_s.empty?
          styled_text(value.to_s, x + 2, y - 2, size: size,
                      width: w - 4, align: align)
        end

        if label_inside
          styled_text(label_inside, x + 2, y - h + 8,
                      size: 6, width: w - 4, align: align, style: :bold)
        end
      end
    end

    def underlined_field(x, y, w, h, label, value)
      with_color(BORDER) do
        if !value.to_s.empty?
          styled_text(value.to_s, x + 2, y - 2, size: 9,
                      width: w - 4, align: :left)
        end
      end
      @pdf.stroke_color BORDER
      @pdf.line_width 0.4
      @pdf.stroke_line [x, y - h + 8], [x + w - 2, y - h + 8]
      tiny_label(x, y - h + 8, w, label, align: :left)
    end

    def box(x, y, w, h)
      @pdf.stroke_color BORDER
      @pdf.line_width 0.5
      @pdf.stroke_rectangle [x, y], w, h
    end

    def filled_rect(x, y, w, h, color)
      @pdf.fill_color color
      @pdf.fill_rectangle [x, y], w, h
      @pdf.fill_color BORDER
    end

    # Wrapper around Prawn's formatted_text_box that respects style
    # (bold/italic) and silently swallows CannotFit (which Prawn raises
    # when a value is too long even after shrink_to_fit).
    def styled_text(text, x, y, size: VALUE_SIZE, style: :normal,
                    width: nil, align: :left, leading: 0)
      styles = []
      styles << :bold   if style == :bold || style == :bold_italic
      styles << :italic if style == :italic || style == :bold_italic

      width ||= @page_w - x
      @pdf.formatted_text_box(
        [{ text: text.to_s, styles: styles, size: size }],
        at:           [x, y],
        width:        width,
        height:       size + 6,
        align:        align,
        leading:      leading,
        overflow:     :shrink_to_fit,
        min_font_size: 4,
      )
    rescue Prawn::Errors::CannotFit
      # Best-effort — silently drop a value that won't fit.
    end

    def tiny_label(x, y, w, label, align: :center)
      with_color(SUBLABEL_FG) do
        styled_text(label.to_s, x, y - 1, size: SUBLABEL_SIZE,
                    width: w, align: align, style: :bold)
      end
    end

    def tiny_label_row(x, y, widths, labels)
      cx = x
      labels.zip(widths).each do |label, w|
        tiny_label(cx, y, w, label)
        cx += w
      end
    end

    def ability_label_box(x, y, w, h, ability)
      framed_value(x, y, w, h, "")
      with_color(BORDER) do
        styled_text(ability.to_s.upcase[0, 3], x + 4, y - 2,
                    size: 11, style: :bold, width: w - 4)
        styled_text(ability.to_s.capitalize, x + 4, y - h + 9,
                    size: 6, width: w - 4)
      end
    end

    def with_color(hex)
      prev = @pdf.fill_color
      @pdf.fill_color hex
      yield
    ensure
      @pdf.fill_color prev if prev
    end

    # ------------------------------------------------------------------
    # Stat-helper methods
    # ------------------------------------------------------------------

    def base_value(stat_name)
      s = @ch.stat(stat_name)
      return 0 unless s

      base = s.adds.find { |a| a[:type].nil? && a[:level] == 1 && a[:statlink].nil? }
      base ? base[:value].to_i : 0
    end
  end
end
