import { Controller } from "@hotwired/stimulus"

const KEY = "typle-r:theme:v1"
const DARK = "(prefers-color-scheme: dark)"
// daisyUI's themes (app/assets/tailwind/application.css), set as data-theme on <html>.
const LIGHT_THEME = "typle"
const DARK_THEME = "typle-dark"

// The top bar's dark mode button: toggles daisyUI's light and dark themes, kept in this browser.
export default class extends Controller {
  static targets = ["button", "failed"]

  connect() {
    this.media = window.matchMedia(DARK)
    this.sync = () => { this.apply(this.preference()); this.show() }
    this.media.addEventListener("change", this.sync)
    this.show()
  }

  disconnect() { this.media.removeEventListener("change", this.sync) }

  get dark() { return document.documentElement.dataset.theme === DARK_THEME }

  preference() {
    const value = document.documentElement.dataset.themePreference
    return value === "light" || value === "dark" ? value : "system"
  }

  apply(preference) {
    const root = document.documentElement
    root.dataset.themePreference = preference
    root.dataset.theme = preference === "dark" || (preference === "system" && this.media.matches) ? DARK_THEME : LIGHT_THEME
  }

  toggle() {
    const preference = this.dark ? "light" : "dark"
    this.apply(preference)
    let saved = true
    try { localStorage.setItem(KEY, preference) } catch { saved = false }
    this.failedTarget.hidden = saved
    this.show()
  }

  show() {
    const dark = this.dark
    this.buttonTarget.setAttribute("aria-pressed", String(dark))
    this.buttonTarget.title = dark ? this.buttonTarget.dataset.toLight : this.buttonTarget.dataset.toDark
  }
}
