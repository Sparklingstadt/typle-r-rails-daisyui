require "test_helper"

class PracticeRecords::FilterMenuComponentTest < ViewComponent::TestCase
  def menu(value) = PracticeRecords::FilterMenuComponent.new(name: "端末", all_label: "すべての端末", value:,
    options: [["d1", "Laptop", 3], ["d2", "Desk", 2]], url: ->(choice) { "/records?device=#{choice}" })

  test "all is chosen first, with every run" do
    render_inline(menu(nil))

    assert_selector "button[aria-label]", text: "端末"
    items = page.all("a[role=menuitemradio]", visible: :all)
    assert_equal ["/records?device=", "/records?device=d1", "/records?device=d2"], items.map { _1[:href] }
    assert_equal "true", items.first["aria-checked"]
    assert_includes items.first.text(:all), "5"
  end

  test "a chosen option reads in the pill, and is checked" do
    render_inline(menu("d2"))

    assert_selector "button.bg-base-200 span.truncate", text: "Desk"
    assert_selector "a[aria-checked=true][href='/records?device=d2'] svg.lucide-check", visible: :all
    assert_selector "a[aria-checked=true]", count: 1, visible: :all
  end
end
