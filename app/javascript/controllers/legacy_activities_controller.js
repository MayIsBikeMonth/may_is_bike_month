import { Controller } from '@hotwired/stimulus'
import { setPressed } from 'utils/aria_pressed'

// data-controller="legacy-activities". Mirrors the UX of the punch
// controller — show/hide all, plus per-user toggle — but without the
// per-day punch model: legacy rows have a single activities container
// per user, keyed by data-user-slug.

export default class extends Controller {
  static targets = ['userButton', 'activities', 'hideAllBtn', 'showAllBtn']

  connect () { this.sync() }

  toggleUser (event) {
    const slug = event.currentTarget.dataset.userSlug
    const els = this.forSlug(slug)
    if (els.length === 0) return
    const on = !els.every(el => !el.classList.contains('hidden!'))
    els.forEach(el => el.classList.toggle('hidden!', !on))
    this.sync()
  }

  showAll () {
    this.activitiesTargets.forEach(el => el.classList.remove('hidden!'))
    this.sync()
  }

  hideAll () {
    this.activitiesTargets.forEach(el => el.classList.add('hidden!'))
    this.sync()
  }

  forSlug (slug) {
    return this.activitiesTargets.filter(el => el.dataset.userSlug === slug)
  }

  isVisible (el) { return !el.classList.contains('hidden!') }

  sync () {
    this.userButtonTargets.forEach(btn => {
      const els = this.forSlug(btn.dataset.userSlug)
      setPressed(btn, els.length > 0 && els.every(el => this.isVisible(el)))
    })
    const anyVisible = this.activitiesTargets.some(el => this.isVisible(el))
    this.hideAllBtnTargets.forEach(btn => btn.classList.toggle('hidden', !anyVisible))
    this.showAllBtnTargets.forEach(btn => setPressed(btn,
      this.activitiesTargets.length > 0 && this.activitiesTargets.every(el => this.isVisible(el))))
  }
}
