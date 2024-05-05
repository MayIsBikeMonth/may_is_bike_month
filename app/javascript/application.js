// Entry point for the build script in your package.json
import "@hotwired/turbo-rails" // eslint-disable-line
// Import flowbite, a tailwind component library, for interactions
import 'flowbite'

import TimeParser from './scripts/time_parser'
import log from './scripts/log'
import './controllers'

const toggleChecks = (event) => {
  const checked = event.target.checked
  event.target.closest('.toggleChecksWrapper')
    .querySelectorAll('.toggleableCheck').forEach(el => {
      el.checked = checked
    })
}

const enableToggleChecks = () => {
  document.querySelectorAll('.toggleChecks')
    .forEach(el => el.addEventListener('change', toggleChecks))
}

const pageWidth = window.outerWidth
const enableFullscreenTableOverflow = () => {
  document.querySelectorAll('.full-screen-table table').forEach(el => {
    const tableWidth = el.offsetWidth
    if (tableWidth > pageWidth) {
      log.debug('overflown')
      el.closest('.full-screen-table').classList.add('full-screen-table-overflown')
    }
  })
}

const setMaxWidths = () => {
  if (pageWidth < 501) {
    document.querySelectorAll('.maxWScreen')
      .forEach(el => {
        // 8px on either side of padding
        el.style.maxWidth = `${pageWidth - 16}px`
      })
  }
}

// Internal
const elementsFromSelectorOrElements = (selOrEl) => {
  if (typeof (selOrEl) === 'string') {
    return document.querySelectorAll(selOrEl)
  } else {
    return [selOrEl].flat()
  }
}

// toggle can be: [true, 'hide', 'show']
const elementsCollapse = (selOrEl, toggle = true) => {
  const els = elementsFromSelectorOrElements(selOrEl)
  // log.trace(`toggling: ${toggle}`)
  // If toggling, determine which direction to toggle
  if (toggle === true) {
    toggle = els[0]?.classList.contains('hidden') ? 'show' : 'hide'
  }
  // TODO: add animation functionality
  if (toggle === 'show') {
    els.forEach(el => el.classList.remove('hidden'))
  } else {
    els.forEach(el => el.classList.add('hidden'))
  }
}

const expandSiblingsEllipse = (event) => {
  event.preventDefault()
  const target = event.currentTarget
  const parent = target.parentElement
  // WTF, failing to pass array in
  parent.querySelectorAll('.hidden').forEach(el => elementsCollapse(el, 'show'))
  elementsCollapse(target, 'hide')
}

// TODO: Move this into a stimulus controller
// It's impossible to redirect_to anchor locations with Hotwire (because of :see_other)
// So: this adds an event listener to store anchor locations prior to form submission
// and scrolls to the stored location
const scrollToStoredLocation = () => {
  const storedAnchor = localStorage.getItem('storedAnchorLocation')
  if (storedAnchor) {
    log.debug(`scrolling to stored anchor: ${storedAnchor}`)
    window.location.hash = storedAnchor
    localStorage.removeItem('storedAnchorLocation')
  }

  document.querySelectorAll('.button_to')
    .forEach(el => {
      if (buttonToAnchorTarget(el)) {
        el.addEventListener('submit', storeAnchorLocation)
      }
    })
}

// Pull out the anchor target from button_to
const buttonToAnchorTarget = (el) => {
  const result = el?.action?.match(/#.*/)
  return result && result[0]
}

const storeAnchorLocation = (event) => {
  localStorage.setItem('storedAnchorLocation', buttonToAnchorTarget(event.target))
  return true
}

// MIBM SPECIFIC Functions

window.currentUnitPreference = () => {
  let unitPreference = localStorage.getItem('unitPreference')
  if (unitPreference === null || unitPreference !== 'metric') {
    unitPreference = 'imperial'
  } else {
    unitPreference = 'metric'
  }
  localStorage.setItem('unitPreference', unitPreference)
  return unitPreference
}

window.toggleUnitPreference = (event = false) => {
  event && event.preventDefault()
  const newUnit = window.currentUnitPreference() === 'metric' ? 'imperial' : 'metric'
  localStorage.setItem('unitPreference', newUnit)
  window.showPreferredUnit()
  // console.log(newUnit)
}

window.showPreferredUnit = () => {
  const unit = window.currentUnitPreference()
  document.querySelectorAll(`.unit-${unit}`).forEach(el => el.classList.remove('hidden'))
  const hiddenUnit = unit === 'metric' ? 'imperial' : 'metric'
  document.querySelectorAll(`.unit-${hiddenUnit}`).forEach(el => el.classList.add('hidden'))
}

// SHOW Activities
window.toggleActivities = (event) => {
  console.log(event)
  // TODO: Make this work
  // document.querySelectorAll(".activityList").forEach(el => el.classList.toggle("hidden"))
}

// Make a request to internal endpoint that updates Strava
window.updateStravaInBackground = async function () {
  const response = await fetch('/update_strava')
  const updateResponse = await response.json()
  console.log(updateResponse)
  setInterval(function () {
    window.updateStravaInBackground()
  }, 650000) // ~ 10 minutes

  // TODO: update the page based on updates
}

document.addEventListener('turbo:load', () => {
  scrollToStoredLocation()

  if (!window.timeParser) window.timeParser = new TimeParser()
  window.timeParser.localize()

  enableToggleChecks()
  enableFullscreenTableOverflow()
  setMaxWidths()

  // When JS is enabled, some things should be hidden and some things should be shown
  document.querySelectorAll('.hiddenNoJs').forEach(el => el.classList.remove('hiddenNoJs'))
  document.querySelectorAll('.hiddenOnJs').forEach(el => el.classList.add('hidden'))

  document.querySelectorAll('.expandSiblingsEllipse')
    .forEach(el => el.addEventListener('click', expandSiblingsEllipse))

  // Function to loop update Strava
  window.updateStravaInBackground()

  // TODO: can these all be defined not on the window since we have eslint?

  // Toggle activities
  document.querySelector('#toggleIndividualActivities')?.addEventListener('click', window.toggleActivities)

  // Add the click selector to the toggle button
  document.querySelectorAll('a.toggleUnitPreference').forEach(el => el.addEventListener('click', window.toggleUnitPreference))
  window.showPreferredUnit()
})
