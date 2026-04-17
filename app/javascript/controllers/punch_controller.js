import { Controller } from '@hotwired/stimulus'

// Connects to data-controller="punch"
// Any number of punches can be active. Active punches are encoded in the URL
// as `?punches=ID,ID,...` and restored on load. History is not pushed.
// Elements with `data-punch-activities-for="<id>"` are revealed when the
// matching punch is active.
export default class extends Controller {
  static targets = ['punch', 'ridgeBar']

  connect () {
    const ids = new URLSearchParams(window.location.search).get('punches')?.split(',') || []
    this.punchTargets.forEach(el => {
      if (ids.includes(el.dataset.punchId)) {
        el.setAttribute('aria-pressed', 'true')
      }
    })
    this.syncRidgeBars()
    this.syncActivities()
  }

  toggle (event) {
    const clicked = event.currentTarget
    const wasActive = clicked.getAttribute('aria-pressed') === 'true'
    clicked.setAttribute('aria-pressed', wasActive ? 'false' : 'true')
    this.afterToggle()
  }

  toggleDay (event) {
    const date = event.currentTarget.dataset.date
    const dayPunches = this.punchTargets.filter(el => el.dataset.date === date)
    if (dayPunches.length === 0) return
    const allActive = dayPunches.every(el => el.getAttribute('aria-pressed') === 'true')
    dayPunches.forEach(el => el.setAttribute('aria-pressed', allActive ? 'false' : 'true'))
    this.afterToggle()
  }

  afterToggle () {
    this.syncRidgeBars()
    this.syncActivities()
    this.updateUrl()
  }

  syncRidgeBars () {
    this.ridgeBarTargets.forEach(bar => {
      const dayPunches = this.punchTargets.filter(el => el.dataset.date === bar.dataset.date)
      const allActive = dayPunches.length > 0 && dayPunches.every(el => el.getAttribute('aria-pressed') === 'true')
      bar.setAttribute('aria-pressed', allActive ? 'true' : 'false')
    })
  }

  syncActivities () {
    const activeIds = new Set(
      this.punchTargets
        .filter(el => el.getAttribute('aria-pressed') === 'true')
        .map(el => el.dataset.punchId)
    )
    this.element.querySelectorAll('[data-punch-activities-for]').forEach(el => {
      el.classList.toggle('hidden', !activeIds.has(el.dataset.punchActivitiesFor))
    })
  }

  updateUrl () {
    const activeIds = this.punchTargets
      .filter(el => el.getAttribute('aria-pressed') === 'true')
      .map(el => el.dataset.punchId)
    const url = new URL(window.location.href)
    if (activeIds.length > 0) {
      url.searchParams.set('punches', activeIds.join(','))
    } else {
      url.searchParams.delete('punches')
    }
    window.history.replaceState(null, '', url)
  }
}
