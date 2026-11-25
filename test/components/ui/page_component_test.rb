require "test_helper"

# PageMain and PageHeader, and the page's own part of the header (UiHelper#page_header).
class Ui::PageComponentTest < ViewComponent::TestCase
  test "the main column is as wide as asked" do
    render_inline(Ui::PageMainComponent.new(width: :narrow)) { "本文" }
    assert_selector "main.max-w-4xl", text: "本文"

    assert_raises(KeyError) { Ui::PageMainComponent.new(width: :huge) }
  end

  test "the header has the title, the description and the page's actions in a row" do
    render_inline(Ui::PageHeaderComponent.new("単語リスト", "説明")) { "<a href='/new'>作成</a>".html_safe }

    assert_selector "header h1", text: "単語リスト"
    assert_selector "header p", text: "説明"
    assert_selector "header > a[href='/new']", text: "作成"
  end

  test "the settings pages' header is the title and description alone" do
    render_inline(Ui::PageHeaderComponent.new("設定", nil, plain: true))

    assert_selector "header.space-y-1 > h1", text: "設定"
    assert_no_selector "header.flex"
    assert_no_selector "p"
  end
end
