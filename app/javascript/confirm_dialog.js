import { Turbo } from "@hotwired/turbo-rails"

// typle-r's AlertDialog in place of window.confirm: a title, a description, optional details and two buttons. A form
// asks for it with data-turbo-confirm (the title) and data-confirm-* (see ConfirmHelper#confirm_data).
export function confirmDialog({ title, description = "", details = "", action, cancel, variant = "error" }) {
  const dialog = document.getElementById("confirm-dialog")
  if (!dialog) return Promise.resolve(window.confirm([title, description].filter(Boolean).join("\n\n")))
  dialog.querySelector("#confirm-dialog-title").textContent = title
  const text = dialog.querySelector("#confirm-dialog-description")
  text.textContent = description
  text.hidden = !description
  const extra = dialog.querySelector("[data-confirm-details]")
  extra.innerHTML = details
  extra.hidden = !details
  const cancelButton = dialog.querySelector("[data-confirm-cancel]")
  cancelButton.dataset.label ??= cancelButton.textContent
  cancelButton.textContent = cancel || cancelButton.dataset.label
  let confirmButton
  for (const button of dialog.querySelectorAll("[data-confirm-action]")) {
    button.hidden = button.dataset.variant !== variant
    if (!button.hidden) { confirmButton = button; button.textContent = action || dialog.dataset.defaultAction || "" }
  }
  return new Promise(resolve => {
    const finish = answer => {
      dialog.removeEventListener("close", onClose)
      cancelButton.onclick = confirmButton.onclick = null
      dialog.onclick = null
      if (dialog.open) dialog.close()
      resolve(answer)
    }
    const onClose = () => finish(false)
    dialog.addEventListener("close", onClose)
    cancelButton.onclick = () => finish(false)
    confirmButton.onclick = () => finish(true)
    // A click on the backdrop leaves the dialog open, as Radix's AlertDialog does.
    dialog.showModal()
    cancelButton.focus()
  })
}

function fromElement(title, element) {
  const data = element?.dataset ?? {}
  return confirmDialog({ title, description: data.confirmDescription, details: data.confirmDetails, action: data.confirmAction,
    cancel: data.confirmCancel, variant: data.confirmVariant || "error" })
}

Turbo.config.forms.confirm = (message, form, submitter) => fromElement(message, submitter?.dataset.turboConfirm ? submitter : form)
