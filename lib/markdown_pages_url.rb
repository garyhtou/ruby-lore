# frozen_string_literal: true

# Shared source of truth for the static "Markdown for agents" URL scheme:
# every real content page at a trailing-slash permalink (e.g. /people/matz/)
# also gets a sibling `.md` file (e.g. /people/matz.md) with clean Markdown
# content, GitHub Pages' answer to Accept-header content negotiation (which
# isn't available on static hosting - see plugins/builders/markdown_pages.rb
# for the full rationale).
#
# Used by both plugins/builders/markdown_pages.rb (which generates the
# files) and src/_partials/_head.erb (which advertises them via
# <link rel="alternate">), so the two can never drift on which pages
# qualify or what the derived URL looks like.
#
# Only trailing-slash (pretty permalink) resources qualify: this excludes
# /404.html, /500.html (explicit-extension permalinks), /robots.txt,
# /llms.txt, /sitemap.xml, and the CNAME file (none of which are real HTML
# content pages) without needing a separate opt-out list.
module MarkdownPagesUrl
  module_function

  def eligible?(resource)
    !!(resource && resource.respond_to?(:relative_url) && resource.relative_url.to_s.end_with?("/"))
  end

  # e.g. "/" -> "/index.md", "/people/matz/" -> "/people/matz.md"
  def relative_md_url(resource)
    relative_md_url_for_path(resource.relative_url.to_s)
  end

  # Same derivation as `relative_md_url`, but for a raw root-relative path
  # rather than a resource - used to rewrite an internal link/wiki-link
  # target discovered while generating Markdown, where there's a path
  # string, not a resource, in hand (see MarkdownPagesRender's
  # resolve_wikilinks, absolute_md_url, and internal_links_to_md).
  def relative_md_url_for_path(path)
    return "/index.md" if path == "/"

    "#{path.chomp("/")}.md"
  end
end
