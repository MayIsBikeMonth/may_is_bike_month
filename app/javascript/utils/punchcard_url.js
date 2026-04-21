// Read/write the punchcard's selection state on the URL.
//
//   ?selected=userSlug:day,day;userSlug:day,...   — explicit punch selections
//   ?days=d,d,...                                 — empty-day ridge bar selections
//
// Days are day-of-month integers; the competition always fits in one month.
// Selection is restored on load and updated via replaceState (no history
// entries are pushed).

// Parses the current window URL into { byUser, days }.
export const readUrlSelection = () => {
  const params = new URLSearchParams(window.location.search)
  const byUser = new Map()
  ;(params.get('selected') || '').split(';').forEach(entry => {
    const [slug, daysStr] = entry.split(':')
    if (!slug || !daysStr) return
    byUser.set(slug, daysStr.split(',').map(d => parseInt(d, 10)))
  })
  const days = (params.get('days') || '')
    .split(',')
    .filter(Boolean)
    .map(d => parseInt(d, 10))
  return { byUser, days }
}

// Writes a selection back to the URL via replaceState. No-op when nothing
// would change.
export const writeUrlSelection = ({ byUser, days }) => {
  const encodedSelected = Array.from(byUser, ([slug, daysArr]) =>
    `${slug}:${[...daysArr].sort((a, b) => a - b).join(',')}`
  ).join(';')
  const encodedDays = [...days].sort((a, b) => a - b).join(',')
  const url = new URL(window.location.href)
  const currentSelected = url.searchParams.get('selected') ?? ''
  const currentDays = url.searchParams.get('days') ?? ''
  if (encodedSelected === currentSelected && encodedDays === currentDays) return
  if (encodedSelected) url.searchParams.set('selected', encodedSelected); else url.searchParams.delete('selected')
  if (encodedDays) url.searchParams.set('days', encodedDays); else url.searchParams.delete('days')
  window.history.replaceState(null, '', url)
}
