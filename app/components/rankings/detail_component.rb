# typle-r RankingDetail: the open list's stats, time trend, top records and the runs at other word counts.
# The page's choices are given: the mode, the device (a DeviceOptions option), the order, whether all runs are shown and
# whether runs at other word counts are included; `rankings_url` makes the page's URL with some of them changed.
class Rankings::DetailComponent < ApplicationComponent
  delegate :current_user, :practice_name, :link_button, :records_t, :records_rich, :records_day, :records_time, :records_accuracy,
           :records_device_choices, :records_time_text, :records_short_date, :records_clock, to: :helpers

  def initialize(ranking:, mode:, device:, order:, show_all:, include_others:, rankings_url:)
    @ranking = ranking
    @list = ranking.list
    @mode = mode
    @device = device
    @order = order
    @show_all = show_all
    @include_others = include_others
    @rankings_url = rankings_url
    @now = Time.current
  end

  private

  attr_reader :ranking, :list, :device, :order, :now

  def show_all? = @show_all

  def include_others? = @include_others

  def rankings_url(changes) = @rankings_url.(changes)

  def ranked = ranking.ranked

  def practice_path = play_path(list: list.id, mode: @mode)

  # The list's runs of this mode, on any device and at any word count.
  def mode_records = @mode_records ||= list.practice_records.select { |record| record.mode == @mode }

  def last_practiced = mode_records.map(&:practiced_at).max

  def device_name = device && records_device_choices([device], mark_deleted: true).first[1]

  # The four tiles: the best, the recent average and its gap to the best, the recent accuracy, and the runs ranked.
  # Each is [term, value, note, highlighted].
  def tiles
    best = ranking.best
    recent = ranking.recent
    gap = ranking.recent_seconds - best.seconds
    unit = ->(chunks) { tag.span(chunks, class: "ml-px text-[0.8em] font-normal text-base-content/60") }
    [
      [records_t("rankings.detail.stats.best"), records_time(best.seconds), records_t("rankings.detail.stats.best_note", accuracy: records_accuracy(best.accuracy), day: records_day(best.practiced_at, now)), true],
      [records_t("rankings.detail.stats.recent_average", count: recent.size), records_time(ranking.recent_seconds),
       gap > 0.005 ? records_t("rankings.detail.stats.gap", value: format("%.2f", gap)) : records_t("rankings.detail.stats.same_as_best"), false],
      [records_t("rankings.detail.stats.average_accuracy"), "#{format("%.1f", ranking.recent_accuracy)}%", records_t("rankings.detail.stats.recent_runs", count: recent.size), false],
      [records_t("rankings.detail.stats.runs"), records_rich("rankings.detail.stats.runs_value", { unit: }, count: ranked.size),
       ranking.mixed? ? records_t("rankings.detail.stats.all_word_counts") : records_t("rankings.detail.stats.current_words", count: list.words.size), false]
    ]
  end

  def top = show_all? ? ranked : ranked.first(ListRanking::TOP)

  # The time of the latest runs.
  def trend_chart(records)
    date = ->(record) { "#{records_short_date(record.practiced_at)} #{records_clock(record.practiced_at)}" }
    render TrendChartComponent.new(
      label: records_t("rankings.detail.trend.label", name: list.full_name),
      points: records.map { |record| TrendChartComponent::Point.new(value: record.seconds, value_text: records_time_text(record.seconds), date_text: date.(record)) },
      scale: Dashboard.speed_scale(records.map(&:seconds)),
      dates: [records_short_date(records.first.practiced_at), records_short_date(records.last.practiced_at)],
      messages: "design.records.chart")
  end

  # The word counts of the runs left out (or included), and how many runs each has.
  def others_detail
    ranking.other_counts.map { |words, count| records_t("rankings.detail.others.words", words:, count:) }.join(records_t("rankings.detail.others.separator"))
  end

  def others_note
    detail = others_detail
    if ranking.fallback? then records_t("rankings.detail.others.fallback", count: list.words.size, detail:)
    elsif include_others? then records_t("rankings.detail.others.included", detail:)
    else records_rich("rankings.detail.others.excluded", { strong: ->(chunks) { tag.span(chunks, class: "font-medium text-base-content") } }, count: ranking.others.size, detail:)
    end
  end
end
