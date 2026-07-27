# frozen_string_literal: true

require "fileutils"
require_relative "../../lib/slugs"
require_relative "../../lib/markdown_pages_url"
require_relative "../../lib/markdown_pages_render"

# MarkdownPages generates a static Markdown counterpart for every real
# content page - the site's answer to "Markdown for Agents" content
# negotiation.
#
# The usual way to serve an agent a Markdown version of a page is Accept-
# header content negotiation: the same URL returns text/html to a browser
# and text/markdown to an agent that asks for it (this is what Cloudflare's
# orange-cloud "Markdown for Agents" feature, or a server/edge-function
# layer, would do). Ruby Lore is intentionally static, deployed to GitHub
# Pages behind grey-cloud (DNS-only, unproxied) Cloudflare DNS - there is no
# server or proxy in front of it to inspect an Accept header. Per-request
# negotiation isn't available on this hosting, and changing that is out of
# scope.
#
# The static, hosting-compatible equivalent - and what this builder does -
# is give every page a SEPARATE, predictable, discoverable URL that's
# already Markdown: a page at `/people/matz/` also gets `/people/matz.md`
# (the home page gets `/index.md`). GitHub Pages serves `.md` files as
# `text/markdown` by default, so fetching that URL directly satisfies the
# same intent as content negotiation would have. See MarkdownPagesUrl for
# the exact URL scheme (shared with src/_partials/_head.erb, which
# advertises each page's `.md` counterpart via `<link rel="alternate">`),
# and MarkdownPagesRender for how each page's Markdown body is produced.
#
# This runs as a `:site, :post_write` hook - after every HTML page has
# rendered AND been written to output/ - so that:
#   - every resource is fully resolved (front matter, permalink/relative_url,
#     absolute_url) and the whole `cards` collection is queryable, which is
#     all MarkdownPagesRender needs: it builds each `.md` from card + site
#     data, never from the page's rendered HTML
#   - `site.dest` is a real, already-created directory tree to write
#     sibling `.md` files into
class Builders::MarkdownPages < SiteBuilder
  def build
    hook :site, :post_write do
      cards = Slugs.load_cards
      site_url = site.config.url

      site.resources.each do |resource|
        next unless MarkdownPagesUrl.eligible?(resource)

        markdown = if card_resource?(resource)
          MarkdownPagesRender.card_markdown(resource, cards, site_url)
        else
          MarkdownPagesRender.page_markdown(resource, site, site_url)
        end

        write_markdown_file(resource, markdown)
      end
    end
  end

  private

  def card_resource?(resource)
    resource.collection&.label == "cards"
  end

  def write_markdown_file(resource, markdown)
    destination = File.join(site.dest, MarkdownPagesUrl.relative_md_url(resource))
    FileUtils.mkdir_p(File.dirname(destination))
    File.write(destination, markdown)
  end
end
