# frozen_string_literal: true

require "date" # Date/Time are named in YAML.safe_load's permitted_classes below
require "yaml"

# Slugs is the single source of truth for turning the on-disk card
# collection (src/_cards/**/*.md) into an in-memory slug -> metadata map.
#
# It is plain Ruby with no Bridgetown dependency, so it can be required
# from:
#   - script/validate.rb (a standalone script, run outside Bridgetown)
#   - a Bridgetown plugin/builder (the `[[slug]]` -> <a href> transform)
#
# This module only resolves slugs. It does not validate anything (no
# schema/link/source checks) - that belongs to script/validate.rb.
module Slugs
  # Card type -> URL segment, per the site's routing scheme.
  # e.g. src/_cards/people/matz.md (type: person) -> /people/matz/
  TYPE_SEGMENTS = {
    "person" => "people",
    "story" => "stories",
    "talk" => "talks",
    "vocabulary" => "glossary",
    "release" => "timeline"
  }.freeze

  # One entry per card file. `error` is set (and `type`/`title`/`href` left
  # nil) when the file's front matter couldn't be parsed at all, so callers
  # can still see the card exists (and report on it) without crashing.
  Card = Struct.new(:slug, :title, :type, :href, :body, :path, :error)

  FRONT_MATTER_DELIMITER = /^---\s*$/

  module_function

  # Globs src/_cards/**/*.md relative to this file's location (so it works
  # regardless of the caller's working directory), parses each card's YAML
  # front matter, and returns a Hash of slug => Card.
  #
  # `glob` may be overridden (e.g. by tests) to point at a different path.
  def load_cards(glob: default_glob)
    Dir.glob(glob).sort.each_with_object({}) do |path, cards|
      slug = File.basename(path, ".md")
      front_matter, body, error = parse_front_matter(path)

      type = front_matter["type"]
      title = front_matter["title"]
      segment = TYPE_SEGMENTS[type]

      cards[slug] = Card.new(
        slug: slug,
        title: title,
        type: type,
        href: segment ? "/#{segment}/#{slug}/" : nil,
        body: body,
        path: path,
        error: error
      )
    end
  end

  def default_glob
    File.expand_path("../src/_cards/**/*.md", __dir__)
  end

  # Splits a card file into [front_matter_hash, body_string, error_or_nil].
  # front_matter is always a Hash (empty if none/unparseable) so callers
  # never need a nil-guard.
  def parse_front_matter(path)
    content = File.read(path)

    unless content.start_with?("---")
      return [{}, content, nil]
    end

    _, raw_front_matter, body = content.split(FRONT_MATTER_DELIMITER, 3)

    if raw_front_matter.nil?
      return [{}, content, "no closing '---' found for front matter block"]
    end

    parsed = YAML.safe_load(raw_front_matter, permitted_classes: [Date, Time])
    [parsed.is_a?(Hash) ? parsed : {}, body.to_s, nil]
  rescue Psych::SyntaxError, Psych::DisallowedClass => e
    [{}, "", "could not parse YAML front matter: #{e.message}"]
  end
end
