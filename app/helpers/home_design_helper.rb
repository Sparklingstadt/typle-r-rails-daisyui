# The home dashboard and the landing page as typle-r draws them (src/components/Dashboard, src/app/page.tsx), with
# typle-r's wording from config/locales/design/home.*.yml and its date and duration formats (src/i18n/useFormat.ts).
module HomeDesignHelper
  def home_t(key, **options) = t("design.home.#{key}", **options)

  # A message with markup in it (typle-r's t.rich): each %{name} is replaced by the given HTML, the rest is escaped.
  def home_rich(key, **parts)
    safe_join(home_t(key).split(/(%\{\w+\})/).map { |piece| piece.match?(/\A%\{\w+\}\z/) ? parts.fetch(piece[2..-2].to_sym) : piece })
  end

  # --- dates and durations ---

  def home_date_values(time)
    { year: time.year, month: time.month, day: time.day, mm: format("%02d", time.month), dd: format("%02d", time.day),
      month_name: home_t("format.month_names")[time.month], hh: format("%02d", time.hour), minute: format("%02d", time.min),
      hour12: format("%02d", (time.hour % 12).nonzero? || 12), ampm: time.hour < 12 ? "AM" : "PM", period: time.hour < 12 ? "上午" : "下午" }
  end

  # The date, with the year only when it is not this year.
  def home_date(time, now = Time.current)
    home_t(time.year == now.year ? "format.month_day" : "format.year_month_day", **home_date_values(time))
  end

  # 今日, 昨日 or the date.
  def home_day(time, now = Time.current)
    days = (now.to_date - time.to_date).to_i
    return home_t("format.today") if days.zero?
    return home_t("format.yesterday") if days == 1
    home_date(time, now)
  end

  def home_date_with_weekday(time, now = Time.current)
    home_t("format.date_with_weekday", date: home_date(time, now), weekday: home_t("format.weekday_names")[time.wday])
  end

  def home_short_date(time) = home_t("format.short_date", **home_date_values(time))
  def home_short_date_time(time) = home_t("format.short_date_time", **home_date_values(time))

  # Practice time as [value, unit] pairs: seconds under a minute, minutes and seconds under an hour, else hours and minutes.
  def home_duration_parts(seconds)
    total = seconds.round
    unit = ->(name) { home_t("format.units.#{name}") }
    return [[total.to_s, unit.(:seconds)]] if total < 60
    return [[(total / 60).to_s, unit.(:minutes)], [(total % 60).to_s, unit.(:seconds)]] if total < 3600
    [[(total / 3600).to_s, unit.(:hours)], [(total % 3600 / 60).to_s, unit.(:minutes)]]
  end

  def home_duration(seconds)
    (first, first_unit), second = home_duration_parts(seconds)
    return home_t("format.time.one", value: first, unit: first_unit) unless second
    home_t("format.time.two", first:, firstUnit: first_unit, second: second[0], secondUnit: second[1])
  end

  # A number and its unit styled apart get a space between them where the language writes one.
  def home_unit_space? = home_t("format.time.one", value: "1", unit: "x").match?(/\s/)

  # A word's meaning: its annotation, without the word itself when the annotation starts with it ("apple / りんご").
  def home_word_meaning(display, annotation)
    note = annotation.to_s.strip
    rest = display.present? && note.start_with?(display) ? note[display.size..] : ""
    rest.match?(/\A\s*\//) ? rest.sub(/\A\s*\/\s*/, "").strip : note
  end

  # --- changes (typle-r's Delta.tsx) ---

  def home_delta(icon:, good:, text:)
    tag.p(class: cn("flex gap-1 text-xs", good ? "text-success" : "text-base-content/60")) do
      safe_join([icon(icon, class: "mt-0.5 size-3.5 shrink-0"), text])
    end
  end

  def home_week_delta(current, previous, &formatter)
    return { icon: "minus", good: false, text: home_t("dashboard.week.same_as_last_week") } if formatter.((current - previous).abs) == formatter.(0)
    more = current > previous
    { icon: more ? "trending-up" : "trending-down", good: more,
      text: home_t(more ? "dashboard.week.more_than_last_week" : "dashboard.week.less_than_last_week", value: formatter.((current - previous).abs)) }
  end

  # kind :seconds (lower is better) or :points.
  def home_change_delta(change, kind, named_recent: true)
    recent = !named_recent ? "none" : change.recent_count == 1 ? "latest" : "other"
    previous = change.previous_count == 1 ? "latest" : "other"
    values = { recentCount: change.recent_count, previousCount: change.previous_count }
    difference = change.recent - change.previous
    value = format(kind == :seconds ? "%.2f" : "%.1f", difference.abs)
    if value.to_f.zero?
      return { icon: "minus", good: false, text: home_t("dashboard.change.same_recent_#{recent}_previous_#{previous}", **values) }
    end
    text = home_t("dashboard.change.#{kind}_direction_#{difference.positive? ? "up" : "other"}", value:)
    { icon: difference.positive? ? "trending-up" : "trending-down", good: difference.positive? != (kind == :seconds),
      text: home_t("dashboard.change.different_recent_#{recent}_previous_#{previous}", **values, difference: text) }
  end

  # --- the trend chart (typle-r's TrendChart.tsx); the trend-chart controller reads it out by pointer and keys ---

  # --- landing page ---

  HOME_PROGRAMMING = "プログラミング"
  HOME_LANGUAGES = "語学"

  # The official list counts (all lists, programming, languages), as typle-r's officialListCounts.
  def home_official_counts
    lists = OfficialCatalog.packs.flat_map(&:lists)
    { total: lists.size, programming: lists.count { |l| l.category == HOME_PROGRAMMING }, languages: lists.count { |l| l.category == HOME_LANGUAGES } }
  end

  # The first words shown of an official pack (its first list).
  def home_first_words(catalog_id, count) = OfficialCatalog.find(catalog_id)&.lists&.first&.words&.first(count)&.map { |w| w[:display] } || []
end
