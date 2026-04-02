import { Controller } from '@hotwired/stimulus'

/* global localStorage */
// Connects to data-controller="unit-preference"
export default class extends Controller {
  static targets = ['option']

  connect () {
    this.highlightActive()
  }

  select (event) {
    event.preventDefault()
    const unit = event.currentTarget.dataset.unit
    localStorage.setItem('unitPreference', unit)
    window.showPreferredUnit()
    this.highlightActive()
  }

  highlightActive () {
    const current = window.currentUnitPreference()
    this.optionTargets.forEach(el => {
      const isActive = el.dataset.unit === current
      el.classList.toggle('ring-2', isActive)
      el.classList.toggle('ring-blue-500', isActive)
      el.classList.toggle('opacity-60', !isActive)
      el.classList.toggle('opacity-100', isActive)
    })
  }
}
