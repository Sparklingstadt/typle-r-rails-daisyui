import { Controller } from "@hotwired/stimulus"

// typle-r's PackListOrder: a pack's lists sorted by dragging the grip, by Alt+↑↓ on the grip, or from a row's menu.
export default class extends Controller {
  static targets = ["rows", "row", "announce"]

  connect() { this.update() }

  update() {
    const rows = this.rowTargets
    rows.forEach((row, index) => {
      row.querySelectorAll("[data-move]").forEach(button => {
        const where = button.dataset.move
        button.disabled = (where === "up" || where === "first") ? index === 0 : index === rows.length - 1
      })
    })
    this.element.dispatchEvent(new Event("input", { bubbles: true }))
  }

  move(event) {
    const row = event.target.closest("[data-list-order-target=row]")
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
    this.update()
  }

  gripKey(event) {
    if (event.key !== "ArrowUp" && event.key !== "ArrowDown") return
    event.preventDefault()
    this.moveTo(event.target.closest("[data-list-order-target=row]"), event.key === "ArrowUp" ? "up" : "down")
    event.target.focus()
  }

  dragStart(event) {
    this.dragged = event.target.closest("[data-list-order-target=row]")
    event.dataTransfer.effectAllowed = "move"
    this.dragged.classList.add("bg-base-200", "shadow-md")
    this.over = over => {
      const row = over.target.closest?.("[data-list-order-target=row]")
      if (!row || !this.dragged) return
      over.preventDefault()
      if (row === this.dragged) return
      const box = row.getBoundingClientRect()
      if (over.clientY < box.top + box.height / 2) row.before(this.dragged)
      else row.after(this.dragged)
    }
    this.rowsTarget.addEventListener("dragover", this.over)
  }

  dragEnd() {
    this.dragged?.classList.remove("bg-base-200", "shadow-md")
    this.dragged = null
    this.rowsTarget.removeEventListener("dragover", this.over)
    this.update()
  }
}
