require "test_helper"

class PracticeRecords::RowComponentTest < ViewComponent::TestCase
  setup do
    user = users(:one)
    @pack = user.packs.create!(name: "Git")
    @list = @pack.word_lists.new(user:, name: "基本")
    @list.words.build([ { display: "git status", input: "git status" }, { display: "git add", input: "git add" } ])
    @list.save!
    @slow = record(time_ms: 9000, accuracy: 95, practiced_at: Time.zone.local(2026, 11, 20, 9, 5))
    @best = record(time_ms: 8000, accuracy: 100, practiced_at: Time.zone.local(2026, 11, 20, 21, 30))
  end

  def record(**attributes)
    @list.practice_records.create!(user: @list.user, mistakes: 0, word_count: 2, device_key: "d1", device_name: "Laptop", **attributes)
  end

  test "a run in the history: its time, accuracy, words, device and a button that deletes it" do
    render_inline(PracticeRecords::RowComponent.new(record: @slow, show_list: true, in_pack: false, best: false))

    assert_selector "li[data-record-key='#{@slow.id}']"
    assert_selector "h3[title='基本']", text: "基本"
    assert_text "09:05"
    assert_text "Laptop"
    assert_selector "form[action='/records/#{@slow.id}'] button[data-delete-record]"
  end

  test "with one list chosen the device is the title" do
    render_inline(PracticeRecords::RowComponent.new(record: @slow, show_list: false, in_pack: false, best: false))

    assert_selector "h3[title='Laptop']", text: "Laptop"
  end

  test "deleting the best says which run becomes the best" do
    render_inline(PracticeRecords::RowComponent.new(record: @best, show_list: true, in_pack: false, best: true))

    details = page.find("form", visible: :all)["data-confirm-details"]
    assert_includes details, "lucide-trophy", "the note on the best is in the dialog"
    assert_includes details, "9.00", "the next best's time"
  end

  test "deleting a run that is not the best says nothing about the best" do
    render_inline(PracticeRecords::RowComponent.new(record: @slow, show_list: true, in_pack: false, best: false))

    assert_not_includes page.find("form", visible: :all)["data-confirm-details"], "lucide-trophy"
  end

  test "a low accuracy is marked" do
    low = record(time_ms: 7000, accuracy: RecordsDesignHelper::LOW_ACCURACY - 1, practiced_at: Time.zone.local(2026, 11, 20, 10))
    render_inline(PracticeRecords::RowComponent.new(record: low, show_list: true, in_pack: false, best: false))

    assert_selector "span.text-warning[title]"
  end
end
