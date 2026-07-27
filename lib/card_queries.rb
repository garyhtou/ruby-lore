# frozen_string_literal: true

# CardQueries is the single source of truth for how the `cards` collection
# is sliced and ordered for the site's index/listing views.
#
# Both sides of every listing page call these:
#   - the ERB templates that render the HTML (src/people.erb, stories.erb,
#     talks.erb, glossary.erb, timeline.erb, index.erb)
#   - the Markdown-counterpart renderer that generates each page's `.md`
#     sibling (lib/markdown_pages_render.rb, via
#     plugins/builders/markdown_pages.rb)
#
# so an HTML page and its `.md` twin can never disagree on WHICH cards
# appear or in WHAT order. That shared selection/sort logic is the whole
# reason the `.md` files are generated from the same card data as the HTML
# rather than by reconverting the rendered HTML back into Markdown.
#
# Every method takes a plain list of card resources (Bridgetown resources
# from `collections.cards.resources`, each responding to `.data.type`,
# `.data.title`, `.data.dates`, and `.data.slug`) and returns a filtered,
# sorted list of the same resources.
#
# Every sort carries `data.slug` as a final tiebreaker. Slugs are unique, so
# the ordering is a TOTAL order and therefore deterministic - it does not
# depend on Ruby's `sort_by` being stable or on the input order. That matters
# because the HTML page and its `.md` twin sort in two separate passes; a
# non-total order could let them break a tie (two equal titles, two equal
# earliest dates) differently and silently disagree.
module CardQueries
  # Home-page editorial pick: the cornerstone why-the-lucky-stiff card first,
  # then a handful of other canon cards as single entry points into the site.
  # A curated set (NOT the ordered tour.yml walk), so it can include cards the
  # tour doesn't, such as tenderlove. Resolved against a slug => card map
  # (collections.cards.resources_by_slug); unknown slugs simply drop out.
  FEATURED_SLUGS = %w[why-the-lucky-stiff matz dhh tenderlove minaswan chunky-bacon].freeze

  # Home-page timeline preview: a deliberately short, hand-picked set of stops
  # that sketch Ruby's whole arc (chosen for span, not recency), rather than
  # every dated card - that is what the full chronology at /timeline/ is for.
  # Resolved by slug and then sorted by earliest date like `dated`, so the
  # preview reads chronologically.
  HOME_TIMELINE_PREVIEW_SLUGS = %w[
    named-before-it-existed
    ruby-1-0
    rails-from-basecamp
    bundler
    ruby-3-0
    ruby-4-0
  ].freeze

  module_function

  # The curated home-page timeline preview (HOME_TIMELINE_PREVIEW_SLUGS),
  # resolved against a slug => card map, keeping only cards that carry dates
  # and ordering them oldest-first (same total order as `dated`).
  def home_timeline_preview(cards_by_slug)
    dated(HOME_TIMELINE_PREVIEW_SLUGS.filter_map { |slug| cards_by_slug[slug] })
  end

  # People / Stories / Talks index views: every card of one type, A-to-Z by
  # title.
  def people(resources)
    of_type_alphabetical(resources, "person")
  end

  def stories(resources)
    of_type_alphabetical(resources, "story")
  end

  def talks(resources)
    of_type_alphabetical(resources, "talk")
  end

  # Glossary: vocabulary cards, A-to-Z. A handful of terms are quoted
  # phrases (e.g. "Optimize for programmer happiness") -- strip the leading
  # non-alphanumerics from the sort key only (not from the display title) so
  # the list reads as a true A-to-Z instead of grouping punctuation-first by
  # ASCII order.
  def vocabulary(resources)
    resources
      .select { |card| card.data.type == "vocabulary" }
      .sort_by { |card| [card.data.title.to_s.downcase.sub(/\A[^a-z0-9]+/, ""), card.data.slug.to_s] }
  end

  # Timeline: every card carrying a `dates:` front-matter entry, oldest first
  # by the card's EARLIEST date. A card could in principle carry more than one
  # `dates` entry, so sort by the minimum rather than assuming the first entry
  # is chronologically first. (home_timeline_preview reuses this to order its
  # curated subset.)
  def dated(resources)
    resources
      .select { |card| card.data.dates.is_a?(Array) && card.data.dates.any? }
      .sort_by { |card| [card.data.dates.map(&:date).min, card.data.slug.to_s] }
  end

  # Resolve FEATURED_SLUGS against a slug => card map, preserving that
  # editorial order and dropping any slug with no matching card.
  def featured(cards_by_slug)
    FEATURED_SLUGS.filter_map { |slug| cards_by_slug[slug] }
  end

  def of_type_alphabetical(resources, type)
    resources
      .select { |card| card.data.type == type }
      .sort_by { |card| [card.data.title.to_s.downcase, card.data.slug.to_s] }
  end
end
