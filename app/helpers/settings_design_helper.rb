# The parts of typle-r's settings, account and info pages (src/components/Settings, Devices, About, Guide, AccountForm)
# that the pages here share. The class strings are typle-r's.
module SettingsDesignHelper
  SETTINGS_SECTION = "#{UiHelper::PANEL} p-4 sm:p-5"
  SETTINGS_LINK = "underline underline-offset-4"
  SETTINGS_GUIDE_LINK = "font-medium underline decoration-base-content/30 underline-offset-3 hover:decoration-base-content"
  SETTINGS_CHECKBOX = "size-4 shrink-0 cursor-pointer accent-primary disabled:cursor-not-allowed"

  # The marked letters of the languages the packs cover (typle-r's SimpleInputTable).
  SETTINGS_MARKED_LETTERS = "àáâãäåāăąǎçćĉċčďèéêëēĕėęěĝğġģĥìíîïĩīĭįıĵķĺļľńņňñòóôõöōŏőǒŕŗřśŝşšșţťțùúûüũūŭůűųǔŵýÿŷźżž"
  SETTINGS_CYRILLIC_LATIN = {
    "а" => "a", "б" => "b", "в" => "v", "г" => "g", "д" => "d", "е" => "e", "ё" => "yo", "ж" => "zh", "з" => "z",
    "и" => "i", "й" => "y", "к" => "k", "л" => "l", "м" => "m", "н" => "n", "о" => "o", "п" => "p", "р" => "r",
    "с" => "s", "т" => "t", "у" => "u", "ф" => "f", "х" => "kh", "ц" => "ts", "ч" => "ch", "ш" => "sh", "щ" => "shch",
    "ъ" => '"', "ы" => "y", "ь" => "'", "э" => "e", "ю" => "yu", "я" => "ya"
  }.freeze

  # A text of the design.settings namespace.
  def settings_t(key, **options) = t("design.settings.#{key}", **options)

  # A message with typle-r's rich tags (<link>…</link>): each tag is turned into a link to links[tag], the rest escaped.
  def settings_rich(text, link_class: SETTINGS_LINK, **links)
    parts = text.to_s.split(%r{(<\w+>.*?</\w+>)})
    safe_join(parts.map do |part|
      if (match = part.match(%r{\A<(\w+)>(.*)</\1>\z}))
        url = links[match[1].to_sym]
        url ? link_to(match[2], url, class: link_class) : match[2]
      else
        part
      end
    end)
  end

  # A card of the settings pages: an icon tile, the heading and the description, with the block under them.
  def settings_section(icon:, title:, id:, description: nil, &block)
    tag.section(class: SETTINGS_SECTION, "aria-labelledby": "#{id}-heading") do
      safe_join([
        tag.div(class: "grid grid-cols-[auto_minmax(0,1fr)] items-start gap-x-3 sm:gap-x-4") do
          safe_join([
            icon_tile(icon),
            tag.div(class: "min-w-0 space-y-1") do
              safe_join([tag.h2(title, id: "#{id}-heading", class: "font-bold"),
                         (tag.p(description, id: "#{id}-description", class: "text-sm text-base-content/60") if description)].compact)
            end
          ])
        end,
        (capture(&block) if block)
      ].compact)
    end
  end

  # typle-r's FormMessage: what a form did, or why it could not.
  def form_message(text, kind: :done)
    kind == :error ? tag.p(text, role: "alert", class: "text-sm text-error") : tag.p(text, role: "status", class: "text-sm")
  end

  # A record's problems, as an alert (typle-r's ErrorAlert).
  def settings_errors(record)
    return if record.nil? || record.errors.empty?
    tag.div(role: "alert", class: alert_classes(:error)) do
      safe_join([icon("circle-alert"),
                 tag.ul(class: "text-sm", "data-slot": "alert-description") { safe_join(record.errors.full_messages.map { tag.li(_1) }) }])
    end
  end

  # The marked Latin letters by the plain letter simple input accepts for them: [["a", ["à", "á", …]], …].
  def settings_marked_groups
    SETTINGS_MARKED_LETTERS.each_char.each_with_object(Hash.new { |h, k| h[k] = [] }) { |char, groups|
      base = char.unicode_normalize(:nfd).gsub(/\p{M}/, "")
      groups[base] << char if base != char && base.match?(/\A\p{Latin}\z/)
    }.sort_by(&:first)
  end

  # typle-r's Kbd of the simple input table.
  def settings_key(text) = tag.kbd(text, class: "rounded border bg-base-200 px-1.5 py-0.5 font-mono text-xs")

  # Keys of the guide ("Ctrl" "+" "Enter").
  def settings_keys(*keys)
    tag.span(class: "inline-flex flex-wrap items-center gap-1") do
      safe_join(keys.each_with_index.map { |key, index|
        tag.span(class: "inline-flex items-center gap-1") do
          safe_join([(tag.span("+", class: "text-xs text-base-content/60", "aria-hidden": "true") if index.positive?),
                     kbd(key, class: "h-6 px-2 text-xs text-base-content/80")].compact)
        end
      })
    end
  end

  # The heading of a guide section, with its icon.
  def settings_guide_section(id, icon_name, title, lead, &block)
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

  # A chip of 関心 (typle-r's InterestSettings): a toggle button that saves at once, disabled while saving.
  def settings_interest_chip(id, label, chosen)
    classes = button_classes(variant: chosen ? :primary : :outline,
                             class: cn("rounded-full px-4 text-sm disabled:opacity-60 in-[form[aria-busy=true]]:opacity-60", !chosen && "bg-base-100"))
    tag.button(label, type: "submit", name: "toggle", value: id, class: classes, "aria-pressed": chosen.to_s)
  end

  def settings_points(items)
    tag.ul(class: "list-disc space-y-1 pl-5 marker:text-base-content/36") { safe_join(Array(items).map { tag.li(_1) }) }
  end
end
