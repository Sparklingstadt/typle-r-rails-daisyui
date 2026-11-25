# typle-r's src/components/Dashboard/TrendCard.tsx: one list's seconds per word and accuracy over its latest runs.
class Home::TrendComponent < ApplicationComponent
  delegate :home_t, :home_rich, :home_day, :home_delta, :home_change_delta, :home_short_date, :home_short_date_time,
           :practice_name, :format_accuracy, :link_button, to: :helpers

  def initialize(trend:, now:)
    @trend = trend
    @now = now
  end

  private

  attr_reader :trend, :now

  def id = "trend-#{trend.list.id}"

  # Each metric: its title, its points and change, and the kind of its values (:seconds or :points).
  def metrics = [[home_t("dashboard.trends.speed"), trend.speed, :seconds], [home_t("dashboard.trends.accuracy"), trend.accuracy, :points]]

  # A value as the card writes it: seconds with two decimals, a percentage with one.
  def with_unit(value, kind)
    kind == :seconds ? home_t("dashboard.trends.seconds", value: format("%.2f", value)) : home_t("dashboard.trends.percent", value: format("%.1f", value))
  end

  def latest_text(metric, kind)
    home_rich("dashboard.trends.latest",
      number: tag.span(home_t("dashboard.trends.latest_number", value: with_unit(metric.points.last.value, kind)), class: "text-base font-semibold text-base-content"))
  end

  def chart(title, metric, kind)
    points = metric.points
    values = points.map(&:value)
    render TrendChartComponent.new(
      label: title,
      points: points.map { |point| TrendChartComponent::Point.new(value: point.value, value_text: with_unit(point.value, kind), date_text: home_short_date_time(point.time)) },
      scale: kind == :seconds ? Dashboard.speed_scale(values) : Dashboard.accuracy_scale(values),
      dates: [home_short_date(points.first.time), home_short_date(points.last.time)],
      messages: "design.home.dashboard.chart")
  end
end
