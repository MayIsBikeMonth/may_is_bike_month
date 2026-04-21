import { Controller } from '@hotwired/stimulus'

// Connects to data-controller="punch"
// Active punches are encoded in the URL as
//   ?selected=userSlug:day,day;userSlug:day,...
// and restored on load. History is not pushed. A separate `days=d,d,...`
// parameter tracks ridge-bar selection for days that have no punches yet
// (the user clicked the bar to pre-select a day so future activities show
// up when they arrive).
// Elements with `data-punch-activities-for="<id>"` are revealed when the
// matching punch is active.
//
// Across turbo morphs we also preserve *group intent*: if a user row, a
// specific day (including a pre-selected empty day), or all activities
// were fully selected before the morph, any newly-rendered punches in
// that group are re-activated so new activities appear without the user
// having to re-click.
export default class extends Controller {
  static targets = ['punch', 'ridgeBar', 'userButton', 'hideAllBtn', 'showAllBtn']

  connect () {
    this.activeUsers = new Set()
    this.activeDays = new Set()
    this.allActive = false
    this.selectedEmptyDays = new Set()
    this.beforeMorphHandler = (event) => {
      if (event.target === this.element) this.captureActiveGroups()
    }
    // idiomorph bubbles turbo:morph-element for every descendant during the
    // morph; debounce into one rebuild per morph cycle.
    this.morphHandler = () => this.scheduleRebuild()
    this.element.addEventListener('turbo:before-morph-element', this.beforeMorphHandler)
    this.element.addEventListener('turbo:morph-element', this.morphHandler)
    this.rebuild()
  }

  scheduleRebuild () {
    if (this.rebuildScheduled) return
    this.rebuildScheduled = true
    queueMicrotask(() => {
      this.rebuildScheduled = false
      this.rebuild()
    })
  }

  disconnect () {
    this.element.removeEventListener('turbo:before-morph-element', this.beforeMorphHandler)
    this.element.removeEventListener('turbo:morph-element', this.morphHandler)
  }

  rebuild () {
    this.indexPunches()
    this.selectedEmptyDays = new Set()
    this.applySelectionFromUrl()
    this.pruneSelectedEmptyDays()
    this.applyCapturedGroups()
    this.sync()
    this.updateUrl()
  }

  applySelectionFromUrl () {
    const params = new URLSearchParams(window.location.search)
    const selected = params.get('selected')
    if (selected) {
      selected.split(';').forEach(group => {
        const [slug, daysStr] = group.split(':')
        if (!slug || !daysStr) return
        daysStr.split(',').forEach(day => {
          this.punchesByKey.get(`${slug}:${parseInt(day, 10)}`)?.setAttribute('aria-pressed', 'true')
        })
      })
    }
    const days = params.get('days')
    if (days) {
      days.split(',').forEach(day => {
        const date = this.dateStringForDay(parseInt(day, 10))
        if (date) this.selectedEmptyDays.add(date)
      })
    }
  }

  // Drop dates that now have punches — their state derives from the
  // punches from here on.
  pruneSelectedEmptyDays () {
    Array.from(this.selectedEmptyDays).forEach(date => {
      if (this.punchesByDate.has(date)) this.selectedEmptyDays.delete(date)
    })
  }

  dateStringForDay (day) {
    const bar = this.ridgeBars.find(b => parseInt(b.dataset.date.slice(-2), 10) === day)
    return bar?.dataset.date
  }

  // Query the DOM directly (rather than via Stimulus target getters) so that
  // newly-morphed-in elements are picked up inside a synchronous
  // turbo:morph-element handler, before Stimulus's MutationObserver runs.
  indexPunches () {
    this.punches = Array.from(this.element.querySelectorAll('[data-punch-target="punch"]'))
    this.ridgeBars = Array.from(this.element.querySelectorAll('[data-punch-target="ridgeBar"]'))
    this.userButtons = Array.from(this.element.querySelectorAll('[data-punch-target="userButton"]'))
    this.hideAllBtns = Array.from(this.element.querySelectorAll('[data-punch-target="hideAllBtn"]'))
    this.showAllBtns = Array.from(this.element.querySelectorAll('[data-punch-target="showAllBtn"]'))
    this.activityEls = Array.from(this.element.querySelectorAll('[data-punch-activities-for]'))

    this.punchesByDate = new Map()
    this.punchesByUser = new Map()
    this.punchesByKey = new Map()
    this.punches.forEach(el => {
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
  }

  captureActiveGroups () {
    this.activeUsers = new Set()
    this.activeDays = new Set()
    this.allActive = this.punches?.length > 0 && this.punches.every(isPressed)
    if (this.allActive) return
    this.punchesByUser?.forEach((els, slug) => {
      if (els.length > 0 && els.every(isPressed)) this.activeUsers.add(slug)
    })
    this.punchesByDate?.forEach((els, date) => {
      if (els.length > 0 && els.every(isPressed)) this.activeDays.add(date)
    })
    this.selectedEmptyDays.forEach(date => this.activeDays.add(date))
  }

  applyCapturedGroups () {
    if (this.allActive) {
      this.punches.forEach(press)
      return
    }
    this.activeUsers.forEach(slug => (this.punchesByUser.get(slug) || []).forEach(press))
    this.activeDays.forEach(date => (this.punchesByDate.get(date) || []).forEach(press))
  }

  toggle (event) {
    const clicked = event.currentTarget
    clicked.setAttribute('aria-pressed', isPressed(clicked) ? 'false' : 'true')
    this.afterToggle()
  }

  toggleDay (event) {
    const date = event.currentTarget.dataset.date
    const targets = this.punchesByDate.get(date)
    if (targets && targets.length > 0) {
      this.toggleGroup(targets)
    } else {
      if (this.selectedEmptyDays.has(date)) {
        this.selectedEmptyDays.delete(date)
      } else {
        this.selectedEmptyDays.add(date)
      }
      this.afterToggle()
    }
  }

  toggleUser (event) {
    this.toggleGroup(this.punchesByUser.get(event.currentTarget.dataset.userSlug))
  }

  toggleGroup (targets) {
    if (!targets || targets.length === 0) return
    const allActive = targets.every(isPressed)
    targets.forEach(el => el.setAttribute('aria-pressed', allActive ? 'false' : 'true'))
    this.afterToggle()
  }

  showAll () {
    this.punches.forEach(press)
    this.afterToggle()
  }

  hideAll () {
    this.punches.forEach(unpress)
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
    this.syncAllButtons()
  }

  syncRidgeBars () {
    this.ridgeBars.forEach(bar => {
      const date = bar.dataset.date
      const targets = this.punchesByDate.get(date) || []
      const pressed = targets.length > 0
        ? groupAllActive(targets)
        : this.selectedEmptyDays.has(date)
      bar.setAttribute('aria-pressed', pressed ? 'true' : 'false')
    })
  }

  syncUserButtons () {
    this.userButtons.forEach(btn => {
      const targets = this.punchesByUser.get(btn.dataset.userSlug) || []
      btn.setAttribute('aria-pressed', groupAllActive(targets) ? 'true' : 'false')
    })
  }

  syncActivities () {
    const activeIds = new Set(
      this.punches.filter(isPressed).map(el => el.dataset.punchId)
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

  syncAllButtons () {
    const anyActive = this.punches.some(isPressed)
    const allActive = this.punches.length > 0 && this.punches.every(isPressed)
    this.hideAllBtns.forEach(btn => btn.classList.toggle('hidden', !anyActive))
    this.showAllBtns.forEach(btn => btn.setAttribute('aria-pressed', allActive ? 'true' : 'false'))
  }

  updateUrl () {
    const byUser = new Map()
    this.punches.filter(isPressed).forEach(el => {
      const slug = el.dataset.userSlug
      if (!byUser.has(slug)) byUser.set(slug, [])
      byUser.get(slug).push(el._punchDay)
    })
    const encoded = Array.from(byUser, ([slug, days]) =>
      `${slug}:${days.sort((a, b) => a - b).join(',')}`
    ).join(';')
    const emptyDays = Array.from(this.selectedEmptyDays)
      .map(d => parseInt(d.slice(-2), 10))
      .sort((a, b) => a - b)
      .join(',')
    const url = new URL(window.location.href)
    const currentSelected = url.searchParams.get('selected') ?? ''
    const currentDays = url.searchParams.get('days') ?? ''
    if (encoded === currentSelected && emptyDays === currentDays) return
    if (encoded) url.searchParams.set('selected', encoded); else url.searchParams.delete('selected')
    if (emptyDays) url.searchParams.set('days', emptyDays); else url.searchParams.delete('days')
    window.history.replaceState(null, '', url)
  }
}

const isPressed = (el) => el.getAttribute('aria-pressed') === 'true'
const press = (el) => el.setAttribute('aria-pressed', 'true')
const unpress = (el) => el.setAttribute('aria-pressed', 'false')
const groupAllActive = (els) => els.length > 0 && els.every(isPressed)
