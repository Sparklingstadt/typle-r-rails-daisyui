require "test_helper"

class Ui::CardComponentTest < ViewComponent::TestCase
  test "a card holds its block, with daisyUI's card merged with the page's" do
    render_inline(Ui::CardComponent.new(class: "gap-2 px-4", "data-pack-id": 7)) { "中身" }

    assert_selector "div[data-slot=card][data-size=default][data-pack-id='7']", text: "中身"
    classes = page.find("[data-slot=card]")[:class].split
    assert_includes classes, "gap-2", "the page's class wins over the card's gap"
    assert_not_includes classes, "gap-(--card-spacing)"
    assert_includes classes, "card"
  end

  test "a card can be another element, and small" do
    render_inline(Ui::CardComponent.new(tag_name: :section, size: :sm)) { "x" }

    assert_selector "section[data-slot=card][data-size=sm]"
  end

  test "the parts carry their slot, and take their text or a block" do
    render_inline(Ui::Card::TitleComponent.new("見出し", tag_name: :h2))
    assert_selector "h2[data-slot=card-title]", text: "見出し"

    render_inline(Ui::Card::DescriptionComponent.new) { "説明" }
    assert_selector "div[data-slot=card-description]", text: "説明"

    { Ui::Card::HeaderComponent => "card-header", Ui::Card::ActionComponent => "card-action",
      Ui::Card::ContentComponent => "card-content", Ui::Card::FooterComponent => "card-footer" }.each do |component, slot|
      render_inline(component.new(class: "extra")) { "part" }
      assert_selector "div.extra[data-slot=#{slot}]", text: "part"
    end
  end

  test "text is escaped" do
    render_inline(Ui::Card::TitleComponent.new("<b>x</b>"))

    assert_no_selector "b"
    assert_text "<b>x</b>"
  end
end
