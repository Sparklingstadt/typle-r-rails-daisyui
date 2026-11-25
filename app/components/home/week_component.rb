# typle-r's WeekSummary: this week's runs, streak, accuracy and time, each against last week's.
class Home::WeekComponent < ApplicationComponent
  delegate :home_t, :home_delta, :home_week_delta, :home_change_delta, :home_duration, :home_duration_parts, :home_unit_space?, to: :helpers

  def initialize(dashboard:)
    @week = dashboard.week
  end

  private

  attr_reader :week

  # One figure: its label, its value in parts (number and unit), and the change under it (home_delta's arguments).
  def stat(label, parts, delta)
    spaced = home_unit_space?
    tag.div(class: "flex flex-col gap-2 rounded-xl p-3 ring-1 ring-base-content/10 sm:p-4") do
      safe_join([
        tag.dt(label, class: "text-[13px] text-base-content/60"),
        tag.dd(class: "flex flex-wrap items-baseline gap-x-0.5") {
          safe_join(parts.flat_map { |value, unit|
            [tag.span(value, class: "text-2xl font-semibold xl:text-3xl"), tag.span(unit, class: cn("mr-1 text-sm text-base-content/60", ("ml-1" if spaced && unit != "%")))]
          })
        },
        tag.dd(home_delta(**delta))
      ])
    end
  end

  def runs
    stat(home_t("dashboard.week.count"), [[week[:runs].to_s, home_t("dashboard.week.count_unit", count: week[:runs])]],
      home_week_delta(week[:runs], week[:runs_before]) { |value| home_t("dashboard.week.times", count: value) })
  end

  def streak
    delta = if week[:practiced_today] then { icon: "check", good: true, text: home_t("dashboard.week.practised_today") }
    else { icon: "keyboard", good: false, text: home_t("dashboard.week.streak_next", day: week[:streak] + 1) }
    end
    stat(home_t("dashboard.week.streak"), [[week[:streak].to_s, home_t("dashboard.week.streak_unit", count: week[:streak])]], delta)
  end

  def accuracy
    delta = if week[:accuracy_change] then home_change_delta(week[:accuracy_change], :points, named_recent: false)
    else { icon: "minus", good: false, text: home_t(week[:accuracy] ? "dashboard.week.no_comparison" : "dashboard.week.no_accuracy") }
    end
    stat(home_t("dashboard.week.accuracy", count: week[:accuracy] ? week[:accuracy_count] : 10),
      week[:accuracy] ? [[format("%.1f", week[:accuracy]), "%"]] : [["—", ""]], delta)
  end

  def time
    stat(home_t("dashboard.week.time"), home_duration_parts(week[:seconds]),
      home_week_delta(week[:seconds], week[:seconds_before]) { |value| home_duration(value) })
  end
end
