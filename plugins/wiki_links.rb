# frozen_string_literal: true

require_relative "../lib/slugs"

# WikiLinks turns `[[slug]]` tokens inside card bodies into real
# `<a href="...">Title</a>` links, then wraps each card's (now
# slug-substituted) body in `{% raw %}...{% endraw %}` so that anything else
# in the prose - `{{ }}`/`{% %}` inside Ruby/Rails code samples, for example
# - survives Liquid rendering verbatim instead of being misinterpreted as
# Liquid syntax. (Cards render through the Liquid template engine per the
# `defaults` scope in bridgetown.config.yml.)
#
# This is implemented as a `hook :site, :post_read`, registered from `build`
# below per the SiteBuilder DSL. `:post_read` fires exactly once, after every
# resource (cards included) has been read from disk but before anything
# renders - so by the time this hook runs, `resource.content` is the raw
# Markdown/Liquid body, untouched by Liquid or Markdown conversion.
#
# The slug -> {title, href} map comes from a *filesystem glob* of
# src/_cards/**/*.md via lib/slugs.rb (the same resolver script/validate.rb
# already uses) rather than from live Bridgetown collection state.
# That keeps the map complete regardless of resource read order, and keeps
# this transform and validate.rb from ever disagreeing about what counts as
# a valid slug.
#
# An unresolved `[[slug]]` - one whose slug isn't in the glob-derived map -
# raises and aborts the build. It must never be left as literal `[[text]]`
# or silently dropped: script/validate.rb would catch it too, but this hook
# runs first (as part of `bin/bridgetown build`), so it's the first line of
# defense.
class WikiLinks < SiteBuilder
  WIKILINK_PATTERN = /\[\[([a-zA-Z0-9_-]+)\]\]/

  def build
    hook :site, :post_read do
      cards = Slugs.load_cards
      site.collections.cards.resources.each do |resource|
        resource.content = wrap_in_raw(resolve_wikilinks(resource.content, cards, resource))
      end
    end
  end

  private

  # Replaces every `[[slug]]` token with rendered `card_link` HTML. Raises
  # with the offending file's path if a slug doesn't resolve.
  def resolve_wikilinks(content, cards, resource)
    content.gsub(WIKILINK_PATTERN) do
      slug = Regexp.last_match(1)
      card = cards[slug]

      if card.nil? || card.error || card.href.nil? || card.title.nil?
        raise "WikiLinks: [[#{slug}]] in #{resource.relative_path} does not " \
              "resolve to a known card slug (checked against " \
              "src/_cards/**/*.md via lib/slugs.rb)"
      end

      Bridgetown::TemplateView.render(CardLink.new(title: card.title, href: card.href)).chomp
    end
  end

  def wrap_in_raw(content)
    "{% raw %}#{content}{% endraw %}"
  end
end
