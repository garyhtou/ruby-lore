import "$styles/index.css"
import "$styles/syntax-highlighting.css"

// Import all JavaScript & CSS files from src/_components
import components from "$components/**/*.{js,jsx,js.rb,css}"

// Perf/CWV: this is now the whole initial-load JS bundle. GSAP +
// ScrollTrigger + the easter eggs (2b.1) + the timeline scroll (2b.2) + the
// _why scroll-telling (2b.3) all moved to a separate esbuild entry point,
// frontend/javascript/experience.js, which this loader fetches lazily (idle
// time or first interaction) instead of downloading it as part of every
// page's initial load. See frontend/javascript/core/load-experience.js for
// why, and src/_partials/_head.erb for where `data-experience-src` (the
// experience bundle's built URL) is put on this file's own <script> tag.
import { loadExperienceWhenIdle } from "./core/load-experience.js"

console.info("Bridgetown is loaded!")

// Read synchronously, during this classic deferred script's own top-level
// execution - document.currentScript is only reliable here, not from an
// async callback (requestIdleCallback/setTimeout/event handler) later.
loadExperienceWhenIdle(document.currentScript)
