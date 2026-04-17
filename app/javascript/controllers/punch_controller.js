import { Controller } from '@hotwired/stimulus'

// Connects to data-controller="punch"
// Any number of punches can be active. Active punches are encoded in the URL
// as `?punches=ID,ID,...` and restored on load. History is not pushed.
// Elements with `data-punch-activities-for="<id>"` are revealed when the
// matching punch is active.
export default class extends Controller {
  static targets = ['punch', 'ridgeBar', 'userButton', 'hideAllBtn']

  connect () {
    const ids = new URLSearchParams(window.location.search).get('punches')?.split(',') || []
    this.punchTargets.forEach(el => {
      if (ids.includes(el.dataset.punchId)) {
        el.setAttribute('aria-pressed', 'true')
      }
    })
    this.sync()
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

  toggleUser (event) {
    const slug = event.currentTarget.dataset.userSlug
    const userPunches = this.punchTargets.filter(el => el.dataset.userSlug === slug)
    if (userPunches.length === 0) return
    const allActive = userPunches.every(el => el.getAttribute('aria-pressed') === 'true')
    userPunches.forEach(el => el.setAttribute('aria-pressed', allActive ? 'false' : 'true'))
    this.afterToggle()
  }

  showAll () {
    this.punchTargets.forEach(el => el.setAttribute('aria-pressed', 'true'))
    this.afterToggle()
  }

  hideAll () {
    this.punchTargets.forEach(el => el.setAttribute('aria-pressed', 'false'))
    this.afterToggle()
  }

  afterToggle () {
    this.sync()
    this.updateUrl()
  }

  sync () {
    this.syncRidgeBars()
    this.syncUserButtons()
    this.syncActivities()
    this.syncHideAllButton()
  }

  syncRidgeBars () {
    this.ridgeBarTargets.forEach(bar => {
      const dayPunches = this.punchTargets.filter(el => el.dataset.date === bar.dataset.date)
      const allActive = dayPunches.length > 0 && dayPunches.every(el => el.getAttribute('aria-pressed') === 'true')
      bar.setAttribute('aria-pressed', allActive ? 'true' : 'false')
    })
  }

  syncUserButtons () {
    this.userButtonTargets.forEach(btn => {
      const userPunches = this.punchTargets.filter(el => el.dataset.userSlug === btn.dataset.userSlug)
      const allActive = userPunches.length > 0 && userPunches.every(el => el.getAttribute('aria-pressed') === 'true')
      btn.setAttribute('aria-pressed', allActive ? 'true' : 'false')
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

  syncHideAllButton () {
    const anyActive = this.punchTargets.some(el => el.getAttribute('aria-pressed') === 'true')
    this.hideAllBtnTargets.forEach(btn => btn.classList.toggle('hidden', !anyActive))
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
