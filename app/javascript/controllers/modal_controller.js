import { Controller } from '@hotwired/stimulus'

// Connects to data-controller="modal"
export default class extends Controller {
  static targets = ['dialog']

  open () {
    this.dialogTarget.showModal()
    document.body.classList.add('overflow-hidden')
  }

  close () {
    this.dialogTarget.close()
    document.body.classList.remove('overflow-hidden')
  }

  backdropClick (event) {
    if (event.target === this.dialogTarget) {
      this.close()
    }
  }

  handleKeydown (event) {
    if (event.key === 'Escape') {
      this.close()
    }
  }
}
