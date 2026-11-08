// LiveView glue for the Carbon web components rendered by CarbonPhoenix.
//
// This file intentionally has no imports. Your app registers the web
// components and styles itself (see the README):
//
//   import "@carbon/web-components/es/index.js"
//   import "@carbon/styles/css/styles.css"
//   import {CarbonEvents} from "carbon_phoenix"

// Turn plain values out of a DOM event detail into something JSON safe.
function serialize(value, depth = 0) {
  if (value === null || ["string", "number", "boolean"].includes(typeof value)) return value
  if (value === undefined || typeof value === "function" || depth > 3) return null
  if (value instanceof Node) return value.id || value.localName || null
  if (Array.isArray(value)) return value.map(v => serialize(v, depth + 1))
  const out = {}
  for (const key of Object.keys(value)) out[key] = serialize(value[key], depth + 1)
  return out
}

/**
 * Forwards Carbon custom events to LiveView.
 *
 * Driven by `data-carbon-on='{"cds-modal-closed": "close_modal"}'`, which the
 * `on={%{...}}` assign of the Elixir components renders. The LiveView receives
 * `%{"event" => dom_event_name, "detail" => detail, "value" => el.value, "id" => el.id}`.
 */
export const CarbonEvents = {
  mounted() { this.bind() },
  updated() { this.bind() },
  destroyed() { this.unbind() },
  bind() {
    this.unbind()
    const map = JSON.parse(this.el.dataset.carbonOn || "{}")
    this.listeners = Object.entries(map).map(([type, name]) => {
      const fn = e => {
        if (e.target !== this.el && !e.composedPath().includes(this.el)) return
        const payload = {
          event: type,
          id: this.el.id,
          value: serialize(this.el.value),
          checked: serialize(this.el.checked),
          detail: serialize(e.detail),
        }
        const target = this.el.getAttribute("phx-target")
        target ? this.pushEventTo(target, name, payload) : this.pushEvent(name, payload)
      }
      this.el.addEventListener(type, fn)
      return [type, fn]
    })
  },
  unbind() {
    (this.listeners || []).forEach(([type, fn]) => this.el.removeEventListener(type, fn))
    this.listeners = []
  },
}
