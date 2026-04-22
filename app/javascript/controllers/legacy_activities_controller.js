import { Controller } from '@hotwired/stimulus'
import { setPressed } from 'utils/aria_pressed'

// data-controller="legacy-activities". Legacy rows render a
// Leaderboard::UserActivitiesForDateWrapper per user; both its container
// and each .punch-activities-container child carry hidden!, so toggling
// visibility means flipping hidden! on the container and every child.
// Rows carry data-user-slug to associate a container with its user button.

export default class extends Controller {
  static targets = ['userButton', 'hideAllBtn', 'showAllBtn']

  connect () { this.sync() }

  get containers () {
    return Array.from(this.element.querySelectorAll('.punch-activities-container'))
  }

  toggleUser (event) {
    const slug = event.currentTarget.dataset.userSlug
    const containers = this.forSlug(slug)
    if (containers.length === 0) return
    const on = !containers.every(el => this.isVisible(el))
    containers.forEach(el => this.setVisible(el, on))
    this.sync()
  }

  showAll () {
    this.containers.forEach(el => this.setVisible(el, true))
    this.sync()
  }

  hideAll () {
    this.containers.forEach(el => this.setVisible(el, false))
    this.sync()
  }

  forSlug (slug) {
    return this.containers.filter(el => el.closest('[data-user-slug]')?.dataset.userSlug === slug)
  }

  isVisible (el) { return !el.classList.contains('hidden!') }

  setVisible (container, on) {
    container.classList.toggle('hidden!', !on)
    container.querySelectorAll('[data-punch-activities-for]').forEach(el => {
      el.classList.toggle('hidden!', !on)
    })
  }

  sync () {
    this.userButtonTargets.forEach(btn => {
      const els = this.forSlug(btn.dataset.userSlug)
      setPressed(btn, els.length > 0 && els.every(el => this.isVisible(el)))
    })
    const all = this.containers
    const anyVisible = all.some(el => this.isVisible(el))
    this.hideAllBtnTargets.forEach(btn => btn.classList.toggle('hidden', !anyVisible))
    this.showAllBtnTargets.forEach(btn => setPressed(btn,
      all.length > 0 && all.every(el => this.isVisible(el))))
  }
}
