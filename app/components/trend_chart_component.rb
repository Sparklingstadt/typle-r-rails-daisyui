# typle-r's TrendChart: a value over the latest runs on a 0–100 viewBox stretched to the box, the latest run marked; the
# trend-chart controller reads each run out by pointer and arrow keys, and a table holds the same for screen readers.
# Used by the dashboard's trends and by the rankings' detail; each gives the points' text in its own formats.
class TrendChartComponent < ApplicationComponent
  # A run: its value (in the scale's unit), how the value and its date are written.
  Point = Data.define(:value, :value_text, :date_text)

  delegate :trend_chart_tooltip, to: :helpers

  # `scale` has low, high, ticks and decimals (Dashboard::Scale); `dates` the first and last runs' short dates;
  # `messages` the scope of the chart's label, date and value texts.
  def initialize(label:, points:, scale:, dates:, messages:)
    @label = label
    @points = points
    @scale = scale
    @dates = dates
    @messages = messages
  end

  def render? = @points.size > 1

  private

  attr_reader :label, :points, :scale, :dates

  def message(key, **options) = t("#{@messages}.#{key}", **options)

  def last = points.size - 1

  def x(index) = (index * 100.0 / last).round(3)

  def y(value) = ((1 - (value - scale.low) / (scale.high - scale.low).to_f) * 100).round(3)

  def line = points.each_with_index.map { |point, index| "#{index.zero? ? "M" : "L"}#{x(index)} #{y(point.value)}" }.join(" ")

  def tick_text(tick) = format("%.#{scale.decimals}f", tick)

  def latest = points.last

  def slider_options
    { class: "relative h-[72px] min-w-0 flex-1 cursor-crosshair touch-pan-y rounded-sm py-2 outline-none focus-visible:ring-3 focus-visible:ring-primary/50",
      role: "slider", tabindex: 0, "aria-label": message("label", label:), "aria-valuemin": 1, "aria-valuemax": points.size,
      "aria-valuenow": points.size, "aria-valuetext": "#{latest.date_text} #{latest.value_text}",
      data: { controller: "trend-chart",
              action: "focus->trend-chart#focus blur->trend-chart#blur pointermove->trend-chart#point pointerdown->trend-chart#point pointerleave->trend-chart#leave keydown->trend-chart#key",
              trend_chart_points_value: points.each_with_index.map { |point, index| { x: x(index), y: y(point.value), value: point.value_text, date: point.date_text } }.to_json } }
  end
end
