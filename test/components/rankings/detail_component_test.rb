require "test_helper"

class Rankings::DetailComponentTest < ViewComponent::TestCase
  setup do
    @user = users(:one)
    vc_test_controller.instance_variable_set(:@current_user, @user)
    pack = @user.packs.create!(name: "Git")
    @list = pack.word_lists.new(user: @user, name: "基本")
    @list.words.build([{ display: "git status", input: "git status" }, { display: "git add", input: "git add" }])
    @list.save!
  end

  def run_at(seconds, accuracy: 100, word_count: 2, device_key: "d1", at: 1.hour.ago)
    @list.practice_records.create!(user: @user, time_ms: (seconds * 1000).to_i, mistakes: 0, accuracy:, word_count:, practiced_at: at,
      device_key:, device_name: device_key && "Laptop")
  end

  def detail(device: nil, include_others: false, show_all: false)
    list = WordList.includes(:words, :practice_records).find(@list.id)
    ranking = ListRanking.new(list, device: device&.value, include_others:)
    Rankings::DetailComponent.new(ranking:, mode: nil, device:, order: "accuracy", show_all:, include_others:,
      rankings_url: ->(changes) { "/rankings?#{changes.compact.to_query}" })
  end

  test "a list never practised asks to practise it" do
    render_inline(detail)

    assert_selector "h2#ranking-title", text: "基本"
    assert_selector "h3", text: I18n.t("design.records.rankings.detail.not_practised.title")
    assert_selector "a[href='/play?list=#{@list.id}']", count: 2
  end

  test "a practised list shows the best, the trend and the top runs" do
    run_at(5, at: 2.hours.ago)
    run_at(4)
    render_inline(detail)

    assert_selector "dl > div.border-warning\\/30", count: 1, text: "4.00"
    assert_selector "[data-controller=trend-chart]"
    assert_selector "table.table-fixed tbody tr", count: 2
    assert_selector "a[href='/records?list=#{@list.id}']"
  end

  test "a device without runs of the list says so and offers every device" do
    run_at(4, device_key: "d1")
    other = DeviceOptions.new(@user, [run_at(6, device_key: "d2")]).first
    @list.practice_records.where(device_key: "d2").delete_all
    render_inline(detail(device: other))

    assert_selector "h3", text: "Laptop"
    assert_selector "a[href='/rankings?']", text: I18n.t("design.records.rankings.detail.no_device_records.show_all")
  end

  test "runs at another word count are left out, and can be included" do
    run_at(4)
    run_at(3, word_count: 5)
    render_inline(detail)
    assert_selector "a[href='/rankings?list=#{@list.id}&others=1']"
    assert_selector "table.table-fixed tbody tr", count: 1

    render_inline(detail(include_others: true))
    assert_selector "a[href='/rankings?list=#{@list.id}']", text: I18n.t("design.records.rankings.detail.others.exclude")
    assert_selector "table.table-fixed tbody tr", count: 2
  end

  test "beyond the top five, the rest is behind a link" do
    6.times { |i| run_at(4 + i, at: (i + 1).hours.ago) }
    render_inline(detail)
    assert_selector "table.table-fixed tbody tr", count: ListRanking::TOP
    assert_selector "a[aria-expanded=false][href='/rankings?all=1&list=#{@list.id}']"

    render_inline(detail(show_all: true))
    assert_selector "table.table-fixed tbody tr", count: 6
  end
end
