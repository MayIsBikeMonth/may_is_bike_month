import { Controller } from '@hotwired/stimulus'

/* global localStorage */
// Connects to data-controller="unit-preference"
export default class extends Controller {
  static targets = ['option']
  static values = { url: String }

  connect () {
    this.highlightActive()
  }

  select (event) {
    event.preventDefault()
    const unit = event.currentTarget.dataset.unit
    localStorage.setItem('unitPreference', unit)
    window.showPreferredUnit()
    this.highlightActive()
    this.save(unit)
  }

  highlightActive () {
    const current = window.currentUnitPreference()
    this.optionTargets.forEach(el => {
      const isActive = el.dataset.unit === current
      el.classList.toggle('option-active', isActive)
      el.classList.toggle('option-inactive', !isActive)
    })
  }

  save (unit) {
    if (!this.urlValue) return
    const token = document.querySelector('meta[name="csrf-token"]')?.content
    fetch(this.urlValue, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': token,
        Accept: 'text/html'
      },
      body: JSON.stringify({ user: { unit } })
    })
  }
}
