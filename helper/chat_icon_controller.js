// app/javascript/controllers/chat_icon_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["popup"]

  toggle(event) {
    event.stopPropagation()
    this.popupTarget.classList.toggle("hidden")
  }

  connect() {
    // Close popup when clicking outside
    document.addEventListener("click", this.handleClickOutside.bind(this))
  }

  disconnect() {
    document.removeEventListener("click", this.handleClickOutside.bind(this))
  }

  handleClickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.popupTarget.classList.add("hidden")
    }
  }
}
