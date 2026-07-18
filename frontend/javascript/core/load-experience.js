// Perf/CWV: lazily loads the "experience" bundle (GSAP +
// ScrollTrigger + the easter eggs + the timeline scroll + the _why
// scroll-telling - see frontend/javascript/experience.js) instead of
// downloading/parsing/executing it as part of the initial page load.
//
// Why: GSAP + the scroll scenes are the bulk of the site's JS but are
// non-critical to first paint - they only ANIMATE static content that
// already rendered without them (the two-layer rule: content is static
// HTML, JS is enhancement-only). Every page paid for all of it anyway
// because the old single bundle was `defer`red as one file. Deferring
// *loading* the experience bundle itself - past first paint, past LCP,
// until the browser is idle or the visitor actually does something - means
// the initial JS transfer is just this tiny loader, and the heavy bundle
// only costs bytes/CPU once it can't compete with rendering the page.
//
// Trigger: whichever happens first -
//   - requestIdleCallback (browser is done with more important work), or
//   - the first real interaction (pointer, key, touch, or scroll) - so an
//     eager visitor who starts scrolling the timeline or _why immediately
//     doesn't wait for idle time that may never come on a busy page.
// A short setTimeout fallback covers browsers without
// requestIdleCallback (e.g. Safari) so the bundle still loads eventually
// even on a page with no interaction and no idle window.
//
// This never affects prefers-reduced-motion: every animation module still
// makes its own reduced-motion check once it loads (see
// frontend/javascript/lib/gsap.js's prefersReducedMotion() and each
// module's gsap.matchMedia() branch) - this loader only controls *when*
// the code arrives, never *whether* motion runs.

const INTERACTION_EVENTS = ["pointerdown", "keydown", "touchstart", "wheel"]
const IDLE_TIMEOUT_MS = 4000
const FALLBACK_DELAY_MS = 2000

/**
 * Kick off the lazy load of the experience bundle. Safe to call even if the
 * bundle URL isn't available (e.g. a future page render without the
 * data attribute) - it's a silent no-op rather than an error, since the
 * experience bundle is enhancement-only.
 * @param {HTMLScriptElement | null} scriptEl the currently-executing
 *   `<script>` tag, read via `document.currentScript` by the caller
 *   *synchronously* (before this function schedules anything async) - see
 *   frontend/javascript/index.js.
 */
export function loadExperienceWhenIdle(scriptEl) {
  const src = scriptEl && scriptEl.getAttribute("data-experience-src")
  if (!src) return

  let loaded = false

  const load = () => {
    if (loaded) return
    loaded = true
    INTERACTION_EVENTS.forEach((eventName) =>
      window.removeEventListener(eventName, load)
    )

    const tag = document.createElement("script")
    tag.src = src
    tag.defer = true
    document.head.appendChild(tag)
  }

  INTERACTION_EVENTS.forEach((eventName) =>
    window.addEventListener(eventName, load, { once: true, passive: true })
  )

  if ("requestIdleCallback" in window) {
    window.requestIdleCallback(load, { timeout: IDLE_TIMEOUT_MS })
  } else {
    window.setTimeout(load, FALLBACK_DELAY_MS)
  }
}
