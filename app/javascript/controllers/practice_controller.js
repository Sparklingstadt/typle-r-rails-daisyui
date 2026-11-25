import { feedKey, simpleInputKeys } from "typing"
import { recallPrompt, recallDisplayHint } from "recall"
import { RunController, message, escapeHtml, noteMistake, lockControl, guardSwitches } from "practice_run"

// One run of typing practice over the words of a list. The clock starts at the first key, stands still while the
// input has no focus, and stops at the last letter. A finished run is saved (signed in) or shown here (guest, weak review).
export default class extends RunController {
  static targets = ["display", "annotation", "letters", "field", "progress", "bar", "time", "mistakes", "accuracy",
                    "reveal", "board", "result", "resultBody", "resultMissed", "speed", "typeThis", "feedback", "upcoming", "allWords",
                    "showAll", "simpleKeys"]
  static values = { words: Array, options: Object, mode: String, saveUrl: String, weakUrl: String, listId: Number, messages: Object, records: Array }

  connect() {
    this.unguard = guardSwitches(this)
    this.reset()
    this.tick = setInterval(() => this.renderStats(), 100)
    this.resumeOnKey = event => this.resumeKey(event)
    document.addEventListener("keydown", this.resumeOnKey)
    this.overlayChange = () => setTimeout(() => this.updateBlurred())
    document.addEventListener("toggle", this.overlayChange, true)
    document.addEventListener("close", this.overlayChange, true)
  }

  disconnect() {
    this.unguard?.()
    clearInterval(this.tick)
    document.removeEventListener("keydown", this.resumeOnKey)
    document.removeEventListener("toggle", this.overlayChange, true)
    document.removeEventListener("close", this.overlayChange, true)
  }

  // typle-r's usePracticeFocus: while the field has lost focus, a printable key or Enter outside another control brings it back.
  resumeKey(event) {
    if (!this.element.classList.contains("blurred") || this.finishedAt) return
    if (event.defaultPrevented || event.isComposing || event.metaKey || event.ctrlKey || event.altKey) return
    if (event.target instanceof Element && event.target.closest('input, textarea, select, button, a, [contenteditable="true"]')) return
    if (document.querySelector("[data-controller~=dropdown][open], dialog[open]")) return
    if (event.key.length !== 1 && event.key !== "Enter") return
    event.preventDefault()
    this.fieldTarget.focus()
  }

  reset() {
    this.resetRun()
    this.position = 0
    this.pending = ""
    this.missed = false
    this.revealed = false
    this.element.classList.remove("blurred")
    this.render()
    this.fieldTarget.focus()
  }

  get recall() { return this.modeValue === "recall" }
  get word() { return this.wordsValue[this.index] }
  get letters() { return Array.from(this.word.input) }

  // --- input ---

  compositionStart() { this.composing = true }

  compositionEnd() {
    this.composing = false
    this.input()
  }

  input(event) {
    if (this.composing || event?.isComposing) {
      this.renderFeedback(this.fieldTarget.value.slice(this.shownText().length) || this.fieldTarget.value)
      return
    }
    if (this.finishedAt) return
    const shown = this.shownText()
    const value = this.fieldTarget.value
    const before = { index: this.index, position: this.position, running: this.startedAt !== null }
    // Only keys added at the end count; a deletion puts the field back as it was.
    const added = value.startsWith(shown) ? Array.from(value.slice(shown.length)) : []
    for (const key of added) {
      if (this.finishedAt) break
      this.feed(key)
    }
    if (!this.finishedAt) this.fieldTarget.value = this.shownText()
    // A key within the word redraws only the letters it moved past and the counts; a new word, the first key of a run
    // and the end draw everything.
    if (this.finishedAt || this.index !== before.index || !before.running) this.render()
    else this.renderKey(before.position)
  }

  keydown(event) {
    if (event.key === "Escape") {
      event.preventDefault()
      this.reset()
    } else if (event.key === "Enter" && event.shiftKey && this.recall) {
      event.preventDefault()
      this.reveal()
    }
  }

  feed(key) {
    const now = performance.now()
    if (this.startedAt === null) this.startedAt = now
    this.attempts += 1
    const result = feedKey(key, this.letters[this.position], this.pending, this.optionsValue)
    if (result === "pending") {
      this.pending += key
    } else if (result === "accept") {
      this.pending = ""
      this.missed = false
      this.position += 1
      if (this.position >= this.letters.length) this.nextWord(now)
    } else {
      this.mistakes += 1
      this.missed = true
      this.noteMistake({ wrong: { position: this.position, typed: key } })
    }
  }

  noteMistake(change) { noteMistake(this.wordMistakes, this.index, change) }

  // Keeps the focus in the field (a mousedown on the reveal button), and keeps pasted or dropped text out of it.
  keepFocus(event) { event.preventDefault() }

  // Shows or hides every word of the list under the coming ones.
  toggleAll() {
    const shown = this.allWordsTarget.hidden
    this.allWordsTarget.hidden = !shown
    this.showAllTarget.setAttribute("aria-expanded", String(shown))
    this.fieldTarget.focus()
  }

  // Recall mode: shows the word; it counts as a word that went wrong.
  reveal() {
    if (!this.recall || this.revealed || this.finishedAt) return
    this.revealed = true
    this.noteMistake({ revealed: true })
    this.render()
    this.fieldTarget.focus()
  }

  nextWord(now) {
    this.fieldTarget.value = ""
    this.index += 1
    this.position = 0
    this.pending = ""
    this.revealed = false
    if (this.index >= this.wordsValue.length) {
      this.index = this.wordsValue.length - 1
      this.finish(now)
    }
  }

  // --- pause ---

  // typle-r's showResume: the "click to resume" cover shows while the field has lost the focus, except while the list
  // picker, the switch confirmation or the device menu is open over the practice.
  updateBlurred() {
    const field = this.hasFieldTarget ? this.fieldTarget : null
    const overlaid = document.querySelector("dialog[open], [data-practice-menu][open]")
    const blurred = this.focusedOnce && !this.finishedAt && document.activeElement !== field && !overlaid
    this.element.classList.toggle("blurred", blurred)
  }

  blur() {
    // The focus moves on after blur, so a dialog or menu opening now is seen a moment later.
    setTimeout(() => this.updateBlurred())
    this.pauseClock()
    this.render()
  }

  focus() {
    this.focusedOnce = true
    this.element.classList.remove("blurred")
    this.resumeClock()
    this.render()
  }

  // --- view ---

  shownText() { return this.letters.slice(0, this.position).join("") + this.pending }

  renderSimpleKeys(word) {
    if (!this.hasSimpleKeysTarget) return
    const keys = this.optionsValue.ignoreAccents && word && !this.recall ? simpleInputKeys(word.input) : []
    this.simpleKeysTarget.hidden = keys.length === 0
    const template = this.simpleKeysTarget.querySelector("template[data-simple-key]")
    this.simpleKeysTarget.querySelector("[data-simple-keys]").replaceChildren(...keys.map(([char, key]) => {
      const item = template.content.firstElementChild.cloneNode(true)
      item.querySelector("dt").textContent = char
      item.querySelector("kbd").textContent = key
      return item
    }))
  }

  render() {
    // A run going on locks the device and the recall switch (typle-r's PracticeHeader `running`).
    const running = this.startedAt !== null && !this.finishedAt
    this.element.dataset.running = String(running)
    this.element.querySelectorAll("[data-lock-while-running]").forEach(control => lockControl(control, running))
    const word = this.word
    const hidden = this.recall && !this.revealed && !this.finishedAt
    // typle-r's WordPrompt (where the view has the "type this" label): a word typed as shown is drawn once, as the
    // letters to type; otherwise its display comes first and the letters under it, smaller.
    const sized = this.hasTypeThisTarget
    const same = word.display === word.input
    this.displayTarget.textContent = hidden ? "？" : word.display
    this.displayTarget.classList.toggle("hidden-word", hidden)
    if (sized) {
      this.displayTarget.hidden = hidden || same
      this.typeThisTarget.hidden = hidden || same
      sizeText(this.displayTarget, word.display, false)
      sizeText(this.lettersTarget, word.input, !same && !hidden)
    }
    // Recall mode never shows the annotation as it is: it may hold the answer (typle-r's recallPrompt).
    if (this.recall) {
      const prompt = recallPrompt(word)
      const hint = recallDisplayHint(word)
      const text = [prompt, hint].filter(Boolean).join("\n")
      this.annotationTarget.textContent = text || this.messagesValue.recallNoHint || ""
      this.annotationTarget.classList.toggle("text-sm", !text)
      this.annotationTarget.classList.toggle("text-base-content/60", !text)
      this.annotationTarget.classList.toggle("whitespace-pre-line", !!text)
    } else {
      this.annotationTarget.textContent = word.annotation || ""
    }
    if (this.hasRevealTarget) this.revealTarget.hidden = !this.recall || this.revealed
    this.renderSimpleKeys(word)
    this.lettersTarget.replaceChildren(...this.letters.map((letter, index) => this.paintLetter(document.createElement("span"), letter, index, hidden)))
    const total = this.wordsValue.length
    const finished = this.finishedAt ? total : this.index
    const current = this.finishedAt ? total : this.index + 1
    this.progressTarget.textContent = this.messagesValue.progressValue
      ? message(this.messagesValue.progressValue, { current, count: total }) : `${finished} / ${total}`
    this.barTarget.style.width = `${finished / total * 100}%`
    // typle-r's PracticeProgress: the bar carries the numbers; the text beside it is only for the eye.
    const bar = this.barTarget.parentElement
    bar.setAttribute("aria-valuenow", finished)
    bar.setAttribute("aria-valuetext", this.progressTarget.textContent)
    this.element.classList.toggle("paused", this.pausedAt !== null)
    this.renderFeedback(null)
    this.renderUpcoming()
    this.renderStats()
  }

  // One letter of the word: typed, the one to type (wrong or not) or still to come; hidden in recall mode until typed.
  paintLetter(span, letter, index, hidden) {
    const done = index < this.position || this.finishedAt
    span.className = done ? "letter-done" : index === this.position ? (this.missed ? "letter-current letter-error" : "letter-current") : "letter-pending"
    const concealed = hidden && !done && !/\s/.test(letter)
    span.textContent = concealed ? "＿" : letter
    if (concealed) span.classList.add("mx-[0.08em]")
    if (letter === " ") span.classList.add("letter-space")
    return span
  }

  // A key within the word: the letters from where it was to where it is now, what is wrong, and the counts.
  renderKey(from) {
    const hidden = this.recall && !this.revealed
    const letters = this.letters
    const spans = this.lettersTarget.children
    for (let index = from; index <= this.position && index < letters.length; index++) {
      this.paintLetter(spans[index], letters[index], index, hidden)
    }
    this.renderFeedback(null)
    this.renderStats()
  }

  // Under the word: which letter is wrong, the text being composed by an input method, or how to start over.
  renderFeedback(composing) {
    if (!this.hasFeedbackTarget) return
    const state = this.missed && !this.finishedAt ? "error" : composing !== null ? "composing" : "idle"
    this.fieldTarget.setAttribute("aria-invalid", String(state === "error"))
    this.feedbackTarget.querySelectorAll("[data-feedback]").forEach(part => {
      part.hidden = part.dataset.feedback !== state
      if (part.hidden) return
      if (state === "error") {
        // As typle-r: the icon and the text directly in one span.
        part.childNodes.forEach(node => { if (node.nodeType === 3) node.remove() })
        part.append(message(this.messagesValue.feedbackMismatch, { position: this.position + 1 }))
        return
      }
      const text = part.querySelector("[data-feedback-text]")
      if (text) text.textContent = composing
    })
  }

  // The next three words, how many more there are, and (shown) every word of the list with the current one marked.
  renderUpcoming() {
    if (!this.hasUpcomingTarget) return
    const m = this.messagesValue
    const words = this.wordsValue
    const index = this.finishedAt ? words.length - 1 : this.index
    if (index === this.upcomingIndex) return
    const from = this.upcomingIndex
    this.upcomingIndex = index
    const next = words.slice(index + 1, index + 4)
    const remaining = words.length - index - 1 - next.length
    const oneLine = word => word.display.replace(/\r\n|\r|\n/g, "  ")
    this.upcomingTarget.innerHTML = next.map(word =>
      `<span class="inline-flex h-7 max-w-full items-center rounded-full border px-3 text-[13px] text-base-content/60" title="${escapeHtml(word.display)}"><span class="truncate whitespace-pre">${escapeHtml(oneLine(word))}</span></span>`).join("")
      + (next.length ? "" : `<span class="text-xs text-base-content/60">${escapeHtml(this.upcomingTarget.dataset.last ?? "")}</span>`)
      + (remaining > 0 ? `<span class="text-xs text-base-content/40">${escapeHtml(message(m.upcomingMore, { count: remaining }))}</span>` : "")
    if (!this.hasAllWordsTarget) return
    const items = this.allWordsTarget.children
    // Moving on in the same words changes only the words from the last one to this one; anything else draws them all.
    if (!this.allWordsStale && from !== undefined && index > from && items.length === words.length) {
      for (let wordIndex = from; wordIndex <= index; wordIndex++) items[wordIndex].outerHTML = this.allWordsItem(words[wordIndex], wordIndex, index)
    } else {
      this.allWordsTarget.innerHTML = words.map((word, wordIndex) => this.allWordsItem(word, wordIndex, index)).join("")
      this.allWordsStale = false
    }
    const currentItem = this.allWordsTarget.querySelector('[aria-current="step"]')
    if (currentItem) this.allWordsTarget.scrollTop = currentItem.offsetTop - 48
  }

  // A word in the list of every word: typed (green), the current one or still to come.
  allWordsItem(word, wordIndex, index) {
    const m = this.messagesValue
    const done = wordIndex < index
    const current = wordIndex === index
    const paragraph = Array.from(word.display).length > 24 || word.display.includes("\n")
    const classes = ["min-h-7 max-w-full border px-3 text-[13px] text-base-content/60",
      paragraph ? "block rounded-lg py-2 text-left leading-relaxed whitespace-pre-wrap [overflow-wrap:anywhere]" : "inline-flex items-center rounded-full break-all whitespace-pre-wrap",
      done ? "border-transparent bg-success/15 text-success" : "",
      current ? "border-transparent bg-primary text-primary-content" : ""].join(" ")
    const state = done ? m.upcomingDone : current ? m.upcomingCurrent : m.upcomingPending
    return `<li class="max-w-full${paragraph ? " w-full" : ""}"><span class="${classes}"${current ? ' aria-current="step"' : ""}>${escapeHtml(word.display)}<span class="sr-only">${escapeHtml(state ?? "")}</span></span></li>`
  }

  // The words change on a review of missed words and back: the list of every word is drawn again.
  wordsValueChanged() { this.allWordsStale = true }
}

// PracticeText's sizes, by the length of the text (and smaller for the letters under a display that differs).
const TEXT_SIZES = ["text-xl", "leading-[1.75]", "sm:text-[26px]", "text-2xl", "leading-relaxed", "tracking-wide", "sm:text-3xl",
  "text-[32px]", "leading-tight", "sm:text-[44px]", "text-[44px]", "sm:text-[64px]"]

function sizeText(element, text, guide) {
  const length = Array.from(text).length
  const size = length > 24 || text.includes("\n") ? "text-xl leading-[1.75] sm:text-[26px]"
    : guide ? "text-2xl leading-relaxed tracking-wide sm:text-3xl"
    : length > 10 ? "text-[32px] leading-tight sm:text-[44px]" : "text-[44px] leading-tight sm:text-[64px]"
  element.classList.remove(...TEXT_SIZES)
  element.classList.add(...size.split(" "))
}
