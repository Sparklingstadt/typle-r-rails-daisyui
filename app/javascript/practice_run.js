// What both practice screens (typing and handwriting) do when a run is over, as typle-r's PracticeResult: save it,
// and show the result in place (the tiles, how it compares with the best, the missed words and what to do next).

import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"
import { accuracyOf } from "typing"
import { confirmDialog } from "confirm_dialog"

const MAX_MISSED = 20

// Adds to the entry of the word at `index`, making it on its first mistake. The first wrong key stays as it was
// (typle-r's noteMistake): { count, position, typed, revealed, skipped }.
export function noteMistake(mistakes, index, change) {
  const entry = mistakes.get(index) ?? { count: 0 }
  if (change.wrong) {
    entry.count += 1
    if (entry.typed === undefined) {
      entry.typed = change.wrong.typed
      if (change.wrong.position !== undefined) entry.position = change.wrong.position
    }
  }
  if (change.revealed) entry.revealed = true
  if (change.skipped) entry.skipped = true
  mistakes.set(index, entry)
}

// The missed words a record keeps: the word to type and its count (at least 1), most first, at most 20.
export function missedWords(mistakes, words) {
  return [...mistakes]
    .filter(([index]) => words[index])
    .map(([index, entry]) => ({ word: words[index].input, count: Math.max(1, entry.count ?? entry) }))
    .sort((a, b) => b.count - a.count)
    .slice(0, MAX_MISSED)
}

export function post(url, body) {
  const token = document.querySelector('meta[name="csrf-token"]')?.content
  return fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json", "Accept": "application/json", "X-CSRF-Token": token },
    body: JSON.stringify(body),
  })
}

// Fills a message: %{name} from `values`; plural messages come as their forms ({one:, other:}) and are chosen by count.
export function message(text, values = {}) {
  if (text && typeof text === "object") {
    const rule = new Intl.PluralRules(document.documentElement.lang || "en").select(values.count ?? 0)
    text = text[rule] ?? text.other
  }
  return String(text ?? "").replace(/%\{(\w+)\}/g, (match, name) => name in values ? String(values[name]) : match)
}

// Correct keys (words when handwriting) per minute; none in the first second.
export function speedOf(correct, ms) {
  return ms < 1000 ? null : Math.round(correct / (ms / 60000))
}

// m:ss.s, as typle-r's live stats show the elapsed time.
export function formatClock(ms) {
  const seconds = Math.max(0, ms) / 1000
  return `${Math.floor(seconds / 60)}:${(seconds % 60).toFixed(1).padStart(4, "0")}`
}

export function escapeHtml(text) {
  return String(text).replace(/[&<>"']/g, char => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[char])
}

// --- a review of the words just missed (not recorded) ---

export function startReview(controller) {
  const words = controller.wordsValue
  const missed = [...controller.wordMistakes.keys()].filter(index => words[index]).map(index => words[index])
  if (!missed.length) return
  controller.fullWords ??= words
  controller.reviewing = true
  controller.wordsValue = missed
  showReviewStatus(controller, missed.length)
}

export function endReview(controller) {
  if (!controller.reviewing) return
  controller.reviewing = false
  controller.wordsValue = controller.fullWords
  controller.fullWords = null
  showReviewStatus(controller, 0)
}

function showReviewStatus(controller, count) {
  const status = controller.element.querySelector("[data-review-status]")
  if (!status) return
  status.hidden = count === 0
  status.textContent = count ? message(controller.messagesValue.result.reviewing, { count }) : ""
}

// 別のリストを選ぶ: the list panel's search when it is shown, otherwise the list picker (ListPickerDialog).
export function chooseList(controller) {
  const search = document.querySelector("#practice-aside input[type=search]")
  if (search && search.offsetParent !== null) return search.focus()
  controller.element.querySelector("[data-controller~=list-picker] [data-list-picker-target=trigger]")?.click()
}

// --- the run, as both screens keep it ---

// The base of the two practice controllers (typing and handwriting): a run's counts and clock, starting again, the
// review of missed words, the live stats and the end of a run. Each adds its own input and drawing (render, and its
// own part of reset), and the targets these use: field, board, result, time, mistakes, accuracy and, on the play
// screen, speed.
export class RunController extends Controller {
  // What a new run starts from.
  resetRun() {
    this.currentRun = null
    this.index = 0
    this.attempts = 0
    this.mistakes = 0
    this.startedAt = null
    this.finishedAt = null
    this.pausedAt = null
    this.wordMistakes = new Map()
    this.composing = false
    if (this.hasResultTarget) this.resultTarget.hidden = true
    this.boardTarget.hidden = false
    this.fieldTarget.disabled = false
  }

  // もう一度: the whole list again (a review of missed words goes back to the list).
  restart() {
    endReview(this)
    this.reset()
  }

  // 間違えた N 語だけ練習する: only the words missed in the run just finished, the same way. Not recorded.
  reviewMissed() {
    startReview(this)
    this.reset()
  }

  chooseList() { chooseList(this) }

  missedWords() { return missedWords(this.wordMistakes, this.wordsValue) }

  // The clock stands still while the input has no focus.
  pauseClock() {
    if (this.startedAt !== null && !this.finishedAt && this.pausedAt === null) this.pausedAt = performance.now()
  }

  resumeClock(now = performance.now()) {
    if (this.pausedAt === null) return
    this.startedAt += now - this.pausedAt
    this.pausedAt = null
  }

  elapsed() {
    if (this.startedAt === null) return 0
    return Math.max(0, (this.finishedAt ?? this.pausedAt ?? performance.now()) - this.startedAt)
  }

  // The time (m:ss.s with the speed beside it on the play screen, seconds elsewhere), mistakes and accuracy.
  renderStats() {
    const elapsed = this.elapsed()
    this.timeTarget.textContent = this.hasSpeedTarget ? formatClock(elapsed) : `${(elapsed / 1000).toFixed(1)}${this.messagesValue.seconds ?? "s"}`
    if (this.hasSpeedTarget) {
      const speed = this.startedAt === null ? null : speedOf(this.attempts - this.mistakes, elapsed)
      this.speedTarget.textContent = speed === null ? "—" : String(speed)
    }
    this.mistakesTarget.textContent = String(this.mistakes)
    this.accuracyTarget.textContent = this.attempts || !this.hasSpeedTarget ? `${Math.round(accuracyOf(this.attempts, this.mistakes) * 10) / 10}%` : "—"
  }

  // The last word is done: the clock stops, and the run is saved and shown (finishRun).
  finish(now = performance.now()) {
    this.finishedAt = now
    this.fieldTarget.disabled = true
    this.render()
    finishRun(this, {
      time_ms: Math.max(1, Math.round(this.elapsed())),
      mistakes: this.mistakes,
      accuracy: accuracyOf(this.attempts, this.mistakes),
      mode: this.modeValue || null,
      missed: this.missedWords(),
    })
  }
}

// --- finishing a run ---

// Saves the run (a list of one's own), keeps a weak review on its list, or only shows it (an official list not
// followed, a review of missed words), then draws the result in place.
export async function finishRun(controller, run) {
  // The run keeps its own counts: starting again (Enter on the result) must not change the result drawn after saving.
  Object.defineProperty(run, "counts", { value: { attempts: controller.attempts, mistakes: controller.mistakes, wordMistakes: new Map(controller.wordMistakes) } })
  controller.currentRun = run
  const review = controller.reviewing
  if (review) return renderResult(controller, run, { review: true })
  if (controller.weakUrlValue) {
    renderResult(controller, run, { review: true, weak: true })
    await post(controller.weakUrlValue, { missed: run.missed })
    return
  }
  if (!controller.saveUrlValue) return renderResult(controller, run, { unsaved: true })
  // As typle-r, the run is compared with the list's runs at once; the saved answer replaces it.
  const local = localComparison(controller, run)
  renderResult(controller, run, { saving: true, comparison: local })
  const save = async () => {
    try {
      const response = await post(controller.saveUrlValue, { ...run, word_list_id: controller.listIdValue })
      if (!response.ok) throw new Error(`HTTP ${response.status}`)
      const saved = await response.json()
      if (controller.hasRecordsValue) controller.recordsValue = [...controller.recordsValue, [run.time_ms / 1000, run.accuracy, controller.wordsValue.length]]
      // Started again meanwhile: the new run stays on screen; only the best records take the saved one.
      if (controller.currentRun === run) renderResult(controller, run, { saved: true, comparison: saved.comparison })
      refreshPage(saved.id)
    } catch (error) {
      console.error(error)
      if (controller.currentRun !== run) return
      renderResult(controller, run, { failed: true, retry: save, comparison: local })
    }
  }
  await save()
}

// Fetches the page again, with the new run marked, and puts its best records and list panel in place.
async function refreshPage(id) {
  const url = new URL(location.href)
  url.searchParams.set("highlight", id)
  const html = await fetch(url, { headers: { Accept: "text/html" } }).then(response => response.text())
  const page = new DOMParser().parseFromString(html, "text/html")
  for (const selector of ["#best-records", "#practice-aside"]) {
    const fresh = page.querySelector(selector)
    const current = document.querySelector(selector)
    if (fresh && current) current.replaceWith(fresh)
  }
}

// What a missed word's meaning is: the annotation without the word itself ("apple / りんご" → "りんご").
function wordMeaning(display, annotation) {
  const note = (annotation ?? "").trim()
  const rest = display && note.startsWith(display) ? note.slice(display.length) : ""
  return /^\s*\//.test(rest) ? rest.replace(/^\s*\/\s*/, "").trim() : note
}

// Icons the result partial renders as <template data-icon-template="name">, so they are lucide's own.
function iconHtml(controller, name) {
  return controller.resultTarget.querySelector(`template[data-icon-template="${name}"]`)?.innerHTML.trim() ?? ""
}

// PracticeRecord#comparison, in the page: the run among the list's runs of its mode at its word count, ranked by
// accuracy then time; a run the same as one before it comes after it.
function localComparison(controller, run) {
  if (!controller.hasRecordsValue) return null
  const count = controller.wordsValue.length
  const same = controller.recordsValue.filter(([, , words]) => words === count).map(([time, accuracy]) => ({ time, accuracy }))
  const mine = { time: run.time_ms / 1000, accuracy: Math.round(run.accuracy * 100) / 100, mine: true }
  const ranked = [...same, mine].sort((a, b) => b.accuracy - a.accuracy || a.time - b.time || (a.mine ? 1 : 0) - (b.mine ? 1 : 0))
  const rank = ranked.indexOf(mine) + 1
  if (!same.length) return { rank, kind: controller.recordsValue.length ? "firstAtCount" : "firstForList" }
  if (rank === 1) return { rank, kind: "best", difference: Math.round((mine.time - ranked[1].time) * 100) / 100 }
  return { rank, kind: "behind", previous: { time: Math.round(ranked[0].time * 100) / 100, accuracy: ranked[0].accuracy } }
}

function saveFailedHtml(controller, r) {
  const box = controller.resultTarget.querySelector("[data-save-failed-template]").content.firstElementChild.cloneNode(true)
  box.querySelector("[data-save-failed-text]").textContent = r.saveFailed
  box.querySelector("[data-retry]").textContent = r.retry
  return box.outerHTML
}

// typle-r's PracticeResult. `outcome`: { saving } | { saved, comparison } | { failed, retry } | { review, weak } | { unsaved }.
export function renderResult(controller, run, outcome) {
  const m = controller.messagesValue
  const r = m.result
  const writing = run.mode === "writing"
  const words = controller.wordsValue
  const counts = run.counts ?? controller
  const mistakes = counts.wordMistakes
  controller.boardTarget.hidden = true
  controller.resultTarget.hidden = false
  const correct = counts.attempts - counts.mistakes
  const speed = speedOf(correct, run.time_ms)
  const time = run.time_ms / 1000
  const accuracy = Math.round(run.accuracy * 10) / 10
  const compared = outcome.comparison
  const best = compared?.kind === "best"
  const faster = best && compared.difference < 0
  const note = !compared ? ""
    : compared.kind === "behind" ? message(r.behind, { time: compared.previous.time.toFixed(2), accuracy: Math.round(compared.previous.accuracy * 10) / 10 })
    : compared.kind === "best" ? (compared.difference < 0 ? message(r.faster, { seconds: (-compared.difference).toFixed(2) }) : r.bestByAccuracy)
    : compared.kind === "firstAtCount" ? message(r.firstAtCount, { count: words.length }) : r.firstForList
  const missedCount = [...mistakes.keys()].filter(index => words[index]).length
  const deviceName = controller.element.querySelector("[data-device-label]")?.textContent?.trim() ?? ""
  const tiles = [
    { term: r.time, value: time.toFixed(2), unit: r.seconds, note, good: best, icon: faster ? iconHtml(controller, "trending-down") : "" },
    { term: r.accuracy, value: String(accuracy), unit: "%", note: message(writing ? r.mistakesWords : r.mistakes, { count: run.mistakes }) },
    { term: r.speed, value: speed === null ? "—" : String(speed), unit: writing ? r.wordSpeedUnit : r.speedUnit, note: message(writing ? r.correctWords : r.correct, { count: correct }) },
    { term: r.missed.tile, value: String(missedCount), unit: message(r.missed.of, { count: words.length }), note: deviceName, icon: iconHtml(controller, "keyboard") },
  ]
  const badges = controller.resultTarget.querySelector("[data-result-badges]")
  badges.querySelector("[data-new-best]")?.remove()
  if (best) badges.insertAdjacentHTML("beforeend", `<span data-new-best class="inline-flex h-7 items-center gap-1.5 rounded-full bg-warning/15 px-2.5 text-[13px] font-bold text-warning">${iconHtml(controller, "trophy")}${escapeHtml(r.newBest)}</span>`)

  const status = outcome.review ? `<p role="status" class="text-[13px] text-base-content/60">${escapeHtml(outcome.weak ? r.reviewNoteWeak : r.reviewNote)}</p>`
    : outcome.unsaved ? `<p role="status" class="text-[13px] text-base-content/60">${escapeHtml(m.notSaved)}</p>`
    : outcome.failed ? saveFailedHtml(controller, r)
    : `<p role="status" class="${outcome.saved ? "flex items-center gap-2 text-[13px] text-success" : "flex items-center gap-2 text-[13px] text-base-content/60"}">${outcome.saved ? iconHtml(controller, "circle-check") + escapeHtml(message(r.saved, { rank: compared.rank })) : escapeHtml(r.saving)}</p>`
  controller.resultBodyTarget.innerHTML = `
    <dl class="grid grid-cols-2 gap-2 sm:gap-3 md:grid-cols-4">
      ${tiles.map(tile => `<div class="grid min-w-0 content-start gap-0.5 rounded-xl border px-3 py-3 sm:px-4 sm:py-3.5">
        <dt class="text-xs text-base-content/60">${escapeHtml(tile.term)}</dt>
        <dd class="text-2xl font-medium tabular-nums sm:text-[28px]">${escapeHtml(tile.value)}<span class="ml-0.5 text-sm font-normal text-base-content/60">${escapeHtml(tile.unit)}</span></dd>
        <dd class="flex min-w-0 items-center gap-1 text-xs text-base-content/60 [overflow-wrap:anywhere]${tile.good ? " font-medium text-success" : ""}">${tile.icon ?? ""}<span class="min-w-0">${escapeHtml(tile.note)}</span></dd>
      </div>`).join("")}
    </dl>
    ${status}`
  controller.resultBodyTarget.querySelector("[data-retry]")?.addEventListener("click", () => outcome.retry())

  // The buttons: 間違えた N 語だけ練習する only when there are some; X でシェア only for a run that counts.
  const review = controller.resultTarget.querySelector("[data-review-missed]")
  if (review) {
    review.hidden = missedCount === 0
    review.childNodes.forEach(node => { if (node.nodeType === 3) node.remove() })
    review.append(message(r.missed.review, { count: missedCount }))
  }
  const share = controller.resultTarget.querySelector("[data-share]")
  if (share) {
    share.hidden = !!outcome.review
    const name = share.dataset.name.replace(/\s+/g, " ").trim()
    const query = new URLSearchParams({ n: name, t: time.toFixed(2), a: String(Math.round(run.accuracy)), w: String(words.length) })
    if (speed !== null) query.set("s", String(speed))
    if (run.mode) query.set("m", run.mode)
    const text = `${message(r.shareText, { name, time: time.toFixed(2), accuracy })} #Typle`
    share.href = `https://x.com/intent/post?${new URLSearchParams({ text, url: `${location.origin}/result?${query}` })}`
  }

  // MissedWords: the word (the wrong letter underlined), its meaning, how it first went wrong and how many times.
  const rows = [...mistakes].filter(([index]) => words[index]).map(([index, entry]) => {
    const word = words[index]
    const characters = Array.from(word.input)
    const marked = !writing && entry.position !== undefined && entry.position < characters.length
      ? `${escapeHtml(characters.slice(0, entry.position).join(""))}<mark class="rounded-[2px] bg-transparent text-error underline decoration-[3px] underline-offset-4">${escapeHtml(characters[entry.position])}</mark>${escapeHtml(characters.slice(entry.position + 1).join(""))}`
      : escapeHtml(word.input)
    const how = entry.skipped ? r.missed.skipped : entry.revealed ? r.missed.revealed : entry.typed === undefined ? ""
      : writing ? message(r.missed.wrote, { typed: entry.typed })
      : message(r.missed.typed, { position: (entry.position ?? 0) + 1, typed: /^\s$/u.test(entry.typed) ? r.missed.space : entry.typed })
    const display = word.display !== word.input ? `<span class="mr-2 font-sans">${escapeHtml(word.display)}</span>` : ""
    return `<li class="grid grid-cols-[minmax(0,1fr)_auto] items-baseline gap-x-4 gap-y-1 py-3 sm:grid-cols-[minmax(0,14rem)_minmax(0,1fr)_auto_3.5rem]">
      <p lang="und" class="min-w-0 font-mono text-lg break-words">${display}${writing ? (word.display === word.input ? escapeHtml(word.input) : "") : marked}</p>
      <p class="min-w-0 text-sm break-words text-base-content/60 max-sm:col-span-2 max-sm:row-start-2">${escapeHtml(word.annotation ? wordMeaning(word.display, word.annotation) : "")}</p>
      <p class="text-[13px] text-base-content/60 max-sm:col-start-1 max-sm:row-start-3">${escapeHtml(how)}</p>
      <p class="text-right text-sm font-bold text-error tabular-nums max-sm:col-start-2 max-sm:row-start-1">${entry.count > 0 ? escapeHtml(message(r.missed.count, { count: entry.count })) : ""}</p>
    </li>`
  }).join("")
  controller.resultMissedTarget.innerHTML = rows
    ? `<section aria-labelledby="result-missed-heading" class="flex flex-col"><h3 id="result-missed-heading" class="mb-2 text-base font-bold">${escapeHtml(r.missed.title)}</h3><ul class="divide-y border-y">${rows}</ul></section>`
    : `<p class="text-sm text-base-content/60">${escapeHtml(r.missed.none)}</p>`
  if (!outcome.saved && !outcome.failed) controller.resultTarget.querySelector("[data-autofocus]")?.focus({ preventScroll: true })
}

// Kept for callers that show a run that is not saved.
export function showResult(controller, run) { renderResult(controller, run, { unsaved: true }) }

// A control locked while a run is on (typle-r disables them); a menu's trigger also closes its menu.
export function lockControl(control, locked) {
  if (locked && !control.disabled && control.closest("[data-controller~=dropdown][open]")) control.click()
  control.disabled = locked
}

// typle-r's usePracticeSwitch: while a run is on, choosing another list or the other way of practising asks first
// (SwitchConfirmDialog), and choosing the list in use changes nothing. A control marked data-practice-switch carries the
// target's name (data-switch-name); "current" marks the list in use, "noop" the way of practising in use.
export function guardSwitches(controller) {
  const onClick = async event => {
    const target = event.target instanceof Element && event.target.closest("[data-practice-switch]")
    if (!target || event.button > 0 || event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return
    const kind = target.dataset.practiceSwitch
    const running = controller.startedAt !== null && !controller.finishedAt
    if (kind === "noop") { event.preventDefault(); event.stopImmediatePropagation(); return }
    if (!running) return
    event.preventDefault()
    event.stopImmediatePropagation()
    target.closest("dialog[open]")?.close()
    if (kind === "current") return
    const texts = controller.messagesValue.switch ?? {}
    const confirmed = await confirmDialog({
      title: texts.title, action: texts.confirm, cancel: texts.continue, variant: "primary",
      description: message(texts.description, { list: controller.messagesValue.listName ?? "", done: controller.index, total: controller.wordsValue.length, next: target.dataset.switchName ?? "" }),
    })
    if (confirmed) Turbo.visit(target.getAttribute("href") || target.dataset.url)
    else if (!controller.usePad && controller.hasFieldTarget) controller.fieldTarget.focus()
  }
  document.addEventListener("click", onClick, true)
  return () => document.removeEventListener("click", onClick, true)
}
