// Perf/CWV: the "experience" bundle - GSAP + ScrollTrigger, the
// easter eggs (2b.1), the timeline scroll (2b.2), and the _why scroll-telling
// (2b.3). This is the entire non-critical, animation-only part of the site's
// JS (the bulk of the former single ~124KB bundle). It is a SEPARATE esbuild
// entry point (see esbuild.config.js) from frontend/javascript/index.js, and
// is never referenced by a static <script> tag - it's fetched lazily by
// frontend/javascript/core/load-experience.js (at browser idle time or on
// first user interaction, whichever comes first), so first paint, LCP, and
// initial JS transfer size never wait on or pay for GSAP.
//
// Nothing here creates, gates, or moves content: every module it wires up
// (easter-eggs/*, timeline/index.js, why/index.js) only enhances DOM that
// already rendered from static HTML long before this file ever loads - see
// each module's own header comment and script/check_no_js_content.rb, the
// site's zero-JS-content guard. Deferring *when* this bundle loads changes
// nothing about that contract.

import "./lib/gsap.js"

import { initEasterEggs } from "./easter-eggs/index.js"
import { initTimeline } from "./timeline/index.js"
import { initWhy } from "./why/index.js"

initEasterEggs()
initTimeline()
initWhy()
