require "application_system_test_case"

# The typing practice screen (practice_controller.js, practice_run.js and typing.js): the run, its counts, its result
# and its saving.
class PracticeTest < ApplicationSystemTestCase
  def letters = find("[data-practice-target=letters]")

  # Follows the official pack from its page, which opens its first list: a guest's own list, whose runs are saved.
  def practise_followed_pack
    visit catalog_path("pack-vim-beginner")
    click_on I18n.t("design.lists.official.practice")
    assert_selector "[data-practice-save-url-value]"
    WordList.order(:id).first
  end

  test "a run of an official list is typed through and shown, not saved" do
    visit play_path(official: "vim-beginner")
    words = practice_words
    assert_selector "[data-practice-target=letters]", text: words.first["input"]

    words.each { |word| type(word["input"]) }

    assert_selector "[data-practice-target=result]"
    assert_no_selector "[data-practice-target=board]"
    within("[data-practice-target=resultBody]") { assert_text "100" }
    assert_equal 0, PracticeRecord.count
  end

  test "a wrong key is counted, and the word waits for the right one" do
    visit play_path(official: "vim-beginner")
    words = practice_words
    first = words.first["input"]
    wrong = first == "z" ? "y" : "z"

    type(wrong)
    assert_selector "[data-practice-target=mistakes]", text: "1"
    assert_selector "[data-practice-target=letters]", text: first, exact_text: false
    type(first)
    assert_selector "[data-practice-target=letters]", text: words[1]["input"]
    assert_selector "[data-practice-target=mistakes]", text: "1"
  end

  test "Escape starts the run again" do
    visit play_path(official: "vim-beginner")
    words = practice_words
    type(words[0]["input"])
    type(words[1]["input"])
    assert_selector "[data-practice-target=letters]", text: words[2]["input"]

    press(:escape)

    assert_selector "[data-practice-target=letters]", text: words[0]["input"]
    assert_selector "[data-practice-target=mistakes]", text: "0"
  end

  test "a run of one's own list is saved, with the words missed" do
    list = practise_followed_pack
    words = practice_words
    missed = words[1]["input"]

    words.each_with_index do |word, index|
      type(word["input"].start_with?("q") ? "w" : "q") if index == 1
      type(word["input"])
    end

    assert_selector "[data-practice-target=resultBody] p[role=status].text-success"
    record = PracticeRecord.sole
    assert_equal list.id, record.word_list_id
    assert_equal 1, record.mistakes
    assert_equal words.size, record.word_count
    assert_equal [{ "word" => missed, "count" => 1 }], record.missed
    assert_operator record.accuracy, :<, 100
    within("[data-practice-target=resultMissed]") { assert_text missed }
    # The page's best records are fetched again, the new run marked.
    assert_selector "#best-records tr.bg-success\\/10", count: 1, visible: :all
  end

  test "recall hides the word until it is revealed" do
    visit play_path(official: "vim-intermediate", mode: "recall")
    word = practice_words.first["input"]

    assert_selector "[data-practice-target=letters]", exact_text: "＿" * word.length
    press(%i[shift enter])

    assert_selector "[data-practice-target=letters]", exact_text: word
    type(word)
    assert_selector "[data-practice-target=progress]", text: "2"
  end

  test "the words missed can be practised again on their own, and then the whole list" do
    visit play_path(official: "vim-beginner")
    words = practice_words
    words.each_with_index do |word, index|
      type(word["input"].start_with?("q") ? "w" : "q") if index == 2
      type(word["input"])
    end

    find("[data-review-missed]").click
    assert_selector "[data-review-status]", visible: true
    assert_selector "[data-practice-target=letters]", text: words[2]["input"]
    assert_selector "[data-practice-target=progress]", text: "1"
    type(words[2]["input"])
    assert_selector "[data-practice-target=result]"

    find("[data-practice-target=result] [data-action~='practice#restart']", match: :first).click
    assert_selector "[data-practice-target=letters]", text: words[0]["input"]
    assert_no_selector "[data-review-status]", visible: true
  end

  test "the clock stands still while the input has lost the focus" do
    visit play_path(official: "vim-beginner")
    words = practice_words
    type(words[0]["input"])
    sleep 0.3
    find("h1, header", match: :first).click
    assert_selector "[data-controller~=practice].blurred"
    stopped = find("[data-practice-target=time]").text
    sleep 0.5
    assert_equal stopped, find("[data-practice-target=time]").text

    find("label[for=practice-field]").click
    assert_no_selector "[data-controller~=practice].blurred"
    type(words[1]["input"])
    assert_selector "[data-practice-target=letters]", text: words[2]["input"]
  end
end
