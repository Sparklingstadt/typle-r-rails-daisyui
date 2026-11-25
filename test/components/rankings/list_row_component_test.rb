require "test_helper"

class Rankings::ListRowComponentTest < ViewComponent::TestCase
  setup do
    user = users(:one)
    @pack = user.packs.create!(name: "Vim")
    @list = @pack.word_lists.new(user:, name: "移動", level: "初級")
    @list.words.build([ { display: "h", input: "h" }, { display: "j", input: "j" } ])
    @list.save!
    @now = Time.zone.local(2026, 11, 20, 12)
  end

  def row(selected: nil, grouped: false)
    Rankings::ListRowComponent.new(ranking: ListRanking.new(@list.reload, now: @now), selected:, href: "/rankings?list=#{@list.id}", grouped:, now: @now)
  end

  test "a list without a run is a quiet row with its word count" do
    render_inline(row)

    button = page.find("button[data-list-id='#{@list.id}'][data-visit-url='/rankings?list=#{@list.id}']")
    assert_includes button[:class].split, "text-base-content/60"
    assert_no_selector "svg.lucide-trophy"
    assert_nil button["aria-current"]
  end

  test "a list with runs shows its best, and is marked while it is chosen" do
    @list.practice_records.create!(user: @list.user, time_ms: 4000, mistakes: 0, accuracy: 100, word_count: 2, practiced_at: @now - 1.hour)
    render_inline(row(selected: @list))

    assert_selector "button[aria-current=true] svg.lucide-trophy"
    assert_text "4.00"
  end

  test "under its pack, a row shows the list's level alone" do
    render_inline(row(grouped: true))
    assert_selector "span[title='Vim › 初級']", text: "初級"

    render_inline(row(grouped: false))
    assert_selector "span[title='Vim › 初級']", text: "Vim › 初級"
  end
end
