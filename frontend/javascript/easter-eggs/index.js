// the three discoverable easter eggs. Each is enhancement-only -
// none of them create, gate, or move any card fact, prose, or cross-link;
// they're pure additions layered on top of DOM that already exists (see
// script/check_no_js_content.rb, the CI guard for that rule). With
// JavaScript off, none of this module runs and the site is unaffected.

import { initFoxShout } from "./fox-shout.js"
import { initKonamiCode } from "./konami.js"
import { initConsoleGag } from "./console-gag.js"

export function initEasterEggs() {
  initFoxShout()
  initKonamiCode()
  initConsoleGag()
}
