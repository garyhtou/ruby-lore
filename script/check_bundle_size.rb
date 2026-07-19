#!/usr/bin/env ruby
# frozen_string_literal: true

# the JS bundle-size budget guard. Run after a frontend build with:
#   npm run esbuild && ruby script/check_bundle_size.rb
# (Precondition: this script inspects an existing esbuild manifest +
# output/ directory; it does not build anything itself - same pattern as
# the other script/check_*.rb guards.)
#
# Why gzip, not raw minified bytes: gzip (or better) is the realistic
# over-the-wire transfer size for text assets on effectively every static
# host/CDN, and it's what "budget" language like "40KB of JS" conventionally
# means. Computed here with Ruby's stdlib Zlib rather than shelling out to
# `gzip`, so this has zero new dependencies and is deterministic across
# platforms/CI.
#
# Two numbers, two very different jobs (see the report for the full
# rationale + measured Lighthouse numbers):
#   - INITIAL_JS_BUDGET_BYTES guards frontend/javascript/index.js, the ONLY
#     JS every page's initial load pays for. It's a tiny loader (no GSAP) by
#     design - see frontend/javascript/core/load-experience.js - so this
#     ceiling is set with generous headroom over its current ~0.4KB gzipped
#     while still being tight enough to fail loudly if GSAP (or anything
#     comparably heavy) ever gets imported back into index.js by mistake.
#   - EXPERIENCE_JS_BUDGET_BYTES guards frontend/javascript/experience.js,
#     the lazily-loaded bundle (GSAP + ScrollTrigger + the easter eggs +
#     timeline scroll + _why scroll-telling). It never blocks first paint,
#     but an unbounded lazy bundle is still a real cost (time-to-interactive
#     for its own features, mobile data), so it gets a budget too - just a
#     much larger one.
#
# This is deliberately NOT a Lighthouse/performance-timing check: gzip size
# of a committed build output is 100% deterministic given the same source,
# so it's safe to run as a hard CI block (unlike Lighthouse timing metrics,
# which are flaky in shared CI runners) - see the CI workflow.

require "zlib"
require "json"
require "stringio"

ROOT_DIR = File.expand_path("..", __dir__)
MANIFEST_PATH = File.join(ROOT_DIR, ".bridgetown-cache", "frontend-bundling", "manifest.json")
STATIC_DIR = File.join(ROOT_DIR, "output", "_bridgetown", "static")

INITIAL_JS_BUDGET_BYTES = 15 * 1024      # 15KB gzipped - the every-page loader
EXPERIENCE_JS_BUDGET_BYTES = 100 * 1024  # 100KB gzipped - the lazy GSAP bundle

BUDGETS = {
  "javascript/index.js" => {label: "initial-load JS (frontend/javascript/index.js)",
                            budget: INITIAL_JS_BUDGET_BYTES},
  "javascript/experience.js" => {label: "lazy-loaded experience bundle (frontend/javascript/experience.js)",
                                 budget: EXPERIENCE_JS_BUDGET_BYTES}
}.freeze

def gzip_size(path)
  raw = File.binread(path)
  io = StringIO.new
  writer = Zlib::GzipWriter.new(io, Zlib::BEST_COMPRESSION)
  writer.write(raw)
  writer.close
  io.string.bytesize
end

unless File.exist?(MANIFEST_PATH)
  warn "check_bundle_size.rb: no frontend bundling manifest found at #{MANIFEST_PATH}."
  warn "  This check inspects a built frontend bundle; it does not build one. Run `npm run esbuild` first."
  exit 1
end

manifest = JSON.parse(File.read(MANIFEST_PATH))
errors = []
reports = []

BUDGETS.each do |manifest_key, config|
  relative_output = manifest[manifest_key]
  if relative_output.nil?
    errors << "#{config[:label]}: no `#{manifest_key}` entry in the frontend bundling manifest " \
              "(#{MANIFEST_PATH}) - is it still a real esbuild entry point?"
    next
  end

  asset_path = File.join(STATIC_DIR, relative_output)
  unless File.exist?(asset_path)
    errors << "#{config[:label]}: manifest points at #{asset_path}, which doesn't exist. Run `npm run esbuild` first."
    next
  end

  size = gzip_size(asset_path)
  budget = config[:budget]
  reports << {label: config[:label], file: relative_output, size: size, budget: budget}

  next unless size > budget

  errors << "#{config[:label]} is #{size} bytes gzipped, over its #{budget}-byte budget " \
            "(#{relative_output})."
end

reports.each do |r|
  pct = ((r[:size].to_f / r[:budget]) * 100).round(1)
  puts format("%-58s %8d B gzip  (budget %6d B, %5s%%)  %s", r[:label], r[:size], r[:budget], pct, r[:file])
end

if errors.empty?
  puts "\nAll JS bundles within budget."
  exit 0
else
  warn "\ncheck_bundle_size.rb found #{errors.size} problem#{"s" unless errors.size == 1}:"
  errors.each { |message| warn "  - #{message}" }
  exit 1
end
