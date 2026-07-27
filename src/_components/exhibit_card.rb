class ExhibitCard < Bridgetown::Component
  # A thin "museum plaque" framing component: given an already-resolved
  # title, an optional list of {date, label} entries, and an optional
  # citation/attribution line, renders the semantic plaque structure with
  # class hooks (`exhibit-card`, `exhibit-card__*`) for to style.
  #
  # No slug resolution, no data-fetching, no front-matter parsing here -
  # callers (card.erb) hand over exactly the values to display.
  #
  #   dates: an Array of objects responding to #date (a Date, used as the
  #     machine-readable <time datetime>) and #label (the human-visible
  #     text), e.g. a card's `dates:` front matter (HashWithDotAccess::Hash
  #     entries already satisfy this).
  #   citation_text / citation_href: an optional small attribution line
  #     (e.g. a card's primary source), rendered as a link when an href is
  #     given, plain text otherwise.
  #   pronouns: an optional short pronouns string (e.g. "he/him") shown
  #     just under the title on person cards. Only rendered when present,
  #     so cards that don't set it are unaffected.
  def initialize(title:, dates: nil, citation_text: nil, citation_href: nil, pronouns: nil)
    @title = title.to_s
    @dates = dates
    @citation_text = citation_text
    @citation_href = citation_href
    @pronouns = pronouns.to_s.strip
  end
end
