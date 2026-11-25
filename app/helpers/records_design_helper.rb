# typle-r's record pieces for 練習記録 and ベスト記録 (src/components/Records, src/components/Rankings), with the formats
# of its useFormat. Text lives under design.records (config/locales/design/records.*.yml).
module RecordsDesignHelper
  LOW_ACCURACY = 90
  # Shared by the column labels and the rows so the numbers line up under their headings (RecordRow's recordColumns).
  RECORDS_COLUMNS = "sm:grid-cols-[3.25rem_minmax(0,1fr)_7rem_4.75rem_5.25rem_3rem_2.5rem] sm:gap-x-4"
  RECORDS_MENU_ITEM = UiHelper::MENU_INSET_ITEM

  def records_t(key, **options) = t("design.records.#{key}", **options)

  # A message with typle-r's rich-text tags (<rankings>…</rankings>): each tag's chunk goes through the lambda of its name.
  def records_rich(key, tags = {}, **options)
    text = ERB::Util.html_escape(records_t(key, **options)).to_str
    tags.each do |name, render|
      text = text.gsub(%r{&lt;#{name}&gt;(.*?)&lt;/#{name}&gt;}m) { ERB::Util.html_escape(render.(Regexp.last_match(1).html_safe)) }
    end
    text.html_safe
  end

  def records_unit_space = I18n.locale.to_s.start_with?("ja", "zh") ? "" : " "

  # RecordTime: seconds with two decimals, a minute or more as minutes and seconds, the units smaller than the numbers.
  def records_time(seconds, class: nil)
    space = records_unit_space
    spans = records_time_parts(seconds).each_with_index.map { |(value, unit), index|
      tag.span(safe_join([(space if index.positive?), value, space, tag.span(records_t("format.units.#{unit}"), class: "ml-px text-[0.8em] font-normal text-base-content/60")].compact))
    }
    tag.span(safe_join(spans), class: cn("tabular-nums", binding.local_variable_get(:class)), title: records_t("history.row.seconds", value: format("%.2f", seconds)))
  end

  def records_time_text(seconds)
    space = records_unit_space
    records_time_parts(seconds).map { |value, unit| "#{value}#{space}#{records_t("format.units.#{unit}")}" }.join(space)
  end

  def records_time_parts(seconds)
    hundredths = (seconds * 100).round
    return [[format("%.2f", hundredths / 100.0), "seconds"]] if hundredths < 6000
    [[(hundredths / 6000).to_s, "minutes"], [format("%05.2f", (hundredths % 6000) / 100.0), "seconds"]]
  end

  # Practice time in whole seconds, minutes or hours (format.duration).
  def records_duration(seconds)
    total = seconds.round
    parts = if total < 60 then [[total, "seconds"]]
    elsif total < 3600 then [[total / 60, "minutes"], [total % 60, "seconds"]]
    else [[total / 3600, "hours"], [total % 3600 / 60, "minutes"]]
    end
    space = records_unit_space
    parts.map { |value, unit| "#{value}#{space}#{records_t("format.units.#{unit}")}" }.join(space)
  end

  def records_accuracy(accuracy) = format_accuracy(accuracy)

  def records_date_parts(time) = { year: time.year, month: time.month, day: time.day, month_name: records_t("extra.months").split(",")[time.month - 1] }

  # 9月19日, with the year only when it is not this year.
  def records_date(time, now = Time.current)
    records_t(time.year == now.year ? "extra.month_day" : "extra.year_month_day", **records_date_parts(time))
  end

  # 今日, 昨日 or the date (format.day).
  def records_day(time, now = Time.current)
    case (now.to_date - time.to_date).to_i
    when 0 then records_t("format.today")
    when 1 then records_t("format.yesterday")
    else records_date(time, now)
    end
  end

  def records_today?(time, now = Time.current) = time.to_date == now.to_date

  # The heading of a day: today and yesterday are named before the date with its weekday (useDayHeading).
  def records_day_heading(day, now = Time.current)
    date = records_t("format.date_with_weekday", date: records_date(day, now), weekday: records_t("extra.weekdays").split(",")[day.wday])
    (now.to_date - day.to_date).to_i.in?(0..1) ? records_t("history.day.heading", relative: records_day(day, now), date:) : date
  end

  # typle-r's format.clock (Intl hour and minute, 2-digit): 24 hours, but "02:05 PM" in English and "下午02:05" in
  # Traditional Chinese, as the browser writes them.
  def records_clock(time)
    hour12 = format("%02d", (time.hour % 12).nonzero? || 12)
    case I18n.locale.to_s
    when "en" then "#{hour12}:#{time.strftime("%M")} #{time.hour < 12 ? "AM" : "PM"}"
    when "zh-Hant" then "#{time.hour < 12 ? "上午" : "下午"}#{hour12}:#{time.strftime("%M")}"
    else time.strftime("%H:%M")
    end
  end
  def records_numeric_date(time) = records_t("extra.numeric_date", **records_date_parts(time))
  def records_short_date(time) = records_t("extra.short_date", **records_date_parts(time))

  # The device a record was made on, by name alone, or with its layout (format.deviceName / format.device).
  def records_device_name(record) = record.device_key == Device::DEFAULT_KEY ? records_t("format.default_device") : record.device_name

  def records_device(record)
    return records_t("format.no_device_recorded") if record.device_key.nil?
    record.device_layout.present? ? records_t("format.device_with_layout", name: records_device_name(record), layout: record.device_layout) : records_device_name(record)
  end

  def records_level_name(list) = list.level.presence || list.name

  # BestBadge / RecallBadge / the handwriting badge of a row.
  def records_best_badge
    tag.span(safe_join([icon(:trophy, class: "size-3"), records_t("history.row.best")]), title: records_t("history.row.best_title"),
      class: badge_classes(variant: :warning, class: "font-bold"))
  end

  def records_mode_badge(record)
    if record.writing?
      tag.span(safe_join([icon("pen-line", class: "size-3"), records_t("history.mode_writing")]), class: badge_classes(variant: :outline))
    elsif record.recall?
      tag.span(records_t("history.recall_badge"), class: badge_classes(variant: :info, class: "font-bold"))
    end
  end

  # The device choices, labelled as typle-r does: deleted devices are marked.
  def records_device_choices(device_options, mark_deleted: false)
    device_options.map { |option|
      label = option.value == ListRanking::NO_DEVICE ? records_t("format.no_device_recorded") : records_device(option.latest)
      label = records_t("rankings.filter.deleted", name: label) if mark_deleted && option.deleted
      [option.value, label, option.count]
    }
  end

  # ModeToggle / OrderToggle (typle-r's Radix RadioGroup): radio buttons, the chosen one raised; choosing one opens its URL.
  def records_pill(label:, items:, **options)
    tag.div(role: "radiogroup", class: UiHelper::SEGMENTED, "aria-label": label, "aria-orientation": "horizontal", data: { controller: "radio-group" }, **options) do
      safe_join(items.map { |text, url, current, data = {}|
        tag.button(tag.span(text), type: "button", role: "radio", class: UiHelper::SEGMENTED_ITEM, "aria-checked": current.to_s, tabindex: (current ? 0 : -1),
          data: { url:, radio_group_target: "radio", action: "radio-group#choose keydown->radio-group#key", **data })
      })
    end
  end

  def records_rank_badge(rank)
    tag.span(rank, class: cn("grid size-6 place-items-center rounded-full bg-base-200 text-xs font-bold text-base-content/60", rank == 1 && "bg-warning/15 text-warning"))
  end
end
