import { Controller } from '@hotwired/stimulus'

/* global CSS, getComputedStyle, requestAnimationFrame */

export default class extends Controller {
  static values = {
    sticky: { type: Boolean, default: false }
  }

  connect () {
    this.applyEdgeStyles()
    this.boundRefresh = () => this.applyEdgeStyles()
    window.addEventListener('ui-table:refresh', this.boundRefresh)

    if (this.stickyValue) {
      this.boundResize = () => this.setupSticky()
      this.boundScroll = () => this.onScroll()
      window.addEventListener('resize', this.boundResize)
      this.setupSticky()
    }
  }

  disconnect () {
    if (this.boundRefresh) {
      window.removeEventListener('ui-table:refresh', this.boundRefresh)
    }
    if (this.boundResize) {
      window.removeEventListener('resize', this.boundResize)
    }
    if (this.boundScroll) {
      window.removeEventListener('scroll', this.boundScroll)
    }
  }

  refresh () {
    this.applyEdgeStyles()
  }

  setupSticky () {
    const wrapper = this.element
    const table = wrapper.querySelector('table.ui-table')
    const headerRow = table?.querySelector('thead tr')
    if (!table || !headerRow) return

    const ths = headerRow.querySelectorAll('th')
    ths.forEach(th => {
      th.style.transform = ''
      th.style.willChange = ''
      th.classList.remove('sticky', 'top-0')
    })

    const needsHorizontalScroll = table.scrollWidth > wrapper.clientWidth

    if (needsHorizontalScroll) {
      wrapper.style.overflowX = ''
      wrapper.classList.add('overflow-x-scroll')
      ths.forEach(th => { th.style.willChange = 'transform' })
      this.cacheMeasurements(table, headerRow, ths)
      this.bindScroll()
      this.applyTransformSticky()
    } else {
      wrapper.classList.remove('overflow-x-scroll')
      // Override .wrapper-padding-overflow's overflow-x:scroll so the wrapper isn't a scroll container,
      // which would anchor position:sticky to it instead of the viewport.
      wrapper.style.overflowX = 'visible'
      ths.forEach(th => th.classList.add('sticky', 'top-0'))
      this.unbindScroll()
    }
  }

  cacheMeasurements (table, headerRow, ths) {
    const rect = table.getBoundingClientRect()
    this.tableTop = rect.top + window.scrollY
    this.tableHeight = rect.height
    this.headerHeight = headerRow.offsetHeight
    this.stickyThs = ths
  }

  bindScroll () {
    window.addEventListener('scroll', this.boundScroll, { passive: true })
  }

  unbindScroll () {
    window.removeEventListener('scroll', this.boundScroll)
  }

  onScroll () {
    if (this.rafPending) return
    this.rafPending = true
    requestAnimationFrame(() => {
      this.applyTransformSticky()
      this.rafPending = false
    })
  }

  applyTransformSticky () {
    if (!this.stickyThs) return
    const offset = window.scrollY - this.tableTop
    const maxOffset = this.tableHeight - this.headerHeight
    let applied = 0
    if (offset > 0 && maxOffset > 0) {
      applied = Math.min(offset, maxOffset)
    }
    const translate = applied ? `translateY(${applied}px)` : ''
    this.stickyThs.forEach(th => {
      if (th.style.transform !== translate) th.style.transform = translate
    })
  }

  applyEdgeStyles () {
    const table = this.element.querySelector('table.ui-table')
    if (!table) return

    const bordered = table.classList.contains('ui-table-bordered')
    const thFirst = bordered ? 'ui-table-bordered-th-first' : 'rounded-tl-sm'
    const thLast = bordered ? 'ui-table-bordered-th-last' : 'rounded-tr-sm'
    const tdFirst = bordered ? 'ui-table-bordered-td-first' : 'rounded-bl-sm'
    const tdLast = bordered ? 'ui-table-bordered-td-last' : 'rounded-br-sm'
    const allClasses = [thFirst, thLast, tdFirst, tdLast]

    allClasses.forEach(cls => {
      table.querySelectorAll(`.${CSS.escape(cls)}`).forEach(el => el.classList.remove(cls))
    })

    const headerRow = table.querySelector('thead tr')
    if (headerRow) {
      const ths = this.visibleCells(headerRow, 'th')
      if (ths.length) {
        ths[0].classList.add(thFirst)
        ths[ths.length - 1].classList.add(thLast)
      }
    }

    const bodyRows = table.querySelectorAll('tbody tr')
    if (bordered) {
      bodyRows.forEach(row => {
        const tds = this.visibleCells(row, 'td')
        if (tds.length) {
          tds[0].classList.add(tdFirst)
          tds[tds.length - 1].classList.add(tdLast)
        }
      })
    } else if (bodyRows.length > 0) {
      const lastRow = bodyRows[bodyRows.length - 1]
      const tds = this.visibleCells(lastRow, 'td')
      if (tds.length) {
        tds[0].classList.add(tdFirst)
        tds[tds.length - 1].classList.add(tdLast)
      }
    }
  }

  visibleCells (row, tag) {
    return Array.from(row.querySelectorAll(tag)).filter(el =>
      getComputedStyle(el).display !== 'none'
    )
  }
}
