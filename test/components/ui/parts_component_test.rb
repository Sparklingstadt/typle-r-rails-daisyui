require "test_helper"

# The small parts of the design system: Badge, EmptyState, EmptyNote, IconTile and Kbd.
class Ui::PartsComponentTest < ViewComponent::TestCase
  test "a badge shows its text or block in its variant" do
    render_inline(Ui::BadgeComponent.new("公式", variant: :secondary, title: "t"))
    assert_selector "span[data-slot=badge][title=t]", text: "公式"
    assert_includes page.find("span")[:class].split, "badge-ghost"

    render_inline(Ui::BadgeComponent.new) { "新着" }
    assert_selector "span[data-slot=badge]", text: "新着"
  end

  test "an empty state holds its block, with its icon in a circle" do
    render_inline(Ui::EmptyStateComponent.new(class: "py-12")) { "まだありません" }
    assert_selector "div.py-12[data-slot=empty-state]", text: "まだありません"

    render_inline(Ui::EmptyState::IconComponent.new("list"))
    assert_selector "span.rounded-full svg.lucide-list.size-6"
  end

  test "an empty note is a paragraph" do
    render_inline(Ui::EmptyNoteComponent.new("記録はまだありません", class: "py-4"))
    assert_selector "p.py-4[data-slot=empty-note]", text: "記録はまだありません"
    assert_not_includes page.find("p")[:class].split, "py-6", "the page's padding wins"
  end

  test "an icon tile is the icon in a rounded square" do
    render_inline(Ui::IconTileComponent.new("folder"))
    assert_selector "span[data-slot=icon-tile].rounded-field svg.lucide-folder.size-5"
  end

  test "a key" do
    render_inline(Ui::KbdComponent.new("Esc", class: "ml-auto"))
    assert_selector "kbd.ml-auto", text: "Esc"
  end
end
