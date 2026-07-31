# frozen_string_literal: true

require "uri"

# ExternalLinks hardens every outbound link in the built site by adding
# `target="_blank"` (open external sites in a new tab) and `rel="noopener"`
# (sever the new page's `window.opener` handle so the linked site can't script
# our tab back), a security/perf best practice for `target="_blank"`.
#
# This runs via the Inspectors API (`inspect_html`, registered from `build`
# below per the SiteBuilder DSL). Inspectors fire once per HTML resource, after
# rendering, against the final parsed document, so this sees every `<a>` on
# every page (card bodies, the footer license link, "Edit on GitHub", etc.),
# regardless of how that link was authored (Markdown, ERB, or the wiki-link
# plugin). Parsing/serialization is handled by Nokolexbor (see Gemfile).
#
# Only genuinely external `http(s)` links are touched:
#   - Relative links (`/timeline/`, wiki-links) parse as non-HTTP URIs -> skipped.
#   - `mailto:`, `#fragment`, etc. -> skipped.
#   - Links to our own domains (canonical + secondary) -> skipped.
# Any pre-existing `rel` tokens are preserved: we *append* `noopener` rather
# than overwrite, so e.g. the footer's `rel="license"` on the (external)
# Creative Commons link becomes `rel="license noopener"`, not `rel="noopener"`.
class Builders::ExternalLinks < SiteBuilder
  def build
    internal = internal_hosts

    inspect_html do |document|
      document.query_selector_all("a[href]").each do |anchor|
        next unless external?(anchor[:href], internal)

        anchor[:target] = "_blank"
        anchor[:rel] = add_rel_token(anchor[:rel], "noopener")
      end
    end
  end

  private

  # The set of hosts we consider "ours" (leading `www.` stripped). Derived from
  # the canonical `url` in bridgetown.config.yml plus rubylore.dev, our
  # secondary official domain (it 301s to the canonical host; see
  # src/_components/json_ld.rb).
  def internal_hosts
    hosts = ["rubylore.dev"]
    hosts << URI.parse(site.config.url).host
    hosts.compact.map { |host| host.downcase.delete_prefix("www.") }
  end

  # True only for absolute http(s) URLs pointing at a host that isn't ours.
  def external?(href, internal)
    uri = URI.parse(href)
    return false unless uri.is_a?(URI::HTTP) # HTTP/HTTPS only; skips relative, mailto:, #frag

    host = uri.host&.downcase&.delete_prefix("www.")
    !host.nil? && !internal.include?(host)
  rescue URI::InvalidURIError
    false
  end

  # Appends `token` to a space-separated `rel` value unless already present.
  def add_rel_token(existing, token)
    tokens = existing.to_s.split
    tokens << token unless tokens.include?(token)
    tokens.join(" ")
  end
end
