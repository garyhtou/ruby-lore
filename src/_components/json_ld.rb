require "json"

# Renders the site's schema.org structured-data graph for the current
# page as a single <script type="application/ld+json"> tag (see
# json_ld.erb). Every page gets a site-wide `WebSite` + `Organization`
# pair (repeated per-page rather than de-duplicated - each page's JSON-LD
# document is meant to be self-contained, and repeating two small nodes
# is simpler and safer than cross-page reference bookkeeping). Card pages
# additionally get:
#   - a page-level `Article` node (headline/description/url, `author` and
#     `publisher` both referencing the Organization via `@id`)
#   - PLUS, for every card `type` whose schema.org mapping differs from
#     that default Article shape (person/vocabulary/talk/release), a
#     second, more specific node - Person / DefinedTerm / CreativeWork /
#     Event - linked back to the Article via `about: { "@id": ... }`.
#     `story` cards map to Article too (the brief's own safe default), so
#     for `story` there is nothing to add beyond the page node itself -
#     emitting a second, identical "Article about an Article" node would
#     be pure duplication.
#   - vocabulary cards additionally get a shared `DefinedTermSet` node
#     (glossary_set_node) that every glossary card's DefinedTerm points
#     to via `inDefinedTermSet`.
#
# JSON safety: the Hash graph below is handed to `JSON.generate` (never
# hand-written/interpolated JSON string literals), which guarantees
# syntactically valid, correctly string-escaped JSON. json_ld.erb then
# outputs the result with the raw `<%==` tag (bypassing HTML-escaping,
# same convention as card.erb's body_html) - see `safe_json` below for
# why that's still safe to embed inside a <script> element.
#
# LICENSE: deliberately never asserted. The site's license is a
# post-build decision (still TBD as of this task) - no node here ever
# sets a `license` property. Wire one in once a real LICENSE file lands;
# asserting CC-BY or similar ahead of that would be inventing a fact.
#
# R31 (anonymity constraint - see the why-the-lucky-stiff card and
# .superpowers/sdd/task-3.2-brief.md): the Person node's `sameAs` is
# built ONLY from that card's own front-matter `sources:` list - never
# from an external identity registry (no Wikipedia/Wikidata/etc. lookup
# happens anywhere in this file, for any person). There is no
# _why-specific code path or name denylist here; every `person` card is
# handled by the exact same generic line. That's safe *because* the
# why-the-lucky-stiff card's own `sources:` front matter is already
# curated to be name-respectful (poignantguide.net, whymirror.github.io,
# whyday.org, viewsourcecode.org/why/, the Smashing Magazine profile
# verified not to state the name, and the CLOSURE repo) - the card
# deliberately omits the Wikipedia/Slate links that would reveal the
# identity (see that card's own "## Sources" note). Mirroring
# front-matter sources into `sameAs` can never introduce anything the
# card doesn't already cite in its own visible body.
class JSONLd < Bridgetown::Component
  PER_TYPE_SCHEMA = {
    "person" => "Person",
    "vocabulary" => "DefinedTerm",
    "story" => "Article",
    "talk" => "CreativeWork",
    "release" => "Event",
  }.freeze

  # @param metadata [HashWithDotAccess::Hash] site.metadata (site_metadata.yml)
  # @param resource [Bridgetown::Resource::Base, nil] the current page's resource
  # @param site_url [String] the canonical site origin, e.g. "https://chunkybacon.dev"
  def initialize(metadata:, resource:, site_url:)
    @metadata = metadata
    @resource = resource
    @site_url = site_url.to_s.chomp("/")
    @json = safe_json({ "@context" => "https://schema.org", "@graph" => graph_nodes })
  end

  private

  attr_reader :json

  def graph_nodes
    nodes = [website_node, organization_node]
    nodes.concat(card_nodes) if card_resource?
    nodes
  end

  def card_resource?
    !!(@resource && @resource.respond_to?(:collection) && @resource.collection&.label == "cards")
  end

  def website_id
    "#{@site_url}/#website"
  end

  def organization_id
    "#{@site_url}/#organization"
  end

  def glossary_set_id
    "#{@site_url}/glossary/#glossary-terms"
  end

  def website_node
    {
      "@type" => "WebSite",
      "@id" => website_id,
      "name" => @metadata.title.to_s,
      "description" => site_description,
      "url" => @site_url,
      "publisher" => { "@id" => organization_id },
    }
  end

  def organization_node
    node = {
      "@type" => "Organization",
      "@id" => organization_id,
      "name" => @metadata.title.to_s,
      "url" => @site_url,
    }
    repo_url = @metadata.repo_url.to_s.strip
    node["sameAs"] = [repo_url] unless repo_url.empty?
    node
  end

  def site_description
    tagline = @metadata.tagline.to_s.strip
    return tagline unless tagline.empty?

    @metadata.description.to_s.strip
  end

  def card_nodes
    data = @resource.data
    mapped_type = PER_TYPE_SCHEMA[data.type.to_s]
    return [] unless mapped_type

    page_url = @resource.absolute_url
    title = data.title.to_s
    description = description_for(data)

    page_node = {
      "@type" => "Article",
      "@id" => "#{page_url}#webpage",
      "headline" => title,
      "url" => page_url,
      "author" => { "@id" => organization_id },
      "publisher" => { "@id" => organization_id },
    }
    page_node["description"] = description if description

    return [page_node] if mapped_type == "Article" # story: nothing more specific to add

    subject_id = "#{page_url}#entity"
    subject_node = {
      "@type" => mapped_type,
      "@id" => subject_id,
      "name" => title,
      "url" => page_url,
    }
    subject_node["description"] = description if description
    extra_nodes = apply_type_specifics(mapped_type, data, subject_node)

    page_node["about"] = { "@id" => subject_id }

    [page_node, subject_node, *extra_nodes]
  end

  # Adds type-specific fields onto subject_node in place, and returns any
  # additional sibling nodes that type needs (currently just the shared
  # DefinedTermSet for vocabulary cards).
  def apply_type_specifics(mapped_type, data, subject_node)
    case mapped_type
    when "Person"
      same_as = same_as_from_sources(data)
      subject_node["sameAs"] = same_as unless same_as.empty?
      []
    when "DefinedTerm"
      subject_node["inDefinedTermSet"] = { "@id" => glossary_set_id }
      [glossary_set_node]
    when "Event"
      start_date = earliest_date(data)
      subject_node["startDate"] = start_date.iso8601 if start_date
      []
    else # "CreativeWork" (talk) - the shared base fields are enough
      []
    end
  end

  # See the class comment's R31 section: this is the ONLY place `sameAs`
  # is populated for a Person node, and it is a plain mirror of the
  # card's own front-matter `sources:` - identical code path for every
  # person card, no name-specific branching.
  def same_as_from_sources(data)
    Array(data.sources).map { |source| source.url.to_s.strip }.reject(&:empty?).uniq
  end

  def earliest_date(data)
    dates = Array(data.dates).filter_map { |entry| entry.date if entry.respond_to?(:date) }
    dates.min
  end

  def glossary_set_node
    {
      "@type" => "DefinedTermSet",
      "@id" => glossary_set_id,
      "name" => "#{@metadata.title} Glossary",
      "description" => "Ruby community vocabulary and folklore terms defined by #{@metadata.title}.",
      "url" => "#{@site_url}/glossary/",
      "publisher" => { "@id" => organization_id },
    }
  end

  def description_for(data)
    summary = data.summary.to_s.strip
    return summary unless summary.empty?

    hook = data.hook.to_s.strip
    hook.empty? ? nil : hook
  end

  # JSON.generate on a plain Hash (never hand-interpolated ERB/string
  # concatenation) guarantees syntactically valid, correctly escaped JSON.
  # The gsubs below are the standard extra hardening step for embedding
  # JSON inside an HTML <script> element: JSON.generate is free to emit
  # the literal 3-character sequence "</" (e.g. as part of an ordinary
  # source URL), and if an HTML parser ever sees that sequence followed
  # by "script" it ends the <script> tag right there - truncating (and
  # potentially escaping content out of) the JSON. `<`, `>`, and `&` are
  # replaced with their JSON-legal \uXXXX escapes (JSON allows \uXXXX
  # escapes anywhere inside a string), which makes producing "</script>"
  # or "<!--" impossible without changing the JSON's meaning at all.
  def safe_json(hash)
    JSON.generate(hash)
        .gsub("<", "\\u003c")
        .gsub(">", "\\u003e")
        .gsub("&", "\\u0026")
  end
end
