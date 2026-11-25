# The practice screens' parts as typle-r draws them (src/components/Practice), and the words their scripts show.
module PracticeDesignHelper
  # PracticeText's sizes (the word to type, or its display), chosen by the text's length.
  def practice_design_text_class(text, guide: false)
    length = text.to_s.chars.size
    base = "mx-auto my-0 w-4/5 max-h-[min(5lh,28dvh)] max-w-full overflow-y-auto overscroll-contain py-[0.25em] text-center font-medium whitespace-pre-wrap [overflow-wrap:anywhere] [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
    size = if length > 24 || text.to_s.include?("\n") then "text-xl leading-[1.75] sm:text-[26px]"
    elsif guide then "text-2xl leading-relaxed tracking-wide sm:text-3xl"
    elsif length > 10 then "text-[32px] leading-tight sm:text-[44px]"
    else "text-[44px] leading-tight sm:text-[64px]"
    end
    cn(base, size)
  end

  # ModeToggle: a pill holding a choice of modes. Its items are links or buttons with aria-pressed (or aria-current).
  PRACTICE_DESIGN_TOGGLE = "inline-flex h-9 shrink-0 items-center rounded-full border bg-base-200/60 p-0.5 text-[13px]"
  PRACTICE_DESIGN_TOGGLE_ITEM = "inline-flex h-full items-center rounded-full px-3 text-base-content/60 outline-none hover:text-base-content focus-visible:ring-3 focus-visible:ring-primary/50 disabled:opacity-60 aria-checked:bg-base-100 aria-checked:font-medium aria-checked:text-base-content aria-checked:shadow-sm"

  # Rank 1 as "1st" in English and "1er" in French; other languages show the number.
  def practice_design_ordinal(rank)
    case I18n.locale.to_s
    when "en" then rank.ordinalize
    when "fr" then rank == 1 ? "1er" : "#{rank}e"
    else rank.to_s
    end
  end

  def practice_design_seconds(seconds) = format("%.2f", seconds)

  # Correct keys (words when handwriting) per minute of a saved run. The record keeps no key count, so it is worked
  # out from the accuracy, or (a run without mistakes) from the letters of its words.
  def practice_design_correct(record, list)
    accuracy = record.accuracy.to_f
    if record.writing?
      [record.word_count - record.missed.size, 0].max
    elsif accuracy < 100 && record.mistakes.positive?
      (record.mistakes * accuracy / (100 - accuracy)).round
    else
      list.words.sum { |word| word.input.to_s.chars.size }
    end
  end

  def practice_design_speed(record, correct)
    record.time_ms < 1000 ? nil : (correct / (record.time_ms / 60_000.0)).round
  end

  # The words practice_controller.js, writing_controller.js and practice_run.js show; plural ones are passed as their
  # forms ({one:, other:}) and chosen in the browser.
  def practice_design_messages
    keys = {
      progressValue: "progress.value", statsSpeedUnit: "stats.speed_unit", statsWordSpeedUnit: "stats.word_speed_unit",
      feedbackMismatch: "feedback.mismatch", feedbackComposing: "feedback.composing",
      upcomingMore: "upcoming.more", upcomingDone: "upcoming.done", upcomingCurrent: "upcoming.current", upcomingPending: "upcoming.pending",
      resultTime: "result.time", resultSeconds: "result.seconds", resultAccuracy: "result.accuracy", resultMistakes: "result.mistakes",
      resultMistakesWords: "result.mistakes_words", resultSpeed: "result.speed", resultSpeedUnit: "result.speed_unit",
      resultWordSpeedUnit: "result.word_speed_unit", resultCorrect: "result.correct", resultCorrectWords: "result.correct_words",
      missedTile: "result.missed.tile", missedOf: "result.missed.of", missedTitle: "result.missed.title", missedNone: "result.missed.none",
      missedCount: "result.missed.count", writingRead: "writing_read", writingPadReading: "writing_pad_reading",
      writingPadLoading: "writing_pad_loading", writingPadFailed: "writing_pad_failed"
    }
    messages = keys.transform_values { |key| I18n.t("design.practice.#{key}") }
    # typle-r's own result strings (practice.result.*), for the result drawn in place.
    messages[:result] = I18n.t("typle.practice.result")
    messages[:modeWriting] = I18n.t("typle.practice.modeWriting")
    messages[:recallNoHint] = I18n.t("typle.practice.recall.noHint")
    messages[:recallResultHeading] = I18n.t("typle.practice.recall.resultHeading")
    messages[:switch] = I18n.t("typle.practice.switch")
    practice_messages.merge(messages)
  end
end
