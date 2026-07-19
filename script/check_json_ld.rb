#!/usr/bin/env ruby
# frozen_string_literal: true

# JSON-LD validity guard. Run after a build with:
#   bin/bridgetown build && ruby script/check_json_ld.rb
# (Precondition: like check_no_js_content.rb, this script inspects an
# existing output/ directory; it does not build the site itself. That
# mirrors how a CI job would call it - a `bin/bridgetown build` step
# first, then this check.)
#
# For every built page under output/, extracts every
# <script type="application/ld+json">...</script> block (emitted by
# src/_components/json_ld.{rb,erb}) and runs it through
# JSON.parse. BLOCKs (exits non-zero), naming the page and the parse
# error, on any block that isn't well-formed JSON. This is the proof that
# the structured-data graph is valid, not just plausible-looking text - a
# corrupt <script type="application/ld+json"> tag would silently break
# Google Rich Results / AI-crawler parsing of the page without the page
# itself looking broken to a human visitor or to check_no_js_content.rb.
#
# Also BLOCKs if the build produced *no* JSON-LD at all - that would mean
# this check has nothing to validate and would pass vacuously, masking a
# real regression (e.g. json_ld.erb no longer wired into _head.erb).

require "json"

OUTPUT_DIR = File.expand_path("../output", __dir__)
SCRIPT_TAG_PATTERN = %r{<script type="application/ld\+json">(.*?)</script>}m

unless Dir.exist?(OUTPUT_DIR)
  warn "check_json_ld.rb: no output/ directory found at #{OUTPUT_DIR}."
  warn "  This check inspects a built site; it does not build one. Run `bin/bridgetown build` first."
  exit 1
end

html_files = Dir.glob(File.join(OUTPUT_DIR, "**", "*.html")).sort
errors = []
blocks_checked = 0
pages_with_json_ld = 0

html_files.each do |path|
  relative_path = path.delete_prefix("#{OUTPUT_DIR}/")
  blocks = File.read(path).scan(SCRIPT_TAG_PATTERN).flatten
  next if blocks.empty?

  pages_with_json_ld += 1

  blocks.each_with_index do |block, index|
    blocks_checked += 1
    begin
      JSON.parse(block)
    rescue JSON::ParserError => e
      label = (blocks.size > 1) ? "#{relative_path} (JSON-LD block #{index + 1})" : relative_path
      errors << "#{label}: malformed JSON-LD (#{e.message})"
    end
  end
end

if blocks_checked.zero? && errors.empty?
  errors << "no <script type=\"application/ld+json\"> blocks were found anywhere under output/ - " \
            "is JsonLd still rendered from src/_partials/_head.erb?"
end

if errors.empty?
  puts "#{blocks_checked} JSON-LD block#{"s" unless blocks_checked == 1} across " \
       "#{pages_with_json_ld} page#{"s" unless pages_with_json_ld == 1} checked, all valid JSON."
  exit 0
else
  warn "check_json_ld.rb found #{errors.size} problem#{"s" unless errors.size == 1}:"
  errors.each { |message| warn "  - #{message}" }
  exit 1
end
