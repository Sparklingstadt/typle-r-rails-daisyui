# The parts of typle-r's guide (src/components/Guide/GuideParts.tsx): its sections, topics, points, keys, rich-text
# tags and the colour legend. The class strings are typle-r's.
module GuideDesignHelper
  GUIDE_LINK = "font-medium underline decoration-base-content/30 underline-offset-3 hover:decoration-base-content"

  # TargetText's classes for each state of a letter (the practice screen's colours).
  GUIDE_CARET = "relative after:absolute after:inset-x-0 after:-bottom-[0.08em] after:h-[max(3px,0.06em)] after:rounded-full motion-safe:after:animate-pulse"
  GUIDE_LETTER = {
    done: "text-success",
    current: "#{GUIDE_CARET} text-base-content after:bg-primary",
    error: "rounded-sm bg-error/10 text-error",
    current_error: "#{GUIDE_CARET} text-error after:bg-error",
    pending: "text-base-content"
  }.freeze

  # The legend's swatches (GuideParts' `swatch`).
  GUIDE_SWATCH = {
    done: "text-success",
    current: "underline decoration-base-content decoration-2 underline-offset-4",
    pending: "text-base-content",
    error: "text-error underline decoration-error decoration-2 underline-offset-4"
  }.freeze

  # The legend's examples: the word, what was pressed (a wrong last key is not taken) and the states it explains.
  GUIDE_LEGEND = [
    { sample: "typle", typed: "ty", missed: false, items: %i[done current pending] },
    { sample: "typle", typed: "tyo", missed: true, items: %i[error] }
  ].freeze

  # typle-r's guide message (typle.guide.*).
  def guide_t(key, **values) = tt("guide.#{key}", **values)

  # A text of the Rails guide's own (design.guide.*), where typle-r's says what this app does not do.
  def guide_own(key, **values) = t("design.guide.#{key}", **values)

  # The rich-text tags of the guide's messages: links to each screen, in-page links and key combinations.
  def guide_tags
    page = ->(url) { ->(inner) { link_to(inner, url, class: GUIDE_LINK) } }
    anchor = ->(id) { ->(inner) { tag.a(inner, href: "##{id}", class: GUIDE_LINK) } }
    {
      play: page.(play_path), create: page.(new_pack_path), edit: page.(packs_path), records: page.(practice_records_path),
      rankings: page.(rankings_path), home: page.(home_path), devices: page.(devices_path), interests: page.(interests_path),
      devicesSection: anchor.("devices"), wordCount: anchor.("word-count"),
      keys: ->(inner) { guide_keys(*inner.split("+")) }
    }
  end

  # A message with typle-r's tags (<play>…</play>, <keys>Ctrl+Enter</keys>): each tag rendered by `tags`, the rest escaped.
  def guide_rich(text, tags = guide_tags)
    parts = []
    rest = text.to_s
    while (match = rest.match(%r{<(\w+)>(.*?)</\1>}m))
      parts << match.pre_match
      handler = tags[match[1].to_sym]
      parts << (handler ? handler.(match[2]) : match[2])
      rest = match.post_match
    end
    parts << rest
    safe_join(parts)
  end

  # GuideSection: a section of the guide with its icon, heading and lead.
  def guide_section(id, icon_name, title, lead, &block)
    tag.section(id:, "aria-labelledby": "#{id}-heading", class: "border-t pt-8") do
      safe_join([
        tag.h2(id: "#{id}-heading", class: "flex items-center gap-2.5 text-xl font-bold") do
          safe_join([tag.span(icon(icon_name, class: "size-4.5"), class: "grid size-8 shrink-0 place-items-center rounded-lg bg-base-200 text-base-content/60"), title])
        end,
        tag.p(lead, class: "mt-3 text-base-content/60"),
        tag.div(capture(&block), class: "mt-5 space-y-5")
      ])
    end
  end

  # Topic: a heading with the block under it.
  def guide_topic(title, &block)
    tag.div { safe_join([tag.h3(title, class: "mb-2 text-base font-bold"), capture(&block)]) }
  end

  # Points: a bulleted list of the items (each a string or HTML, or [content, li options]).
  def guide_points(*items)
    tag.ul(class: "list-disc space-y-1 pl-5 marker:text-base-content/36") do
      safe_join(items.compact.map { |item| item.is_a?(Array) ? tag.li(item[0], **item[1]) : tag.li(item) })
    end
  end

  # Keys: "Ctrl" "+" "Enter".
  def guide_keys(*keys)
    tag.span(class: "inline-flex flex-wrap items-center gap-1") do
      safe_join(keys.each_with_index.map { |key, index|
        tag.span(class: "inline-flex items-center gap-1") do
          safe_join([(tag.span("+", class: "text-xs text-base-content/60", "aria-hidden": "true") if index.positive?),
                     kbd(key, class: "h-6 px-2 text-xs text-base-content/80")].compact)
        end
      })
    end
  end

  # typle-r's compareInput: the state of each letter of `target` after `typed` (`missed`: the last key was wrong).
  def guide_letter_states(target, typed, missed)
    characters = target.chars
    actual = typed.chars
    error = actual.each_index.find { |index| index < characters.size && actual[index] != characters[index] }
    error = characters.size if error.nil? && actual.size > characters.size
    error = actual.size if error.nil? && missed
    characters.each_with_index.map do |char, index|
      state = if index < actual.size then error.nil? || index < error ? :done : :error
      elsif index == actual.size then error.nil? ? :current : :current_error
      else :pending
      end
      [char, state]
    end
  end
end
