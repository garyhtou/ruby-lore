# frozen_string_literal: true

require_relative "card_queries"
require_relative "markdown_pages_url"

# Renders the Markdown body for a page's `.md` counterpart (see
# plugins/builders/markdown_pages.rb, which calls this and writes the
# result to disk).
#
# Every `.md` file is generated from the SAME source the HTML page renders
# from - never by reconverting the page's rendered HTML back into Markdown.
# Two strategies, chosen per resource:
#
#   - card_markdown: for `cards` collection resources (person/story/talk/
#     vocabulary/release). Built straight from the card's own front matter
#     and its RAW source Markdown body (via Slugs.load_cards, the same
#     glob-of-src/_cards-on-disk resolver script/validate.rb and
#     plugins/wiki_links.rb already use) rather than the rendered HTML.
#     This matters: by the time this runs (a `:site, :post_write` hook,
#     i.e. after everything has rendered), plugins/wiki_links.rb has
#     already rewritten `resource.content` in place - `[[slug]]` tokens
#     are gone, replaced with rendered `<a href>` HTML. Re-reading the
#     pristine source and doing our own (Markdown-flavored) wikilink
#     resolution gets an exact match for the author's original Markdown -
#     real emphasis, links, and the "## Sources" section entirely intact.
#
#   - page_markdown: for the hand-built index/listing pages (home, the five
#     card-type index views, Start Here, Credits). These have no single
#     source Markdown body to reuse, so each has a small builder here that
#     assembles its Markdown from the SAME card data (via CardQueries) and
#     site data the ERB template renders from. That shared selection/sort
#     logic is why an HTML listing page and its `.md` twin can never
#     disagree on which cards appear or in what order.
module MarkdownPagesRender
  WIKILINK_PATTERN = /\[\[([a-zA-Z0-9_-]+)\]\]/
  CONTENT_LICENSE_LINE = "License: CC BY 4.0 (https://creativecommons.org/licenses/by/4.0/)"

  # relative_url => builder method for every eligible non-card page. Every
  # such page MUST have an entry (page_markdown raises otherwise), so a newly
  # added listing page can't silently ship without a Markdown counterpart.
  PAGE_BUILDERS = {
    "/" => :home_body,
    "/people/" => :people_body,
    "/stories/" => :stories_body,
    "/talks/" => :talks_body,
    "/glossary/" => :glossary_body,
    "/timeline/" => :timeline_body,
    "/start-here/" => :start_here_body,
    "/credits/" => :credits_body
  }.freeze

  # Home hero intro, kept verbatim from src/index.erb (the copy is the site's
  # own). The one difference is the link target: the HTML points at
  # /start-here/, the Markdown at its /start-here.md counterpart, so this
  # can't be a single shared string - the link differs by format.
  HOME_INTRO =
    "A collection of the people, stories, talks, and words that make up " \
    "Ruby's history, the kind of thing a longtime Rubyist would tell " \
    "you over coffee. New here? [Start here](%<start_here>s) for a guided " \
    "walk through it all."

  module_function

  def card_markdown(resource, cards, site_url)
    data = resource.data
    card = cards[File.basename(resource.relative_path.to_s, ".md")]
    raw_body = (card && !card.error) ? card.body.to_s : resource.content.to_s

    parts = [display_title(data.title)]

    hook = data.hook.to_s.strip
    parts << "> #{hook}" unless hook.empty?

    date_block = dates_block(data.dates)
    parts << date_block if date_block

    parts << resolve_wikilinks(raw_body, cards, site_url).strip
    parts << footer_block(resource)

    join_blocks(parts)
  end

  # Hand-built index/listing pages. Dispatched by relative_url to a builder
  # that assembles the body from card + site data, then wrapped with the
  # shared Source/License footer.
  def page_markdown(resource, site, site_url)
    builder = PAGE_BUILDERS[resource.relative_url.to_s]
    unless builder
      raise "MarkdownPagesRender: no Markdown builder registered for " \
            "#{resource.relative_url.inspect}. Add one to " \
            "MarkdownPagesRender::PAGE_BUILDERS."
    end

    body = send(builder, resource, site, site_url)
    join_blocks([body.strip, footer_block(resource)])
  end

  # --- Page builders ---------------------------------------------------

  def home_body(_resource, site, site_url)
    by_slug = site.collections.cards.resources_by_slug

    preview = CardQueries.home_timeline_preview(by_slug).each_with_index.map do |card, i|
      "#{i + 1}. #{date_display(card)} #{card_link(card, site_url)}"
    end

    featured = CardQueries.featured(by_slug)

    blocks(
      "# #{site.metadata.title}",
      site.metadata.tagline,
      format(HOME_INTRO, start_here: absolute_md_url("/start-here/", site_url)),
      "## The short version, in time",
      preview.join("\n"),
      "[See the full timeline →](#{absolute_md_url("/timeline/", site_url)})",
      "## A few places to start",
      bullet_list(featured, site_url)
    )
  end

  def people_body(resource, site, site_url)
    listing(resource, CardQueries.people(cards(site)), site_url)
  end

  def stories_body(resource, site, site_url)
    listing(resource, CardQueries.stories(cards(site)), site_url)
  end

  def talks_body(resource, site, site_url)
    listing(resource, CardQueries.talks(cards(site)), site_url)
  end

  def glossary_body(resource, site, site_url)
    listing(resource, CardQueries.vocabulary(cards(site)), site_url)
  end

  def timeline_body(resource, site, site_url)
    lines = CardQueries.dated(cards(site)).each_with_index.map do |card, i|
      hook_suffix(card, "#{i + 1}. #{date_display(card)} #{card_link(card, site_url)}")
    end

    blocks("# #{resource.data.title}", resource.data.lead, lines.join("\n"))
  end

  def start_here_body(resource, site, site_url)
    by_slug = site.collections.cards.resources_by_slug
    # script/validate.rb fails the build if any tour slug doesn't resolve, so
    # filter_map never actually drops an entry here - it just keeps this
    # robust if that guard is ever removed. (The HTML view in
    # src/start-here.erb renders a visible placeholder for an unresolved
    # slug; the guard is what keeps the two from diverging on that path.)
    tour_cards = Array(site.data.tour).filter_map { |slug| by_slug[slug] }

    lines = tour_cards.each_with_index.map do |card, i|
      hook_suffix(card, "#{i + 1}. #{card_link(card, site_url)}")
    end

    blocks("# #{resource.data.title}", resource.data.lead, lines.join("\n"))
  end

  def credits_body(resource, site, site_url)
    blocks(
      "# #{resource.data.title}",
      resource.data.lead,
      internal_links_to_md(site.data.credits.body.to_s, site_url)
    )
  end

  # --- Building blocks -------------------------------------------------

  # A "# Title / lead / bulleted list" body for the type-index pages
  # (people, stories, talks, glossary). The bullet shape itself
  # ("- [Title](md): hook") comes from bullet_list, which the home page's
  # featured list also uses directly (see home_body).
  def listing(resource, cards_list, site_url)
    blocks("# #{resource.data.title}", resource.data.lead, bullet_list(cards_list, site_url))
  end

  def bullet_list(cards_list, site_url)
    cards_list.map { |card| hook_suffix(card, "- #{card_link(card, site_url)}") }.join("\n")
  end

  def cards(site)
    site.collections.cards.resources
  end

  # "[Title](absolute .md url)" for a card resource.
  def card_link(card, site_url)
    "[#{card.data.title}](#{absolute_md_url(card.relative_url.to_s, site_url)})"
  end

  # Append ": hook" to a line unless the card has no hook.
  def hook_suffix(card, line)
    hook = card.data.hook.to_s.strip
    hook.empty? ? line : "#{line}: #{hook}"
  end

  # Human-readable earliest date for a dated card, mirroring the display
  # logic in src/timeline.erb / src/index.erb: year-only-precision dates
  # (e.g. "the Pickaxe, around 2000") render just the year rather than a
  # false-precise full date.
  def date_display(card)
    entry = card.data.dates.min_by(&:date)
    year_only = entry.respond_to?(:precision) && entry.precision.to_s == "year"
    year_only ? entry.date.strftime("%Y") : entry.date.strftime("%B %-d, %Y")
  end

  # Absolute URL to a page's `.md` counterpart, e.g. "/people/matz/" =>
  # "https://chunkybacon.dev/people/matz.md".
  def absolute_md_url(path, site_url)
    "#{site_url.to_s.chomp("/")}#{MarkdownPagesUrl.relative_md_url_for_path(path)}"
  end

  # Rewrite root-relative internal Markdown links "](/foo/)" to point at the
  # target's absolute `.md` counterpart, so an agent following a link out of
  # a `.md` page stays in Markdown. External links (https://...) are left
  # untouched. Deliberately narrow: it assumes a plain "](/path/)" link, so
  # it is NOT safe for internal images (`![](/x.png)`), anchor-only targets
  # (`/x/#frag`), or titled links (`](/x/ "t")`). Used only for the
  # hand-authored Credits body, whose sole internal link is to the _why card;
  # revisit if that body ever gains one of those forms.
  def internal_links_to_md(markdown, site_url)
    markdown.gsub(/\]\((\/[^)]*)\)/) do
      "](#{absolute_md_url(Regexp.last_match(1), site_url)})"
    end
  end

  def display_title(title)
    "# #{title}"
  end

  def dates_block(dates)
    entries = Array(dates)
    return nil if entries.empty?

    entries.map { |entry| "- #{date_line(entry)}" }.join("\n")
  end

  def date_line(entry)
    date = entry.date
    label = entry.label.to_s.strip
    year_only = entry.respond_to?(:precision) && entry.precision.to_s == "year"
    display = year_only ? date.strftime("%Y") : date.strftime("%B %-d, %Y")
    label.empty? ? display : "#{display}: #{label}"
  end

  # Same substitution plugins/wiki_links.rb performs, but emitting a plain
  # Markdown link to the target card's OWN `.md` counterpart, not its HTML
  # page - so an agent following a cross-reference from one card's
  # Markdown to another stays in clean Markdown the whole way through,
  # rather than getting bounced back into HTML mid-chain.
  def resolve_wikilinks(body, cards, site_url)
    body.gsub(WIKILINK_PATTERN) do
      slug = Regexp.last_match(1)
      target = cards[slug]
      if target && !target.error && target.href && target.title
        "[#{target.title}](#{site_url.to_s.chomp("/")}#{MarkdownPagesUrl.relative_md_url_for_path(target.href)})"
      else
        Regexp.last_match(0) # leave unresolved tokens as-is; validate.rb's problem, not this one's
      end
    end
  end

  def footer_block(resource)
    "---\n\nSource: #{resource.absolute_url}\n#{CONTENT_LICENSE_LINE}"
  end

  # Join non-empty parts with blank lines between them. `blocks` returns the
  # body with no trailing newline (for further composition); `join_blocks`
  # adds the single trailing newline every generated `.md` file ends with.
  def blocks(*parts)
    parts.map(&:to_s).reject { |block| block.strip.empty? }.join("\n\n").strip
  end

  def join_blocks(parts)
    "#{blocks(*parts)}\n"
  end
end
