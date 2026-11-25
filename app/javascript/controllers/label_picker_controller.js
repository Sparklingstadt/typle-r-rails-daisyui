import { Controller } from "@hotwired/stimulus"

// typle-r's LabelFields / LabelPicker: a button that opens a searchable list of the labels in use. Typing a name that is
// not there offers to create it, which also chooses it. "single" keeps one category; "multi" keeps tags as chips, where a
// comma (or 、 and ，) ends a tag and choosing a chosen tag again takes it off.
const separators = /[,、，]/
const same = (a, b) => a.trim().toLocaleLowerCase() === b.trim().toLocaleLowerCase()
const escapeHtml = text => String(text).replace(/[&<>"']/g, char => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[char]))
const ICONS = {
  check: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-check ml-auto size-4" aria-hidden="true"><path d="M20 6 9 17l-5-5"/></svg>',
  plus: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-plus size-4" aria-hidden="true"><path d="M5 12h14"/><path d="M12 5v14"/></svg>',
  x: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-x size-4" aria-hidden="true"><path d="M18 6 6 18"/><path d="m6 6 12 12"/></svg>',
  xSmall: '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-x size-3.5" aria-hidden="true"><path d="M18 6 6 18"/><path d="m6 6 12 12"/></svg>',
}
const ITEM = "relative flex w-full cursor-pointer items-center gap-2 rounded-sm px-2 py-1.5 text-left text-sm outline-none select-none hover:bg-base-200 data-[active=true]:bg-base-200 disabled:pointer-events-none disabled:opacity-50"

export default class extends Controller {
  static targets = ["trigger", "triggerText", "panel", "query", "options", "chips", "inputs"]
  static values = { mode: String, labels: Object, suggestions: Array, chosen: Array, name: String, max: Number, maxLength: Number }

  connect() {
    this.chosen = [...this.chosenValue]
    this.outside = event => { if (!this.element.contains(event.target)) this.close() }
    document.addEventListener("click", this.outside)
    this.sync()
  }

  disconnect() { document.removeEventListener("click", this.outside) }

  get multi() { return this.modeValue === "multi" }
  get full() { return this.multi && this.chosen.length >= this.maxValue }

  toggle() { this.panelTarget.hidden ? this.open() : this.close() }

  open() {
    this.panelTarget.hidden = false
    this.triggerTarget.setAttribute("aria-expanded", "true")
    this.queryTarget.value = ""
    this.render()
    this.queryTarget.focus()
  }

  close(focus = false) {
    if (this.panelTarget.hidden) return
    this.panelTarget.hidden = true
    this.triggerTarget.setAttribute("aria-expanded", "false")
    if (focus) this.triggerTarget.focus()
  }

  // Enter picks the first item; Esc closes; the keys stay in the picker, as the editor's form would take Enter.
  keydown(event) {
    if (event.key === "Escape") { event.preventDefault(); event.stopPropagation(); this.close(true) }
    else if (event.key === "Enter") {
      event.preventDefault(); event.stopPropagation()
      this.optionsTarget.querySelector("button:not(:disabled)")?.click()
    } else if (event.key === "ArrowDown" || event.key === "ArrowUp") {
      event.preventDefault()
      const buttons = [...this.optionsTarget.querySelectorAll("button:not(:disabled)")]
      if (buttons.length) buttons[event.key === "ArrowDown" ? 0 : buttons.length - 1].focus()
    }
  }

  itemKey(event) {
    const buttons = [...this.optionsTarget.querySelectorAll("button:not(:disabled)")]
    const index = buttons.indexOf(event.currentTarget)
    if (event.key === "ArrowDown") { event.preventDefault(); (buttons[index + 1] ?? this.queryTarget).focus() }
    else if (event.key === "ArrowUp") { event.preventDefault(); (buttons[index - 1] ?? this.queryTarget).focus() }
    else if (event.key === "Escape") { event.preventDefault(); this.close(true) }
  }

  render() {
    const l = this.labelsValue
    const query = this.queryTarget.value
    const matches = name => name.toLocaleLowerCase().includes(query.trim().toLocaleLowerCase())
    const groups = []
    const item = (attrs, inner, disabled = false) => `<button type="button" role="option" class="${ITEM}" ${attrs}${disabled ? " disabled" : ""} data-action="label-picker#pick keydown->label-picker#itemKey">${inner}</button>`
    if (this.multi) {
      const names = [...this.chosen.filter(tag => !this.suggestionsValue.some(name => same(name, tag))), ...this.suggestionsValue].filter(matches)
      if (names.length) groups.push(names.map(name => {
        const chosen = this.chosen.some(tag => same(tag, name))
        return item(`data-value="${escapeHtml(name)}" data-kind="toggle" aria-selected="${chosen}"`, `<span class="truncate">${escapeHtml(name)}</span>${chosen ? ICONS.check : ""}`, this.full && !chosen)
      }).join(""))
      const fresh = query.split(separators).map(part => part.trim()).filter(part => part && ![...this.chosen, ...this.suggestionsValue].some(name => same(name, part)))
      if (fresh.length && !this.full) groups.push(item(`data-value="${escapeHtml(query)}" data-kind="create"`, `${ICONS.plus}<span class="truncate">${escapeHtml(l.create.replace("%{name}", fresh.join(", ")))}</span>`))
    } else {
      const current = this.chosen[0] ?? ""
      const names = this.suggestionsValue.filter(matches)
      if (names.length) groups.push(names.map(name => {
        const chosen = same(name, current)
        return item(`data-value="${escapeHtml(chosen ? "" : name)}" data-kind="set" aria-selected="${chosen}"`, `<span class="truncate">${escapeHtml(name)}</span>${chosen ? ICONS.check : ""}`)
      }).join(""))
      const fresh = query.trim() && !this.suggestionsValue.some(name => same(name, query)) ? query.trim() : ""
      const rest = []
      if (fresh) rest.push(item(`data-value="${escapeHtml(fresh)}" data-kind="set"`, `${ICONS.plus}<span class="truncate">${escapeHtml(l.create.replace("%{name}", fresh))}</span>`))
      if (current.trim()) rest.push(item(`data-value="" data-kind="set"`, `${ICONS.x}${escapeHtml(l.clearCategory)}`))
      if (rest.length) groups.push(rest.join(""))
    }
    this.optionsTarget.innerHTML = groups.length
      ? groups.map(group => `<div class="overflow-hidden p-1 text-base-content">${group}</div>`).join('<div class="-mx-1 h-px bg-base-300"></div>')
      : `<p class="py-6 text-center text-sm">${escapeHtml(l.noLabels)}</p>`
  }

  pick(event) {
    const { value, kind } = event.currentTarget.dataset
    if (kind === "set") {
      this.chosen = value ? [value] : []
      this.sync()
      this.close(true)
      return
    }
    if (kind === "toggle") {
      const chosen = this.chosen.find(tag => same(tag, value))
      this.chosen = chosen ? this.chosen.filter(tag => tag !== chosen) : this.add(value)
    } else this.chosen = this.add(value)
    this.queryTarget.value = ""
    this.sync()
    this.render()
    this.queryTarget.focus()
  }

  // addTags: the separated parts, trimmed, unless already there in any case, up to the most tags.
  add(text) {
    const tags = [...this.chosen]
    for (const part of text.split(separators).map(item => item.trim())) {
      if (part && !tags.some(tag => same(tag, part))) tags.push(part.slice(0, this.maxLengthValue))
    }
    return tags.slice(0, this.maxValue)
  }

  remove(event) {
    this.chosen = this.chosen.filter(tag => tag !== event.currentTarget.dataset.tag)
    this.sync()
  }

  sync() {
    const l = this.labelsValue
    if (this.multi) {
      this.triggerTextTarget.textContent = this.full ? l.tagsFull : l.addTag
      this.chipsTarget.hidden = !this.chosen.length
      this.chipsTarget.innerHTML = this.chosen.map(tag => `<li class="inline-flex h-7 max-w-full items-center gap-0.5 rounded-full bg-base-200 pr-0.5 pl-2.5 text-[13px] text-base-content">
        <span class="truncate">${escapeHtml(tag)}</span>
        <button type="button" aria-label="${escapeHtml(l.removeTag.replace("%{tag}", tag))}" title="${escapeHtml(l.removeTag.replace("%{tag}", tag))}" data-tag="${escapeHtml(tag)}" data-action="label-picker#remove"
          class="grid size-6 shrink-0 place-items-center rounded-full text-base-content/60 outline-none hover:bg-base-100 hover:text-base-content focus-visible:ring-3 focus-visible:ring-primary/50">${ICONS.xSmall}</button></li>`).join("")
      // A blank tag keeps the field in the form when none is chosen, so clearing them saves.
      this.inputsTarget.innerHTML = (this.chosen.length ? this.chosen : [""]).map(tag => `<input type="hidden" name="${this.nameValue}" value="${escapeHtml(tag)}">`).join("")
    } else {
      const current = this.chosen[0] ?? ""
      this.triggerTextTarget.textContent = current || l.chooseCategory
      this.triggerTextTarget.classList.toggle("text-base-content/60", !current)
      this.inputsTarget.innerHTML = `<input type="hidden" name="${this.nameValue}" value="${escapeHtml(current)}">`
    }
    this.element.dispatchEvent(new Event("input", { bubbles: true }))
  }
}
