import "$styles/index.css"
import "$styles/syntax-highlighting.css"

// Import all JavaScript & CSS files from src/_components
import components from "$components/**/*.{js,jsx,js.rb,css}"

// GSAP + ScrollTrigger are wired once here (frontend/javascript/lib/gsap.js)
// so the later scrubbable-timeline (2b.2) and _why scroll-telling (2b.3)
// tasks can `import { gsap, ScrollTrigger } from "../lib/gsap.js"` without
// re-registering the plugin.
import "./lib/gsap.js"

import { initEasterEggs } from "./easter-eggs/index.js"
import { initTimeline } from "./timeline/index.js"
import { initWhy } from "./why/index.js"

console.info("Bridgetown is loaded!")

initEasterEggs()
initTimeline()
initWhy()
