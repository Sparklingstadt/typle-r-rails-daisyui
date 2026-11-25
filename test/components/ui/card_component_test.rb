require "test_helper"

class Ui::CardComponentTest < ViewComponent::TestCase
  test "a card holds its block, with daisyUI's card and the page's classes" do
    render_inline(Ui::CardComponent.new(class: "gap-2 px-4", "data-pack-id": 7)) { "中身" }

    card = page.find("div.card.card-border[data-pack-id='7']", text: "中身")
    assert_includes card[:class].split, "gap-2"
    assert_includes card[:class].split, "px-4"
  end

  test "a card can be another element" do
    render_inline(Ui::CardComponent.new(tag_name: :section)) { "x" }

    assert_selector "section.card", text: "x"
  end
end
