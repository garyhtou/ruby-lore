class CardLink < Bridgetown::Component
  # A thin renderer: given an already-resolved card slug's title/href, emit
  # <a href="HREF">TITLE</a>. Slug resolution itself lives in lib/slugs.rb -
  # this component doesn't know what a "slug" is, only how to link to one.
  #
  # Used two ways:
  #   - from plugins/wiki_links.rb's `hook :site, :post_read`, rendered
  #     Ruby-side via Bridgetown::TemplateView.render(CardLink.new(...))
  #   - from ERB templates in future tasks (2.2/2.3), e.g.
  #     <%= render CardLink.new(title: card.title, href: card.href) %>
  def initialize(title:, href:)
    # Deliberately NOT pre-escaped here. `href` is safe unescaped: slugs are
    # constrained to `[a-zA-Z0-9_-]+` by WIKILINK_PATTERN in
    # plugins/wiki_links.rb, so it can never contain `&`, `<`, or `"`.
    #
    # `title` is raw front-matter text and DOES need HTML-escaping - but
    # that already happens automatically, exactly once, when `card_link.erb`
    # interpolates it via `<%= @title %>`: Bridgetown's ERB output buffer
    # (`Bridgetown::OutputBuffer#<<`, bridgetown-core/converters/erb_templates.rb)
    # runs `Erubi.h` (escapes `& < > " '`) on any `<%= %>` value that isn't
    # already `html_safe?`, and a plain String from YAML front matter never
    # is. Verified directly: `Bridgetown::TemplateView.render(CardLink.new(
    # title: "Rails & <Merb>", ...))` already returns
    # `"...>Rails &amp; &lt;Merb&gt;</a>"` with zero extra code here.
    #
    # DO NOT add manual escaping (`Bridgetown::Utils.xml_escape`, `CGI.
    # escapeHTML`, a hand-rolled `gsub`, etc.) in this class or in
    # `card_link.erb` - stacking it on top of the ERB auto-escape above
    # double-escapes (`&` -> `&amp;` -> `&amp;amp;`), which is exactly the
    # regression this comment exists to prevent. `.to_s` here is just a
    # defensive guarantee that `@title` is a plain (never `html_safe?`)
    # String, so the auto-escape above always applies.
    @title = title.to_s
    @href = href
  end
end
