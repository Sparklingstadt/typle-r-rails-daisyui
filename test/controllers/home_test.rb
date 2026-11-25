require "test_helper"

class HomeTest < ActionDispatch::IntegrationTest
  test "a guest with no records sees the welcome" do
    get home_path
    assert_response :success
    assert_select "h1", "自分の単語で、タイピング練習。"
    assert_select "[data-slot=badge]", "完了した練習 0 回"
    assert_select "a[href=?]", guide_path, "使い方"
  end

  Localization::LOCALES.each do |locale|
    test "the dashboard with trends and the landing page render in #{locale}" do
      user = users(:one)
      list = OfficialCatalog.follow(user, "pack-vim-beginner").word_lists.first
      other = OfficialCatalog.follow(user, "pack-english-basic-words").word_lists.first
      [5, 4, 3, 2, 1].each_with_index do |days, index|
        list.practice_records.create!(user:, time_ms: 3000 + index * 400, accuracy: 85 + index * 2, mistakes: 1, word_count: list.words.size,
          missed: [{ "word" => list.words.first.input, "count" => 1 }], practiced_at: days.days.ago)
      end
      other.practice_records.create!(user:, time_ms: 5000, accuracy: 100, mistakes: 0, word_count: other.words.size, practiced_at: 1.hour.ago)
      sign_in_as user
      patch locale_settings_path, params: { locale: }

      get home_path
      assert_response :success
      assert_select "h2", other.full_name
      assert_select "article h3", list.full_name
      assert_select "article svg path.stroke-info", 2
      get root_path
      assert_response :success
      assert_select "[data-controller=try-word] [data-try-word-target=letters]"
    end
  end
end
