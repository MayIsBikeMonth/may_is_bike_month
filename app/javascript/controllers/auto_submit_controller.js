import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  // hw-combobox:selection fires BEFORE the hidden field is updated
  // (the combobox dispatches the event, then mutates value in _createChip).
  // Defer to a microtask so requestSubmit reads the post-mutation value.
  connect () {
    this.submit = () => queueMicrotask(() => this.element.requestSubmit())
    this.element.addEventListener('hw-combobox:selection', this.submit)
    this.element.addEventListener('hw-combobox:removal', this.submit)
  }

  disconnect () {
    this.element.removeEventListener('hw-combobox:selection', this.submit)
    this.element.removeEventListener('hw-combobox:removal', this.submit)
  }
}
