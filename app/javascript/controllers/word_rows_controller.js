import { Controller } from "@hotwired/stimulus"
import { message } from "practice_run"
import { Turbo } from "@hotwired/turbo-rails"
import { confirmDialog } from "confirm_dialog"

// The word editor (typle-r's WordsSection, WordRowFields, SortableWordRow and WordListSaveBar): one row per word, added,
// removed and moved in place; Enter goes to the next word (adding one at the end), Alt+↑↓ moves a word, Ctrl(⌘)+Enter
// saves, a row is dragged by its grip, and a CSV file adds its words at the end.
const MAX_WORDS = 1000

export default class extends Controller {
  static targets = ["rows", "row", "template", "count", "notice", "moved", "total", "dirty", "dirtyDot", "clean",
    "importDialog", "importFile", "importEmpty", "importDrop", "importLoaded", "importName", "importSummary", "importPreview", "importMore",
    "importModes", "importMode", "importHint", "importStatus", "importError", "importErrorText", "importConfirm"]
  static values = { labels: Object }

  connect() {
    this.initial = this.snapshot()
    this.renumber()
  }

  get dirty() { return this.snapshot() !== this.initial }

  // typle-r's useUnsavedWarning and DiscardChangesDialog: leaving with unsaved changes asks first.
  submitting() { this.saving = true }

  unload(event) {
    if (this.dirty && !this.saving) event.preventDefault()
  }

  // typle-r's DiscardChangesDialog: leaving within the app asks in its dialog, then goes on when told to.
  leave(event) {
    if (!this.dirty || this.saving) return
    event.preventDefault()
    const l = this.labelsValue
    confirmDialog({ title: message(l.discard), description: message(l.discardDescription), cancel: message(l.keepEditing), action: message(l.discardAction) })
      .then(ok => { if (ok) { this.saving = true; Turbo.visit(event.detail.url) } })
  }

  // What a save would send: the words in their order and the list's own fields (name, pack, handwriting), as typle-r's
  // unsaved warning compares the whole draft.
  snapshot() {
    const rows = this.rowTargets.map(row => ["display", "input", "inputType", "annotation"].map(role => this.field(row, role).value))
    const form = this.element.closest("form") ?? this.element.querySelector("form")
    const fields = form ? [...new FormData(form)].filter(([name, value]) => name !== "authenticity_token" && !name.includes("[words_rows]") && typeof value === "string") : []
    return JSON.stringify([rows, fields])
  }

  field(row, role) { return row.querySelector(`[data-role="${role}"]`) }

  // Numbers, labels and which actions can be used, after any change to the rows.
  renumber() {
    const rows = this.rowTargets
    const l = this.labelsValue
    rows.forEach((row, index) => {
      const n = index + 1
      row.setAttribute("aria-label", message(l.row, { n }))
      this.field(row, "number").textContent = n
      this.field(row, "drag").setAttribute("aria-label", message(l.drag, { n }))
      this.field(row, "drag").disabled = rows.length < 2
      this.field(row, "display").setAttribute("aria-label", message(l.display, { n }))
      this.field(row, "input").setAttribute("aria-label", message(l.input, { n }))
      this.field(row, "inputType").setAttribute("aria-label", message(l.inputType, { n }))
      this.field(row, "annotation").setAttribute("aria-label", message(l.annotation, { n }))
      this.field(row, "actions").setAttribute("aria-label", message(l.actions, { n }))
      this.field(row, "remove").setAttribute("aria-label", message(l.delete, { n }))
      this.field(row, "remove").disabled = rows.length < 2
      this.field(row, "remove-menu").disabled = rows.length < 2
      this.field(row, "move-up").disabled = index === 0
      this.field(row, "move-first").disabled = index === 0
      this.field(row, "move-down").disabled = index === rows.length - 1
      this.field(row, "move-last").disabled = index === rows.length - 1
      // The text to type defaults to the word shown, which the empty field says.
      this.field(row, "input").placeholder = this.field(row, "display").value
    })
    if (this.hasCountTarget) this.countTarget.textContent = rows.length.toLocaleString()
    this.changed()
  }

  changed(event) {
    if (event?.target?.dataset.role === "display") this.field(event.target.closest("[data-word-rows-target=row]"), "input").placeholder = event.target.value
    const dirty = this.dirty
    if (this.hasDirtyTarget) {
      this.dirtyTarget.hidden = !dirty
      this.dirtyDotTarget.hidden = !dirty
      this.cleanTarget.hidden = dirty
    }
    if (this.hasTotalTarget) this.totalTarget.textContent = message(this.labelsValue.total, { count: this.rowTargets.length })
  }

  newRow(word = {}) {
    const row = this.templateTarget.content.firstElementChild.cloneNode(true)
    this.field(row, "display").value = word.display ?? ""
    this.field(row, "input").value = word.input && word.input !== word.display ? word.input : ""
    this.field(row, "annotation").value = word.annotation ?? ""
    if (word.input_type) this.field(row, "inputType").value = word.input_type
    return row
  }

  add() {
    if (this.rowTargets.length >= MAX_WORDS) return
    const row = this.newRow()
    this.rowsTarget.append(row)
    this.renumber()
    this.field(row, "display").focus()
  }

  rowOf(event) { return event.target.closest("[data-word-rows-target=row]") }

  remove(event) {
    if (this.rowTargets.length < 2) return
    const row = this.rowOf(event)
    const rows = this.rowTargets
    const next = rows[rows.indexOf(row) + 1] ?? rows[rows.indexOf(row) - 1]
    row.remove()
    this.renumber()
    this.field(next, "display").focus()
  }

  move(event) {
    const row = this.rowOf(event)
    row.querySelector("[data-controller~=dropdown][open] > [data-dropdown-target=trigger]")?.click()
    this.moveTo(row, event.params.where)
  }

  moveTo(row, where) {
    const rows = this.rowTargets
    const index = rows.indexOf(row)
    const target = { up: index - 1, down: index + 1, first: 0, last: rows.length - 1 }[where]
    if (target < 0 || target >= rows.length || target === index) return
    if (target < index) rows[target].before(row)
    else rows[target].after(row)
    this.renumber()
    this.announceMove(row)
  }

  // The moved word's new place, read out (the row's own label: 単語 N).
  announceMove(row) {
    if (this.hasMovedTarget && row) this.movedTarget.textContent = row.getAttribute("aria-label") ?? ""
  }

  keydown(event) {
    if (event.isComposing) return
    const row = this.rowOf(event)
    if (event.altKey && (event.key === "ArrowUp" || event.key === "ArrowDown")) {
      event.preventDefault()
      this.moveTo(row, event.key === "ArrowUp" ? "up" : "down")
      event.target.focus()
    } else if (event.key === "Enter" && !event.metaKey && !event.ctrlKey) {
      // Enter: the same field of the next word, or a new word after the last one.
      event.preventDefault()
      const rows = this.rowTargets
      const next = rows[rows.indexOf(row) + 1]
      if (next) this.field(next, event.target.dataset.role).focus()
      else this.add()
    }
  }

  saveShortcut(event) {
    if (event.key === "Enter" && (event.metaKey || event.ctrlKey)) {
      event.preventDefault()
      this.element.requestSubmit()
    }
  }

  // Dragging a row by its grip moves it before or after the row it is dropped on.
  dragStart(event) {
    this.dragged = this.rowOf(event)
    event.dataTransfer.effectAllowed = "move"
    this.dragged.classList.add("bg-base-200", "shadow-md")
    this.over = event => {
      const row = event.target.closest?.("[data-word-rows-target=row]")
      if (!row || !this.dragged) return
      event.preventDefault()
      if (row === this.dragged) return
      const box = row.getBoundingClientRect()
      if (event.clientY < box.top + box.height / 2) row.before(this.dragged)
      else row.after(this.dragged)
    }
    this.rowsTarget.addEventListener("dragover", this.over)
  }

  dragEnd() {
    const moved = this.dragged
    this.dragged?.classList.remove("bg-base-200", "shadow-md")
    this.dragged = null
    this.rowsTarget.removeEventListener("dragover", this.over)
    this.renumber()
    this.announceMove(moved)
  }

  // typle-r's WordListImport: a dialog to choose or drop a CSV file (a header naming input, display, annotation and
  // input_type in any order), see its first words, then add them after the words there or put them in their place.
  openImport() {
    this.resetImport()
    this.importDialogTarget.showModal()
  }

  closeImport() { this.importDialogTarget.close() }

  pickImport() { this.importFileTarget.click() }

  resetImport() {
    this.parsed = null
    this.importEmptyTarget.hidden = false
    this.importLoadedTarget.hidden = true
    this.importConfirmTarget.hidden = true
    this.importErrorTarget.hidden = true
    this.importStatusTarget.textContent = ""
    this.importModeTargets.forEach(radio => { radio.checked = radio.value === "append" })
    this.importDropTarget.dataset.dragging = "false"
  }

  chooseImport(event) {
    const file = event.target.files?.[0]
    event.target.value = ""
    this.loadImport(file)
  }

  dragOverImport(event) { event.preventDefault(); this.importDropTarget.dataset.dragging = "true" }
  dragLeaveImport() { this.importDropTarget.dataset.dragging = "false" }
  dropImport(event) {
    event.preventDefault()
    this.importDropTarget.dataset.dragging = "false"
    this.loadImport(event.dataTransfer.files[0])
  }

  async loadImport(file) {
    if (!file) return
    const l = this.labelsValue
    this.importErrorTarget.hidden = true
    this.importStatusTarget.textContent = message(l.importLoading)
    try {
      if (!/\.csv$/i.test(file.name)) throw new Error(message(l.errorFileType))
      if (file.size > 1024 * 1024) throw new Error(message(l.errorTooLarge))
      let text
      try { text = new TextDecoder("utf-8", { fatal: true }).decode(await file.arrayBuffer()) } catch { throw new Error(message(l.errorEncoding)) }
      this.parsed = { name: file.name, size: file.size, words: parseWords(text.replace(/^\uFEFF/, "")) }
    } catch (error) {
      this.parsed = null
      this.importStatusTarget.textContent = ""
      this.importErrorTextTarget.textContent = error.message && error.message !== "header" ? error.message : message(l.readFailed)
      this.importErrorTarget.hidden = false
      return
    }
    this.showImport()
  }

  get filledRows() { return this.rowTargets.filter(row => this.field(row, "display").value.trim() || this.field(row, "input").value.trim() || this.field(row, "annotation").value.trim()) }

  showImport() {
    const l = this.labelsValue
    const { name, size, words } = this.parsed
    const count = words.length
    const existing = this.filledRows.length
    this.importEmptyTarget.hidden = true
    this.importLoadedTarget.hidden = false
    this.importNameTarget.textContent = name
    const sizeText = size < 1024 ? message(l.importBytes, { value: size }) : message(l.importKilobytes, { value: Math.ceil(size / 1024) })
    this.importSummaryTarget.textContent = message(l.importSummary, { count, size: sizeText })
    const cell = (text, extra = "") => `<td class="truncate px-3 py-2${extra}">${escapeHtml(text)}</td>`
    this.importPreviewTarget.innerHTML = words.slice(0, 3).map(word =>
      `<tr class="border-t">${cell(word.display)}${cell(word.input)}${cell(word.annotation || "—", " text-base-content/60")}</tr>`).join("")
    this.importMoreTarget.hidden = count <= 3
    this.importMoreTarget.textContent = count > 3 ? message(l.importMore, { count: count - 3 }) : ""
    this.importModesTarget.hidden = existing === 0
    this.importHintTargets.forEach(hint => {
      hint.textContent = hint.dataset.mode === "append" ? message(l.importAppendHint, { existing, count }) : message(l.importReplaceHint, { existing })
    })
    this.importStatusTarget.textContent = message(l.importLoaded, { count })
    this.importConfirmTarget.hidden = false
    this.importModeChanged()
  }

  importModeChanged() {
    if (!this.parsed) return
    const l = this.labelsValue
    const count = this.parsed.words.length
    const replace = this.filledRows.length > 0 && this.importModeTargets.find(radio => radio.checked)?.value === "replace"
    this.importConfirmTarget.textContent = message(replace ? l.importReplaceWith : l.importAdd, { count })
  }

  confirmImport() {
    if (!this.parsed) return
    const replace = this.filledRows.length > 0 && this.importModeTargets.find(radio => radio.checked)?.value === "replace"
    const { words } = this.parsed
    // Rows left empty are dropped first; replacing removes every word there.
    this.rowTargets.filter(row => replace || !this.filledRows.includes(row)).forEach(row => row.remove())
    for (const word of words.slice(0, MAX_WORDS - this.rowTargets.length)) this.rowsTarget.append(this.newRow(word))
    if (!this.rowTargets.length) this.rowsTarget.append(this.newRow())
    this.renumber()
    this.closeImport()
  }
}

// The words of a CSV file with typle-r's header: input and display required, annotation and input_type optional.
function parseWords(text) {
  const rows = parseCsv(text)
  const header = (rows.shift() ?? []).map(name => name.trim().toLowerCase().replace(/^anotation$/, "annotation"))
  const at = name => header.indexOf(name)
  if (at("input") < 0 || at("display") < 0) throw new Error("header")
  return rows.filter(cells => cells.some(cell => cell.trim())).map(cells => ({
    input: cells[at("input")] ?? "", display: cells[at("display")] ?? "", annotation: at("annotation") >= 0 ? cells[at("annotation")] ?? "" : "",
    input_type: at("input_type") >= 0 ? cells[at("input_type")] : undefined,
  }))
}

const escapeHtml = text => String(text).replace(/[&<>"']/g, char => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[char]))

// RFC 4180 CSV: quoted fields with commas, line breaks and doubled quotes.
function parseCsv(text) {
  const rows = []
  let row = [], field = "", quoted = false
  for (let i = 0; i < text.length; i++) {
    const char = text[i]
    if (quoted) {
      if (char === '"' && text[i + 1] === '"') { field += '"'; i++ }
      else if (char === '"') quoted = false
      else field += char
    } else if (char === '"') quoted = true
    else if (char === ",") { row.push(field); field = "" }
    else if (char === "\n" || char === "\r") {
      if (char === "\r" && text[i + 1] === "\n") i++
      row.push(field); rows.push(row); row = []; field = ""
    } else field += char
  }
  if (field || row.length) { row.push(field); rows.push(row) }
  return rows
}
