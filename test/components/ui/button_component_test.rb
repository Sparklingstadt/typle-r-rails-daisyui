require "test_helper"

class Ui::ButtonComponentTest < ViewComponent::TestCase
  test "a link styled as a button, with its variant and size" do
    render_inline(Ui::ButtonComponent.new("戻る", url: "/packs", variant: :outline, size: :sm, icon: "arrow-left"))

    link = page.find("a[href='/packs'][data-slot=button][data-variant=outline][data-size=sm]")
    assert_equal "戻る", link.text
    assert link.has_css?("svg.lucide-arrow-left[aria-hidden=true]"), "the icon comes before the label"
    assert_includes link[:class].split, "btn-sm", "the sm size"
  end

  test "a block takes the label's place" do
    render_inline(Ui::ButtonComponent.new(url: "/home")) { "ホーム" }

    assert_selector "a[href='/home'][data-variant=primary]", text: "ホーム"
  end

  test "a button that opens a page is a button, with the page in data-visit-url" do
    render_inline(Ui::ButtonComponent.new("キャンセル", url: "/packs", as: :visit, variant: :ghost))

    assert_selector "button[type=button][data-visit-url='/packs'][data-variant=ghost]", text: "キャンセル"
    assert_no_selector "a"
  end

  test "a form button submits its request from a form that does not affect the layout" do
    render_inline(Ui::ButtonComponent.new("削除", url: "/packs/1", as: :form, method: :delete, variant: :error))

    assert_selector "form.contents[action='/packs/1'] input[name=_method][value=delete]", visible: :all
    assert_selector "form button[type=submit][data-variant=error]", text: "削除"
  end

  test "the page's class wins over the button's own" do
    render_inline(Ui::ButtonComponent.new("x", url: "/", class: "h-14 px-8"))

    classes = page.find("a")[:class].split
    assert_includes classes, "h-14"
    assert_not_includes classes, "h-11"
  end

  test "an unknown kind is refused" do
    assert_raises(ArgumentError) { Ui::ButtonComponent.new("x", url: "/", as: :span) }
  end
end
