# A filter of 記録 and ベスト記録 as a pill that opens a menu: every choice (`options` as [value, label, count]) after "all"
# (`all_label`), the chosen one checked. `url` makes the page's URL for a choice's value (nil for all).
class PracticeRecords::FilterMenuComponent < ApplicationComponent
  delegate :records_t, :menu_check, to: :helpers

  def initialize(name:, all_label:, value:, options:, url:)
    @name = name
    @all_label = all_label
    @value = value
    @options = options
    @url = url
  end

  private

  attr_reader :name

  def current = @options.find { |option| option[0] == @value }

  def current_label = current ? current[1] : @all_label

  def trigger_class
    button_classes(variant: :outline, size: :sm, class: cn("h-9 max-w-full min-w-0 gap-1.5 rounded-full bg-base-100 px-3.5 text-sm font-normal aria-expanded:bg-base-200",
      current && "border-base-content/25 bg-base-200 font-medium"))
  end

  def choices = [[nil, @all_label, @options.sum { |option| option[2] }], *@options]

  def chosen?(value) = value == @value

  def url_for_choice(value) = @url.(value)
end
