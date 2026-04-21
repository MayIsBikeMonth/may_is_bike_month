import { Controller } from '@hotwired/stimulus'

// Connects to data-controller="punch"
// Active punches are encoded in the URL as
//   ?selected=userSlug:day,day;userSlug:day,...
// and restored on load. History is not pushed.
// Elements with `data-punch-activities-for="<id>"` are revealed when the
// matching punch is active.
export default class extends Controller {
  static targets = ['punch', 'ridgeBar', 'userButton', 'hideAllBtn']

  connect () {
    this.morphHandler = () => this.rebuild()
    this.element.addEventListener('turbo:morph-element', this.morphHandler)
    this.rebuild()
  }

  disconnect () {
    this.element.removeEventListener('turbo:morph-element', this.morphHandler)
  }

  rebuild () {
    this.indexPunches()
    this.applySelectionFromUrl()
    this.sync()
  }

  applySelectionFromUrl () {
    const selected = new URLSearchParams(window.location.search).get('selected')
    if (!selected) return
    selected.split(';').forEach(group => {
      const [slug, daysStr] = group.split(':')
      if (!slug || !daysStr) return
      daysStr.split(',').forEach(day => {
        this.punchesByKey.get(`${slug}:${parseInt(day, 10)}`)?.setAttribute('aria-pressed', 'true')
      })
    })
  }

  indexPunches () {
    this.punchesByDate = new Map()
    this.punchesByUser = new Map()
    this.punchesByKey = new Map()
    this.punchTargets.forEach(el => {
      const date = el.dataset.date
      const slug = el.dataset.userSlug
      const day = parseInt(date.slice(-2), 10)
      el._punchDay = day
      if (!this.punchesByDate.has(date)) this.punchesByDate.set(date, [])
      this.punchesByDate.get(date).push(el)
      if (!this.punchesByUser.has(slug)) this.punchesByUser.set(slug, [])
      this.punchesByUser.get(slug).push(el)
      this.punchesByKey.set(`${slug}:${day}`, el)
    })
    this.activityEls = Array.from(this.element.querySelectorAll('[data-punch-activities-for]'))
  }

  toggle (event) {
    const clicked = event.currentTarget
    const wasActive = clicked.getAttribute('aria-pressed') === 'true'
    clicked.setAttribute('aria-pressed', wasActive ? 'false' : 'true')
    this.afterToggle()
  }

  toggleDay (event) {
    this.toggleGroup(this.punchesByDate.get(event.currentTarget.dataset.date))
  }

  toggleUser (event) {
    this.toggleGroup(this.punchesByUser.get(event.currentTarget.dataset.userSlug))
  }

  toggleGroup (targets) {
    if (!targets || targets.length === 0) return
    const allActive = targets.every(el => el.getAttribute('aria-pressed') === 'true')
    targets.forEach(el => el.setAttribute('aria-pressed', allActive ? 'false' : 'true'))
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
      const targets = this.punchesByDate.get(bar.dataset.date) || []
      const allActive = targets.length > 0 && targets.every(el => el.getAttribute('aria-pressed') === 'true')
      bar.setAttribute('aria-pressed', allActive ? 'true' : 'false')
    })
  }

  syncUserButtons () {
    this.userButtonTargets.forEach(btn => {
      const targets = this.punchesByUser.get(btn.dataset.userSlug) || []
      const allActive = targets.length > 0 && targets.every(el => el.getAttribute('aria-pressed') === 'true')
      btn.setAttribute('aria-pressed', allActive ? 'true' : 'false')
    })
  }

  syncActivities () {
    const activeIds = new Set(
      this.punchTargets
        .filter(el => el.getAttribute('aria-pressed') === 'true')
        .map(el => el.dataset.punchId)
    )
    this.activityEls.forEach(el => {
      el.classList.toggle('hidden!', !activeIds.has(el.dataset.punchActivitiesFor))
    })
    const containers = new Set(this.activityEls.map(el => el.parentElement))
    containers.forEach(container => {
      const anyVisible = Array.from(container.children).some(child => !child.classList.contains('hidden!'))
      container.classList.toggle('hidden!', !anyVisible)
    })
  }

  syncHideAllButton () {
    const anyActive = this.punchTargets.some(el => el.getAttribute('aria-pressed') === 'true')
    this.hideAllBtnTargets.forEach(btn => btn.classList.toggle('hidden', !anyActive))
  }

  updateUrl () {
    const byUser = new Map()
    this.punchTargets
      .filter(el => el.getAttribute('aria-pressed') === 'true')
      .forEach(el => {
        const slug = el.dataset.userSlug
        if (!byUser.has(slug)) byUser.set(slug, [])
        byUser.get(slug).push(el._punchDay)
      })
    const encoded = Array.from(byUser, ([slug, days]) =>
      `${slug}:${days.sort((a, b) => a - b).join(',')}`
    ).join(';')
    const url = new URL(window.location.href)
    const current = url.searchParams.get('selected') ?? ''
    if (encoded === current) return
    if (encoded) {
      url.searchParams.set('selected', encoded)
    } else {
      url.searchParams.delete('selected')
    }
    window.history.replaceState(null, '', url)
  }
}
