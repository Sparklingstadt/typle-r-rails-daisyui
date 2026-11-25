# Strings and small parts shared by the pages, as typle-r has them.
module CommonDesignHelper
  # typle-r's own message (config/locales/typle, imported from typle-r/src/messages): typle-r's key path and values.
  # A plural on a variable other than count is looked up with that variable as count.
  # The few messages with more than one plural or a select are kept in their ICU form (IcuMessage).
  def tt(key, **values)
    entry = I18n.t("typle.#{key}", default: nil)
    return IcuMessage.format(entry.delete_prefix("__icu:"), values) if entry.is_a?(String) && entry.start_with?("__icu:")
    if entry.is_a?(Hash) && entry[:__var]
      var = entry[:__var].to_sym
      values = values.merge(count: values[var])
    end
    t("typle.#{key}", **values)
  end

  # typle-r's page.copySuffix ("{n, plural, =1 {（コピー）} other {（コピー{n}）}}"): =1 is its own form in every language.
  def copy_suffix(n) = n == 1 ? I18n.t("typle.wordLists.page.copySuffix.one") : tt("wordLists.page.copySuffix", n:)

  # A typle-r message as the practice scripts' message() takes it: its plural forms, or { other: text }.
  def tt_forms(key)
    entry = I18n.t("typle.#{key}")
    (entry.is_a?(Hash) ? entry.except(:__var) : { other: entry }).to_json
  end

  # typle-r's officialPack.stats: "4リスト・160語", "4 lists · 160 items".
  def pack_stats(lists, words)
    t("design.common.pack_stats.stats", lists: t("design.common.pack_stats.lists", count: lists), words: t("design.common.pack_stats.words", count: words))
  end

  # PracticeName: "pack › list" with the pack in a muted colour, or the list's name alone.
  def practice_name(list)
    pack, name = list.name_parts
    return name if pack.nil?
    parts = tt("common.packList", pack: "\u0001", list: "\u0002").split(/(\u0001|\u0002)/)
    safe_join(parts.map { |part|
      case part
      when "\u0001" then tag.span(pack, class: "font-normal text-base-content/60")
      when "\u0002" then name
      else part
      end
    })
  end

  def practice_name_text(list)
    pack, name = list.name_parts
    pack ? tt("common.packList", pack:, list: name) : name
  end

  # ListLabels: a list's category and tags, such as [プログラミング] #Kotlin.
  def list_labels(category, tags, class: nil)
    return if category.blank? && tags.blank?
    tag.span(class: cn("relative flex min-w-0 flex-wrap items-center gap-1", binding.local_variable_get(:class)), "data-list-labels": "") do
      safe_join([
        (tag.span(class: "inline-flex h-5 max-w-full items-center gap-1 rounded-md bg-base-200 px-1.5 text-[11px] font-medium text-base-content") {
          safe_join([icon(:folder, class: "size-3 shrink-0"), tag.span("#{tt("wordLists.labels.category")}: ", class: "sr-only"), tag.span(category, class: "truncate")])
        } if category.present?),
        *Array(tags).map { |name|
          tag.span(class: "inline-flex h-5 max-w-full items-center rounded-full border px-1.5 text-[11px] text-base-content/60") {
            safe_join([tag.span("#{tt("wordLists.labels.tag")}: ", class: "sr-only"), tag.span("#", "aria-hidden": "true"), tag.span(name, class: "truncate")])
          }
        }
      ].compact)
    end
  end
end
