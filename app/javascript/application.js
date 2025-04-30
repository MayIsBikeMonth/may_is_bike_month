import '@hotwired/turbo-rails'
import TimeLocalizer from 'utils/time_localizer'

// Import stimulus controllers
import { Application } from '@hotwired/stimulus'
// Lazy load all controllers
import { lazyLoadControllersFrom } from '@hotwired/stimulus-loading'

const application = Application.start()

// Configure Stimulus development experience
application.debug = false
window.Stimulus = application

lazyLoadControllersFrom('components', application)

// const toggleChecks = (event) => {
//   const checked = event.target.checked
//   event.target.closest('.toggleChecksWrapper')
//     .querySelectorAll('.toggleableCheck').forEach(el => {
//       el.checked = checked
//     })
// }

// const enableToggleChecks = () => {
//   document.querySelectorAll('.toggleChecks')
//     .forEach(el => el.addEventListener('change', toggleChecks))
// }

// // Internal
// const elementsFromSelectorOrElements = (selOrEl) => {
//   if (typeof (selOrEl) === 'string') {
//     return document.querySelectorAll(selOrEl)
//   } else {
//     return [selOrEl].flat()
//   }
// }

// // toggle can be: [true, 'hide', 'show']
// const elementsCollapse = (selOrEl, toggle = true) => {
//   const els = elementsFromSelectorOrElements(selOrEl)
//   // log.trace(`toggling: ${toggle}`)
//   // If toggling, determine which direction to toggle
//   if (toggle === true) {
//     toggle = els[0]?.classList.contains('hidden') ? 'show' : 'hide'
//   }
//   // TODO: add animation functionality
//   if (toggle === 'show') {
//     els.forEach(el => el.classList.remove('hidden'))
//   } else {
//     els.forEach(el => el.classList.add('hidden'))
//   }
// }

// const expandSiblingsEllipse = (event) => {
//   event.preventDefault()
//   const target = event.currentTarget
//   const parent = target.parentElement
//   // WTF, failing to pass array in
//   parent.querySelectorAll('.hidden').forEach(el => elementsCollapse(el, 'show'))
//   elementsCollapse(target, 'hide')
// }

// // TODO: Move this into a stimulus controller
// // It's impossible to redirect_to anchor locations with Hotwire (because of :see_other)
// // So: this adds an event listener to store anchor locations prior to form submission
// // and scrolls to the stored location
// const scrollToStoredLocation = () => {
//   const storedAnchor = localStorage.getItem('storedAnchorLocation')
//   if (storedAnchor) {
//     console.log(`scrolling to stored anchor: ${storedAnchor}`)
//     window.location.hash = storedAnchor
//     localStorage.removeItem('storedAnchorLocation')
//   }

//   document.querySelectorAll('.button_to')
//     .forEach(el => {
//       if (buttonToAnchorTarget(el)) {
//         el.addEventListener('submit', storeAnchorLocation)
//       }
//     })
// }

// // Pull out the anchor target from button_to
// const buttonToAnchorTarget = (el) => {
//   const result = el?.action?.match(/#.*/)
//   return result && result[0]
// }

// const storeAnchorLocation = (event) => {
//   localStorage.setItem('storedAnchorLocation', buttonToAnchorTarget(event.target))
//   return true
// }

// // MIBM SPECIFIC Functions

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

const currentActivityVisibility = () => {
  let activityVisibility = localStorage.getItem('activityVisibility')
  if (activityVisibility === null || activityVisibility !== 'show-all') {
    activityVisibility = 'hidden'
  } else {
    activityVisibility = 'show-all'
  }
  localStorage.setItem('activityVisibility', activityVisibility)
  return activityVisibility
}

const showActivityVisibility = () => {
  if (currentActivityVisibility() === 'hidden') {
    document.querySelectorAll('.activityList').forEach(el => el.classList.add('hidden'))
    document.querySelectorAll('.toggleActivities-shown').forEach(el => el.classList.add('hidden'))
    document.querySelectorAll('.toggleActivities-hidden').forEach(el => el.classList.remove('hidden'))
  } else {
    document.querySelectorAll('.activityList, .toggleActivities-shown').forEach(el => el.classList.remove('hidden'))
    document.querySelectorAll('.toggleActivities-hidden').forEach(el => el.classList.add('hidden'))
    document.querySelectorAll('.toggleActivities-shown').forEach(el => el.classList.remove('hidden'))
  }
}

const toggleActivities = () => {
  document.querySelectorAll('.activityList').forEach(el => el.classList.toggle('hidden'))
  const newVisibility = currentActivityVisibility() === 'hidden' ? 'show-all' : 'hidden'
  localStorage.setItem('activityVisibility', newVisibility)
  // console.log(newVisibility, currentActivityVisibility())
  showActivityVisibility()
}

// Make a request to internal endpoint that updates Strava
window.updateStravaInBackground = async function () {
  const response = await fetch('/update_strava')
  const updateResponse = await response.json()
  console.log(updateResponse)
  setInterval(function () {
    window.updateStravaInBackground()
    // Manual page reload
    window.location.reload()
  }, 600000) // ~ 10 minutes

  // TODO: update the page based on updates, actioncable
}

// document.addEventListener('turbo:load', () => {
//   scrollToStoredLocation()

//   if (!window.timeParser) window.timeParser = new TimeParser()
//   window.timeParser.localize()

//   enableToggleChecks()
//   enableFullscreenTableOverflow()
//   setMaxWidths()

//   // When JS is enabled, some things should be hidden and some things should be shown

//   document.querySelectorAll('.expandSiblingsEllipse')
//     .forEach(el => el.addEventListener('click', expandSiblingsEllipse))

//   // Function to loop update Strava
//   window.updateStravaInBackground()

//   // TODO: can these all be defined not on the window since we have eslint?

//   // Toggle activities
//   showActivityVisibility()
//   document.querySelector('#toggleIndividualActivities')?.addEventListener('click', toggleActivities)

//   // Add the click selector to the toggle button
//   document.querySelectorAll('a.toggleUnitPreference').forEach(el => el.addEventListener('click', window.toggleUnitPreference))
//   window.showPreferredUnit()
// })

document.addEventListener('turbo:load', () => {
  console.log('turbo:loaded')

  if (window.shouldUpdateStravaInBackground) {
    window.updateStravaInBackground()
  }

  if (!window.timeLocalizer) window.timeLocalizer = new TimeLocalizer()
  window.timeLocalizer.localize()

  // This is set on the window on the view pages (but not the lookbook pages)
  if (window.enableToggles) {
    // Add the click selector to the toggle button
    document.querySelectorAll('a.toggleUnitPreference').forEach(el => el.addEventListener('click', window.toggleUnitPreference))
    window.showPreferredUnit()

    // Toggle activities
    showActivityVisibility()
    document.querySelector('#toggleIndividualActivities')?.addEventListener('click', toggleActivities)

    // Add the click selector to the toggle button
    document.querySelectorAll('a.toggleUnitPreference').forEach(el => el.addEventListener('click', window.toggleUnitPreference))
    window.showPreferredUnit()
  }
})
