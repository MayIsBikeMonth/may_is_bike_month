// Small helpers for reading and writing aria-pressed state on DOM elements.
//
// Used by the punch controller to drive selection state on punches, ridge
// bars, user buttons, and the show-all button uniformly.

export const isPressed = (el) => el.getAttribute('aria-pressed') === 'true'

export const press = (el) => el.setAttribute('aria-pressed', 'true')

export const unpress = (el) => el.setAttribute('aria-pressed', 'false')

export const setPressed = (el, on) =>
  el.setAttribute('aria-pressed', on ? 'true' : 'false')

// True when there's at least one element and every one is pressed.
export const allPressed = (els) => els.length > 0 && els.every(isPressed)
