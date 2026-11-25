require "test_helper"

class Packs::PackRowComponentTest < ViewComponent::TestCase
  setup do
    @user = users(:one)
    @pack = @user.packs.create!(name: "Git")
    @lists = %w[基本 応用].map do |name|
      list = @pack.word_lists.new(user: @user, name:)
      list.words.build([{ display: "git", input: "git" }])
      list.save!
      list
    end
    @pack.reload
  end

  test "a pack is closed, with its lists inside" do
    render_inline(Packs::PackRowComponent.new(pack: @pack))

    assert_selector "li[data-pack-id='#{@pack.id}'] button[aria-expanded=false]", text: "Git"
    assert_selector "ul#pack-#{@pack.id}[hidden] > li[data-list-id]", count: 2, visible: :all
    assert_no_selector "[data-controller=row-highlight]", visible: :all
  end

  test "an open pack shows its lists; a pointed one is also highlighted" do
    render_inline(Packs::PackRowComponent.new(pack: @pack, open: true))
    assert_selector "button[aria-expanded=true]"
    assert_no_selector "[data-controller=row-highlight]"

    render_inline(Packs::PackRowComponent.new(pack: @pack, pointed: true))
    assert_selector "button[aria-expanded=true]"
    assert_selector "div.bg-success\\/10[data-controller=row-highlight]"
  end

  test "the list pointed at is highlighted" do
    render_inline(Packs::PackRowComponent.new(pack: @pack, open: true, pointed_list_id: @lists.last.id))

    assert_selector "li[data-list-id='#{@lists.last.id}'][data-controller=row-highlight]"
    assert_selector "li[data-controller=row-highlight]", count: 1
  end

  test "a followed pack is unfollowed rather than deleted" do
    followed = OfficialCatalog.follow(@user, "pack-vim-beginner")
    render_inline(Packs::PackRowComponent.new(pack: followed))

    assert_selector "[data-slot=badge]", text: I18n.t("design.lists.follow.badge")
    assert_selector "form[action='/catalog/#{followed.catalog_id}/unfollow']", visible: :all
    assert_no_selector "form[action='/packs/#{followed.id}']", visible: :all
  end
end
