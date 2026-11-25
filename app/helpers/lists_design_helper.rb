# Pieces of typle-r's word-pack screens (src/components/WordLists, Words, the catalog and the official pack page) that
# the lists views share.
module ListsDesignHelper
  # typle-r's PackRow and ListRow: one grid row with the name, the numbers and the actions.
  LISTS_ROW = "grid grid-cols-[minmax(0,1fr)_auto] items-center gap-x-3 px-4 py-3.5 sm:grid-cols-[minmax(0,1fr)_11rem_auto] sm:gap-x-5 sm:px-5"
  # DropdownMenuContent and DropdownMenuItem.
  LISTS_MENU = "absolute top-full right-0 z-50 mt-1 min-w-56 rounded-lg border bg-base-100 p-1 text-left text-base-content shadow-md"
  LISTS_MENU_ITEM = "flex w-full cursor-pointer items-center gap-2.5 rounded-md px-2.5 py-2 text-sm font-normal outline-none select-none hover:bg-base-200 hover:text-base-content focus-visible:bg-base-200 focus-visible:text-base-content [&_svg]:size-4 [&_svg]:shrink-0 [&_svg]:text-base-content/60"
  LISTS_MENU_DESTRUCTIVE = "flex w-full cursor-pointer items-center gap-2.5 rounded-md px-2.5 py-2 text-sm font-normal text-error outline-none select-none hover:bg-base-200 hover:text-error focus-visible:bg-base-200 [&_svg]:size-4 [&_svg]:shrink-0 [&_svg]:text-error"
  # The amber notes of the editor (the word count changing, a pack being deleted).
  LISTS_HINT = "flex gap-2 rounded-lg bg-warning/10 px-3 py-2 text-[13px] text-warning"

  # 今日, 昨日 or the date, with the year only when it is not this year (typle-r's format.day).
  def lists_day(time, now = Time.current)
    date, today = time.to_date, now.to_date
    return t("design.lists.format.today") if date == today
    return t("design.lists.format.yesterday") if date == today - 1
    date.strftime(t(date.year == today.year ? "design.lists.format.month_day" : "design.lists.format.year_month_day"))
  end

  # 練習 3回 · 最終 今日, or まだ練習していません (typle-r's usePracticeText).
  def lists_practice_text(records)
    return t("design.lists.row.not_practiced") if records.empty?
    t("design.lists.row.practiced", count: records.size, day: lists_day(records.map(&:practiced_at).max))
  end

  # The first words of a list, such as "ls・pwd・cd ほか12語".
  def lists_word_preview(words, limit = 6)
    shown = words.first(limit).map { |word| word.display.strip }.join(t("design.lists.row.separator"))
    rest = words.size - limit
    rest.positive? ? t("design.lists.row.more", words: shown, rest:) : shown
  end

  # typle-r's ListLabels: the category (with a folder icon) and tags after a name. Nothing without them.
  def lists_labels(category: nil, tags: [], class: nil)
    tags = Array(tags).compact_blank
    return if category.blank? && tags.empty?
    parts = []
    if category.present?
      parts << tag.span(class: "inline-flex h-5 max-w-full items-center gap-1 rounded-md bg-base-200 px-1.5 text-[11px] font-medium text-base-content") do
        safe_join([icon(:folder, class: "size-3 shrink-0"), tag.span("#{t("design.lists.labels.category")}: ", class: "sr-only"), tag.span(category, class: "truncate")])
      end
    end
    tags.each do |name|
      parts << tag.span(class: "inline-flex h-5 max-w-full items-center rounded-full border px-1.5 text-[11px] text-base-content/60") do
        safe_join([tag.span("#{t("design.lists.labels.tag")}: ", class: "sr-only"), tag.span("#", "aria-hidden": "true"), tag.span(name, class: "truncate")])
      end
    end
    tag.span(safe_join(parts), class: cn("relative flex min-w-0 flex-wrap items-center gap-1", binding.local_variable_get(:class)), "data-list-labels": "")
  end

  # The ⋯ button and its menu (typle-r's DropdownMenu), a button and a menu the dropdown controller opens and closes.
  def lists_menu(label:, title:, &block)
    tag.div(class: "relative", data: { controller: "dropdown" }) do
      safe_join([
        tag.button(icon("ellipsis"), type: "button", data: { dropdown_target: "trigger" }, class: button_classes(variant: :ghost, size: "icon-lg", class: "size-10 text-base-content/60"),
                    "aria-label": label, title:),
        tag.div(capture(&block), class: LISTS_MENU)
      ])
    end
  end

  def lists_menu_separator(class: nil) = tag.div(class: cn("my-1 h-px bg-base-300", binding.local_variable_get(:class)), role: "separator")

  # typle-r's FieldError: the message under a field.
  def lists_field_error(message, id: nil)
    tag.p(safe_join([icon("circle-alert", class: "mt-0.5 size-4 shrink-0"), message]), id:, class: "flex items-start gap-1.5 text-sm text-error")
  end

  # The pack's category, taken from its lists (a followed pack's lists carry the official category).
  def lists_pack_category(pack) = pack.category

  def lists_pack_records(pack) = pack.word_lists.flat_map(&:practice_records)

  # The list practised last in a pack, or its first: where 練習 starts.
  def lists_practice_target(pack)
    pack.word_lists.max_by { |list| list.practice_records.map(&:practiced_at).max || Time.at(0) }.then { |latest|
      latest&.practice_records&.any? ? latest : pack.word_lists.first
    }
  end

  # The categories and tags offered while typing (typle-r's packLabels): those of every pack of the user, most used first.
  def pack_label_suggestions
    packs = current_user.packs.includes(:word_lists)
    rank = ->(names) { names.compact_blank.group_by(&:downcase).values.sort_by { |group| [-group.size, group.first.downcase] }.map(&:first) }
    { categories: rank.(packs.map(&:category)), tags: rank.(packs.flat_map(&:tags)) }
  end
end
