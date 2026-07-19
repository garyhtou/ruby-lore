require "json"
require_relative "../../lib/slugs"

# Renders the site's schema.org structured-data graph for the current
# page as a single <script type="application/ld+json"> tag (see
# json_ld.erb). Every page gets a site-wide `WebSite` + `Organization`
# pair (repeated per-page rather than de-duplicated - each page's JSON-LD
# document is meant to be self-contained, and repeating two small nodes
# is simpler and safer than cross-page reference bookkeeping). Card pages
# additionally get:
#   - a page-level `Article` node (headline/description/url/image/dates,
#     `author` and `publisher` both referencing the Organization via
#     `@id`), plus a `BreadcrumbList` node mirroring the visual breadcrumb
#     trail (Home -> type segment -> card title)
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
#     to via `inDefinedTermSet`. The /glossary/ index page itself emits a
#     FULLY populated version of that same `@id` (`hasDefinedTerm` listing
#     every glossary term) - see `full_glossary_set_node` - so there is one
#     canonical, machine-readable "whole glossary" resource.
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
# built ONLY from that card's own front-matter `sources:` list, PLUS an
# OPTIONAL `identity_urls:` front-matter list a card can opt into (used
# for openly-public figures like Matz/DHH to add an authoritative
# Wikipedia/Wikidata `sameAs` - see `same_as_for_person` below) - never
# from an external identity registry looked up BY this file. There is no
# _why-specific code path or name denylist here; every `person` card is
# handled by the exact same generic merge of `sources:` + `identity_urls:`.
# That's safe *because* the why-the-lucky-stiff card's own `sources:`
# front matter is already curated to be name-respectful (poignantguide.net,
# whymirror.github.io, whyday.org, viewsourcecode.org/why/, the Smashing
# Magazine profile verified not to state the name, and the CLOSURE repo)
# and it simply never sets `identity_urls:` - the card deliberately omits
# the Wikipedia/Slate links that would reveal the identity (see that
# card's own "## Sources" note). Mirroring front-matter sources into
# `sameAs` can never introduce anything the card doesn't already cite in
# its own visible body; `identity_urls:` is a plain per-card opt-in, not a
# lookup, so a card that never sets it (like why-the-lucky-stiff's) is
# never touched by this feature at all.
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
    nodes << full_glossary_set_node if glossary_index_resource?
    nodes
  end

  def card_resource?
    !!(@resource && @resource.respond_to?(:collection) && @resource.collection&.label == "cards")
  end

  # The /glossary/ view page (src/glossary.erb) - a regular page, not a
  # card - is the one place we emit the FULLY populated DefinedTermSet
  # (fix #5). Identified by its resolved URL rather than by title text so
  # it stays correct even if the page's title copy changes.
  def glossary_index_resource?
    !!(@resource && !card_resource? && @resource.respond_to?(:relative_url) &&
       @resource.relative_url == "/glossary/")
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
      "inLanguage" => "en",
      "publisher" => { "@id" => organization_id },
      "creator" => {
        "@type" => "Person",
        "name" => "Gary Tou",
        "url" => "https://garytou.com",
        "sameAs" => ["https://garytou.com"],
      },
    }
  end

  def organization_node
    node = {
      "@type" => "Organization",
      "@id" => organization_id,
      "name" => @metadata.title.to_s,
      "url" => @site_url,
    }
    # sameAs collects other URLs that identify this same entity: the public
    # source repo and rubylore.dev, the site's secondary official domain
    # (it 301-redirects to the canonical chunkybacon.dev, but is declared
    # here so search/AI recognize it as an official alternate).
    same_as = []
    repo_url = @metadata.repo_url.to_s.strip
    same_as << repo_url unless repo_url.empty?
    same_as << "https://rubylore.dev"
    node["sameAs"] = same_as unless same_as.empty?
    node
  end

  def site_description
    tagline = @metadata.tagline.to_s.strip
    return tagline unless tagline.empty?

    @metadata.description.to_s.strip
  end

  # Same absolute share-image URL src/_partials/_head.erb computes for
  # og:image/twitter:image (a single site-wide 1200x630 raster for v1 -
  # per-page images are a later, optional enhancement). Duplicated here
  # rather than extracted into a shared helper because it's a one-line
  # formula and _head.erb isn't a Ruby object this component can reach
  # into; if per-page OG images ever land, update both call sites.
  def share_image_url
    "#{@site_url}/images/og-share.png"
  end

  def card_nodes
    data = @resource.data
    mapped_type = PER_TYPE_SCHEMA[data.type.to_s]
    return [] unless mapped_type

    page_url = @resource.absolute_url
    title = data.title.to_s
    description = description_for(data)
    published_at, modified_at = git_dates(@resource)

    page_node = {
      "@type" => "Article",
      "@id" => "#{page_url}#webpage",
      "headline" => title,
      "url" => page_url,
      "image" => share_image_url,
      "inLanguage" => "en",
      "author" => { "@id" => organization_id },
      "publisher" => { "@id" => organization_id },
    }
    page_node["description"] = description if description
    page_node["datePublished"] = published_at if published_at
    page_node["dateModified"] = modified_at if modified_at

    breadcrumb_node = breadcrumb_list_node(data, page_url, title)

    return [page_node, breadcrumb_node] if mapped_type == "Article" # story: nothing more specific to add

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

    [page_node, breadcrumb_node, subject_node, *extra_nodes]
  end

  # BreadcrumbList mirroring the real visual breadcrumb trail rendered by
  # src/_partials/_breadcrumbs.erb: Home -> <type segment> -> <card
  # title>. Uses the exact same type -> URL-segment map as the breadcrumb
  # partial and lib/slugs.rb (Slugs::TYPE_SEGMENTS), and the segment's
  # display label is just that segment capitalized ("people" -> "People",
  # "glossary" -> "Glossary", ...) - which is exactly what the breadcrumb
  # partial's own label map already spells out per type, so there's
  # nothing to keep in sync beyond the shared segment map itself.
  def breadcrumb_list_node(data, page_url, title)
    segment = Slugs::TYPE_SEGMENTS[data.type.to_s]

    items = [
      { "@type" => "ListItem", "position" => 1, "name" => "Home", "item" => "#{@site_url}/" },
    ]
    if segment
      items << {
        "@type" => "ListItem",
        "position" => 2,
        "name" => segment.capitalize,
        "item" => "#{@site_url}/#{segment}/",
      }
    end
    items << {
      "@type" => "ListItem",
      "position" => items.length + 1,
      "name" => title,
      "item" => page_url,
    }

    {
      "@type" => "BreadcrumbList",
      "@id" => "#{page_url}#breadcrumb",
      "itemListElement" => items,
    }
  end

  # Adds type-specific fields onto subject_node in place, and returns any
  # additional sibling nodes that type needs (currently just the shared
  # DefinedTermSet for vocabulary cards).
  def apply_type_specifics(mapped_type, data, subject_node)
    case mapped_type
    when "Person"
      same_as = same_as_for_person(data)
      subject_node["sameAs"] = same_as unless same_as.empty?
      []
    when "DefinedTerm"
      subject_node["inDefinedTermSet"] = { "@id" => glossary_set_id }
      [glossary_set_node]
    when "Event"
      # Fix #4: a release Event needs `location` to be Rich-Results
      # eligible. A software release isn't a physical happening, so model
      # it honestly as a VirtualLocation (the release's own Ruby Lore
      # page - a stable, dereferenceable URL for "where this release was
      # announced/lives"), plus the attendance-mode/status pair Google
      # expects alongside `location` on an Event.
      start_date = earliest_date(data)
      subject_node["startDate"] = start_date.iso8601 if start_date
      subject_node["eventAttendanceMode"] = "https://schema.org/OnlineEventAttendanceMode"
      subject_node["eventStatus"] = "https://schema.org/EventScheduled"
      subject_node["location"] = { "@type" => "VirtualLocation", "url" => subject_node["url"] }
      []
    else # "CreativeWork" (talk) - the shared base fields are enough
      []
    end
  end

  # See the class comment's R31 section: this is the ONLY place `sameAs`
  # is populated for a Person node. It's a plain merge of the card's own
  # front-matter `sources:` (as before) with an OPTIONAL `identity_urls:`
  # list - identical code path for every person card, no name-specific
  # branching. A card that never sets `identity_urls:` (why-the-lucky-stiff's)
  # gets exactly the same `sameAs` it always did.
  def same_as_for_person(data)
    urls = Array(data.sources).map { |source| source.url.to_s.strip }
    urls += Array(data.identity_urls).map { |url| url.to_s.strip }
    urls.reject(&:empty?).uniq
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

  # Fix #5: the /glossary/ index page's own DefinedTermSet node, fully
  # populated with `hasDefinedTerm` so there's one canonical,
  # machine-readable "whole glossary" resource for AI/search - as opposed
  # to `glossary_set_node` above (used on individual card pages purely as
  # a lightweight `inDefinedTermSet` reference target). Same `@id` as
  # every card's reference, so the two stay consistent; each page's
  # JSON-LD document remains self-contained (this class's own stated
  # convention) by inlining full DefinedTerm entries rather than dangling
  # cross-page `@id`-only references.
  def full_glossary_set_node
    terms = @resource.site.collections["cards"].resources
                      .select { |card| card.data.type.to_s == "vocabulary" }
                      .sort_by { |card| card.data.title.to_s.downcase.sub(/\A[^a-z0-9]+/, "") }
                      .map { |card| defined_term_entry(card) }

    node = glossary_set_node
    node["hasDefinedTerm"] = terms
    node
  end

  def defined_term_entry(card)
    url = card.absolute_url
    entry = {
      "@type" => "DefinedTerm",
      "@id" => "#{url}#entity",
      "name" => card.data.title.to_s,
      "url" => url,
    }
    description = description_for(card.data)
    entry["description"] = description if description
    entry
  end

  def description_for(data)
    summary = data.summary.to_s.strip
    return summary unless summary.empty?

    hook = data.hook.to_s.strip
    hook.empty? ? nil : hook
  end

  # Fix #1: `datePublished`/`dateModified` are GIT-DERIVED (first/last
  # commit touching the card's source file), never the card's `dates:`
  # front matter - that field holds HISTORICAL event dates (e.g. a 1993
  # milestone), which is the Event/timeline date, not when this Ruby Lore
  # *article* was written. Mirrors the idea bridgetown-sitemap already
  # uses for sitemap.xml lastmod (see its GitInspector, which also shells
  # out to `git log` for a resource's file). Returns [nil, nil] (rather
  # than crashing, or fabricating a date) when git/history isn't
  # available - e.g. a file that's been created but not yet committed, or
  # a checkout with no .git at all.
  def git_dates(resource)
    root = resource.site.root_dir
    rel_path = "src/#{resource.relative_path}"
    return [nil, nil] unless File.exist?(File.join(root, rel_path))

    published = first_commit_date(root, rel_path)
    modified = last_commit_date(root, rel_path)
    [published, modified]
  rescue StandardError
    [nil, nil]
  end

  def first_commit_date(root, rel_path)
    output = run_git(root, ["log", "--diff-filter=A", "--follow", "--format=%aI", "--", rel_path])
    line = output.lines.last&.strip
    line.nil? || line.empty? ? nil : line
  end

  def last_commit_date(root, rel_path)
    output = run_git(root, ["log", "-1", "--format=%aI", "--", rel_path])
    line = output.lines.first&.strip
    line.nil? || line.empty? ? nil : line
  end

  def run_git(root, args)
    IO.popen(["git", "-C", root.to_s, *args], err: File::NULL, &:read).to_s
  rescue Errno::ENOENT, IOError, SystemCallError
    ""
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
