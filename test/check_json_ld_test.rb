# frozen_string_literal: true

require "test_helper"

# Integration tests for script/check_json_ld.rb - the guard that parses every
# <script type="application/ld+json"> block in the built output/ and blocks the
# build on malformed JSON (or on a build that emitted no JSON-LD at all, which
# would let the check pass vacuously). Driven as a subprocess over a fixture
# output/ tree.
class CheckJsonLdTest < Minitest::Test
  include GuardRunner

  SCRIPT = "check_json_ld.rb"

  def test_errors_clearly_when_there_is_no_build_to_inspect
    result = run_guard(SCRIPT) # no output/ directory materialized

    refute result.success?, result.combined
    assert_match(/no output\/ directory found/, result.stderr)
  end

  def test_passes_when_every_json_ld_block_is_well_formed
    result = run_guard(SCRIPT, files: {
      "output/index.html" => page(json_ld(%({"@context":"https://schema.org","@type":"WebSite"}))),
      "output/people/matz/index.html" => page(json_ld(%({"@type":"Person","name":"Matz"})))
    })

    assert result.success?, "expected valid JSON-LD to pass:\n#{result.combined}"
    assert_match(/\b2 JSON-LD blocks across 2 pages\b/, result.stdout)
  end

  def test_parses_pretty_printed_multiline_json_ld
    # The real component pretty-prints JSON across lines; the extractor relies on
    # its /m flag to span them. A single well-formed multi-line block must pass.
    multiline = %({\n  "@context": "https://schema.org",\n  "@type": "WebSite",\n  "name": "Ruby Lore"\n})
    result = run_guard(SCRIPT, files: {"output/index.html" => page(json_ld(multiline))})

    assert result.success?, "multiline JSON-LD should parse:\n#{result.combined}"
    assert_match(/\b1 JSON-LD block across 1 page\b/, result.stdout)
  end

  def test_counts_blocks_per_block_but_pages_per_page
    # Two valid blocks on one page: "2 blocks across 1 page" pins that
    # blocks_checked increments per block while pages_with_json_ld is per page.
    two_valid = json_ld(%({"@type":"WebSite"})) + json_ld(%({"@type":"Organization"}))
    result = run_guard(SCRIPT, files: {"output/index.html" => page(two_valid)})

    assert result.success?, result.combined
    assert_match(/\b2 JSON-LD blocks across 1 page\b/, result.stdout)
  end

  def test_blocks_and_names_the_page_on_malformed_json
    result = run_guard(SCRIPT, files: {
      "output/index.html" => page(json_ld(%({"@type":"WebSite"}))),
      "output/broken/index.html" => page(json_ld(%({"@type":"Person", "name": })))
    })

    refute result.success?, result.combined
    assert_match(/malformed JSON-LD/, result.stderr)
    assert_match(%r{broken/index\.html}, result.stderr)
  end

  def test_labels_the_offending_block_when_a_page_has_several
    two_blocks = json_ld(%({"@type":"WebSite"})) + json_ld(%({"@type":"Person","name":}))
    result = run_guard(SCRIPT, files: {"output/index.html" => page(two_blocks)})

    refute result.success?, result.combined
    assert_match(/JSON-LD block 2/, result.stderr)
  end

  def test_blocks_when_the_build_emitted_no_json_ld_at_all
    # A build that produced HTML but zero JSON-LD would otherwise pass
    # vacuously; the guard treats "nothing to check" as a regression.
    result = run_guard(SCRIPT, files: {
      "output/index.html" => page("<p>No structured data here.</p>")
    })

    refute result.success?, result.combined
    assert_match(/no <script type="application\/ld\+json"> blocks were found/, result.stderr)
  end

  def test_uses_singular_wording_for_a_single_block
    result = run_guard(SCRIPT, files: {
      "output/index.html" => page(json_ld(%({"@type":"WebSite"})))
    })

    assert result.success?, result.combined
    assert_match(/\b1 JSON-LD block across 1 page checked\b/, result.stdout)
  end

  private

  def json_ld(json)
    %(<script type="application/ld+json">#{json}</script>)
  end

  def page(body)
    "<!doctype html>\n<html><head></head><body>#{body}</body></html>\n"
  end
end
