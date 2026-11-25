import { Controller } from "@hotwired/stimulus"
import { message } from "practice_run"

// The landing page's hero (typle-r's TryWord): a word of an official pack typed right there. A finished word gives way
// to the next; the button goes on to the same pack. Nothing typed here is recorded.
const caret = "relative after:absolute after:inset-x-0 after:-bottom-[0.08em] after:h-[max(3px,0.06em)] after:rounded-full motion-safe:after:animate-pulse"
const stateClass = {
  done: "text-success",
  current: `${caret} text-base-content after:bg-primary`,
  error: "rounded-sm bg-error/10 text-error",
  "current-error": `${caret} text-error after:bg-error`,
  pending: "text-base-content",
}

export default class extends Controller {
  static targets = ["progress", "bar", "letters", "meaning", "field", "note", "button"]
  static values = { words: Array, total: Number, name: String, progress: String, hint: String, done: Object }

  connect() {
    this.index = 0
    this.done = 0
    this.render()
  }

  get word() { return this.wordsValue[this.index % this.wordsValue.length] }

  input() {
    if (this.fieldTarget.value === this.word.input) {
      this.index += 1
      this.done += 1
      this.fieldTarget.value = ""
    }
    this.render()
  }

  // typle-r's compareInput: from the first mismatch on everything is an error, and keys past the end are extra.
  compare(target, typed) {
    const characters = Array.from(target)
    const actual = Array.from(typed)
    let errorIndex = actual.findIndex((char, index) => index < characters.length && char !== characters[index])
    if (errorIndex === -1 && actual.length > characters.length) errorIndex = characters.length
    const states = characters.map((_, index) => {
      if (index < actual.length) return errorIndex === -1 || index < errorIndex ? "done" : "error"
      if (index === actual.length) return errorIndex === -1 ? "current" : "current-error"
      return "pending"
    })
    return { characters, states, extra: actual.slice(characters.length), errorIndex }
  }

  render() {
    const { characters, states, extra, errorIndex } = this.compare(this.word.input, this.fieldTarget.value)
    this.lettersTarget.replaceChildren(
      ...characters.map((char, index) => Object.assign(document.createElement("span"), { textContent: char, className: stateClass[states[index]] })),
      ...extra.map(char => Object.assign(document.createElement("span"), { textContent: char, className: "rounded-sm bg-error/10 text-error line-through" })))
    this.fieldTarget.setAttribute("aria-invalid", String(errorIndex >= 0))
    this.meaningTarget.textContent = this.word.meaning
    const current = (this.index % this.wordsValue.length) + 1
    this.progressTarget.textContent = message(this.progressValue, { name: this.nameValue, current, total: this.totalValue })
    this.barTarget.style.width = `${current / this.totalValue * 100}%`
    this.noteTarget.textContent = this.done > 0 ? message(this.doneValue, { count: this.done }) : this.hintValue
    // The button becomes the main one once a word is typed.
    const primary = this.done > 0
    this.buttonTarget.classList.toggle("bg-primary", primary)
    this.buttonTarget.classList.toggle("text-primary-content", primary)
    this.buttonTarget.classList.toggle("hover:bg-primary/90", primary)
    for (const name of ["border-base-300", "bg-base-100", "hover:bg-base-200", "hover:text-base-content", "", "", ""]) this.buttonTarget.classList.toggle(name, !primary)
  }
}
