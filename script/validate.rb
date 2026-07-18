#!/usr/bin/env ruby
# frozen_string_literal: true

# Plain-Ruby validator for the card content model. Run directly with:
#   ruby script/validate.rb
# (does not require Bridgetown to be built or running).
#
# Checks every card under src/_cards/**/*.md and BLOCKs (exits non-zero)
# if any card has:
#   - a missing or invalid `type` (must be one of ALLOWED_TYPES)
#   - a missing `title`
#   - a [[slug]] wiki-link token that doesn't resolve to another card
#   - no real sources under a `## Sources` heading (a section that's
#     missing entirely, empty, or contains only a bare [VERIFY] marker
#     does not count)
#
# All cards are checked and all problems are reported together (not just
# the first one found), so a single run surfaces everything to fix.

require_relative "../lib/slugs"

ALLOWED_TYPES = %w[person story talk vocabulary release artifact institution book program].freeze
WIKILINK_PATTERN = /\[\[([a-zA-Z0-9_-]+)\]\]/.freeze
SOURCES_HEADING_PATTERN = /^##\s+Sources\s*$/i.freeze
NEXT_HEADING_PATTERN = /^##\s+/.freeze
VERIFY_MARKER_PATTERN = /\[VERIFY\]/i.freeze

# Returns the raw text of the "## Sources" section (everything up to the
# next "##" heading, or end of body), or nil if there's no such section.
def sources_section(body)
  lines = body.to_s.lines
  heading_index = lines.index { |line| line.match?(SOURCES_HEADING_PATTERN) }
  return nil unless heading_index

  lines[(heading_index + 1)..]
    .take_while { |line| !line.match?(NEXT_HEADING_PATTERN) }
    .join
end

# A card has "real" sources if it has a ## Sources section, and that
# section has at least one non-blank line left over once bare [VERIFY]
# markers and list-item punctuation are stripped out.
def real_sources?(body)
  section = sources_section(body)
  return false if section.nil?

  section.lines.any? do |line|
    cleaned = line.gsub(VERIFY_MARKER_PATTERN, "").gsub(/^[\s\-*]+/, "").strip
    !cleaned.empty?
  end
end

cards = Slugs.load_cards
errors = []

cards.each_value do |card|
  location = card.path

  if card.error
    errors << "#{location}: could not read this card (#{card.error})"
    next
  end

  if card.type.nil? || card.type.to_s.strip.empty?
    errors << "#{location}: missing required 'type' field in front matter"
  elsif !ALLOWED_TYPES.include?(card.type)
    errors << "#{location}: invalid 'type' value #{card.type.inspect} " \
              "(must be one of: #{ALLOWED_TYPES.join(', ')})"
  end

  errors << "#{location}: missing required 'title' field in front matter" if card.title.to_s.strip.empty?

  card.body.to_s.scan(WIKILINK_PATTERN).flatten.uniq.each do |linked_slug|
    unless cards.key?(linked_slug)
      errors << "#{location}: [[#{linked_slug}]] does not match any known card slug"
    end
  end

  unless real_sources?(card.body)
    errors << "#{location}: missing sources (no '## Sources' section with real citations found)"
  end
end

if errors.empty?
  puts "#{cards.size} card#{cards.size == 1 ? '' : 's'} validated, all clean."
  exit 0
else
  warn "validate.rb found #{errors.size} problem#{errors.size == 1 ? '' : 's'}:"
  errors.each { |message| warn "  - #{message}" }
  exit 1
end
