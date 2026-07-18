import build from "./config/esbuild.defaults.js"

// You can customize this as you wish, perhaps to add new esbuild plugins.
//
// ```
// import { copy } from 'esbuild-plugin-copy'
// 
// const esbuildOptions = {
//   plugins: [
//     copy({
//       resolveFrom: 'cwd',
//       assets: {
//         from: ['./node_modules/somepackage/files/*')],
//         to: ['./output/_bridgetown/somepackage/files')],
//       },
//       verbose: false
//     }),
//   ]
// }
// ```
//
// You can also support custom base_path deployments via changing `publicPath`.
//
// ```
// const esbuildOptions = {
//   publicPath: "/my_subfolder/_bridgetown/static",
//   ...
// }
// ```

/**
 * @typedef { import("esbuild").BuildOptions } BuildOptions
 * @type {BuildOptions}
 */
const esbuildOptions = {
  plugins: [
    // add new plugins here...
  ],
  globOptions: {
    excludeFilter: /\.(dsd|lit)\.css$/
  },
  // Perf/CWV: a second entry point for the lazily-loaded
  // "experience" bundle (GSAP + the easter eggs/timeline/_why scroll
  // scenes - see frontend/javascript/experience.js). Keeping it a normal
  // esbuild entry point (rather than a dynamic import()) means it's just
  // another self-contained, hashed, cache-busted file in the frontend
  // bundling manifest - frontend/javascript/core/load-experience.js reads
  // its built URL off a data attribute (see src/_partials/_head.erb) and
  // injects a plain <script> tag for it once idle/interaction fires,
  // instead of shipping it as part of every page's initial load.
  entryPoints: [
    "./frontend/javascript/index.js",
    "./frontend/javascript/experience.js",
  ],
}

build(esbuildOptions)
