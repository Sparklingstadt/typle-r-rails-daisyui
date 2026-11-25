require "test_helper"

class Rankings::TopRecordsComponentTest < ViewComponent::TestCase
  setup do
    @user = users(:one)
    pack = @user.packs.create!(name: "Git")
    @list = pack.word_lists.new(user: @user, name: "基本")
    @list.words.build([{ display: "a", input: "a" }])
    @list.save!
  end

  def record_run(**attributes) = @list.practice_records.create!(user: @user, time_ms: 4000, mistakes: 1, accuracy: 90, word_count: 1, practiced_at: 1.hour.ago, **attributes)

  test "runs are ranked in a table and in cards, the first marked" do
    records = [record_run, record_run(time_ms: 5000)]
    render_inline(Rankings::TopRecordsComponent.new(records:, list: @list, user: @user))

    assert_selector "table tbody tr", count: 2
    assert_selector "table tbody tr:first-child.bg-warning\\/5"
    assert_selector "ol li", count: 2
  end

  test "a removed device and another word count are marked; a run without a device shows a dash" do
    records = [record_run(device_key: "gone", device_name: "Old"), record_run(word_count: 3), record_run(device_key: nil)]
    render_inline(Rankings::TopRecordsComponent.new(records:, list: @list, user: @user))

    rows = page.all("table tbody tr")
    assert_includes rows[0].text, I18n.t("design.records.rankings.top.deleted")
    assert rows[1].has_css?("span[title='#{I18n.t("design.records.rankings.top.other_words")}']")
    assert_includes rows[2].text, "—"
  end
end
