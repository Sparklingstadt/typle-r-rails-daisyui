require "test_helper"

class Ui::SearchFieldComponentTest < ViewComponent::TestCase
  test "a search field is labelled, with its icon" do
    render_inline(Ui::SearchFieldComponent.new(name: "q", value: "vim", placeholder: "検索", label: "ライセンスを検索"))

    assert_selector "label.h-9 svg.lucide-search"
    assert_selector "input[type=search][name=q][value=vim][placeholder='検索'][aria-label='ライセンスを検索']"
  end

  test "a clearable field shows the link that empties it only while it has a value" do
    render_inline(Ui::ClearableSearchFieldComponent.new(name: "q", value: "git", label: "検索", size: :sm, clear_url: "/words", clear_label: "クリア"))
    assert_selector "label.input.input-sm[data-slot=search-field] input[name=q][value=git]"
    assert_selector "a[href='/words'][aria-label='クリア'].btn-circle svg.lucide-x"

    render_inline(Ui::ClearableSearchFieldComponent.new(name: "q", value: "", label: "検索", clear_url: "/words", clear_label: "クリア"))
    assert_selector "label.input:not(.input-sm)"
    assert_no_selector "a"
  end
end
