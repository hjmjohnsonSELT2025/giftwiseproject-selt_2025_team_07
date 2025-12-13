// app/javascript/controllers/chat_icon_controller.js
// Stimulus controller for chat icon popup functionality

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["popup"]

    toggle(event) {
        event.stopPropagation()
        this.popupTarget.classList.toggle("hidden")
    }

    connect() {
        // Close popup when clicking outside
        this.boundHandleClickOutside = this.handleClickOutside.bind(this)
        document.addEventListener("click", this.boundHandleClickOutside)
    }

    disconnect() {
        document.removeEventListener("click", this.boundHandleClickOutside)
    }

    handleClickOutside(event) {
        if (!this.element.contains(event.target)) {
            this.popupTarget.classList.add("hidden")
        }
    }
}