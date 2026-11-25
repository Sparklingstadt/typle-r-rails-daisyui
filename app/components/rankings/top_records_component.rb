# typle-r TopRecords: a list's top runs, as a fixed-width table from `sm` up and one card per run on phones. A device
# the user has since removed is marked; a run at another word count than the list's has its count.
class Rankings::TopRecordsComponent < ApplicationComponent
  Cell = Data.define(:record, :rank, :device, :words, :date, :today)

  delegate :records_t, :records_day, :records_clock, :records_today?, :records_device, :records_device_name, :records_time,
           :records_accuracy, :records_rank_badge, to: :helpers

  def initialize(records:, list:, user:)
    @records = records
    @list = list
    @device_keys = user.devices.map(&:key) << Device::DEFAULT_KEY
    @now = Time.current
  end

  private

  attr_reader :list

  def label = records_t("rankings.top.label", name: list.full_name)

  def cells
    @cells ||= @records.each_with_index.map do |record, index|
      words = (records_t("rankings.top.words", count: record.word_count) unless record.word_count == list.words.size)
      Cell.new(record:, rank: index + 1, device: device(record), words:,
        date: "#{records_day(record.practiced_at, @now)} #{records_clock(record.practiced_at)}", today: records_today?(record.practiced_at, @now))
    end
  end

  # The run's device: its short name, its full name (with the layout) and whether the user has removed it.
  def device(record)
    return { name: "—", title: records_t("format.no_device_recorded"), removed: false } if record.device_key.nil?
    { name: records_device_name(record), title: records_device(record), removed: !@device_keys.include?(record.device_key) }
  end

  def word_count(cell)
    tag.span(cell.words, class: "ml-1.5 rounded border px-1 text-[11px] font-normal text-base-content/60", title: records_t("rankings.top.other_words")) if cell.words
  end
end
