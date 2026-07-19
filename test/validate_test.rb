# frozen_string_literal: true

require "test_helper"

# Integration tests for script/validate.rb - the plain-Ruby card validator CI
# runs before building. Each test drives the real script as a subprocess over a
# throwaway card collection and asserts on its public contract: the exit status
# and the aggregated problem report. Every problem is expected to be reported
# (not just the first), so several tests deliberately mix a valid card in with a
# broken one and assert the valid card is left alone.
class ValidateTest < Minitest::Test
  include GuardRunner

  SCRIPT = "validate.rb"

  def test_passes_and_reports_the_count_when_every_card_is_valid
    result = run_guard(SCRIPT, files: {
      "src/_cards/people/matz.md" => valid_card("Matz"),
      "src/_cards/timeline/ruby-1-0.md" => valid_card("Ruby 1.0", type: "release")
    })

    assert result.success?, "expected clean cards to exit 0:\n#{result.combined}"
    assert_match(/2 cards validated, all clean/, result.stdout)
  end

  def test_uses_singular_wording_for_a_single_card
    result = run_guard(SCRIPT, files: {"src/_cards/people/matz.md" => valid_card("Matz")})

    assert result.success?
    assert_match(/\b1 card validated\b/, result.stdout)
  end

  def test_flags_a_missing_type
    result = run_guard(SCRIPT, files: {
      "src/_cards/people/nameless.md" => card(front_matter: {"title" => "No Type"})
    })

    refute result.success?
    assert_match(/missing required 'type' field/, result.stderr)
  end

  def test_flags_an_invalid_type
    result = run_guard(SCRIPT, files: {
      "src/_cards/people/weird.md" => valid_card("Weird", type: "sasquatch")
    })

    refute result.success?
    assert_match(/invalid 'type' value "sasquatch"/, result.stderr)
    assert_match(/must be one of:/, result.stderr)
  end

  def test_flags_a_missing_title
    result = run_guard(SCRIPT, files: {
      "src/_cards/people/untitled.md" => card(front_matter: {"type" => "person"}, body: sources_section)
    })

    refute result.success?
    assert_match(/missing required 'title' field/, result.stderr)
  end

  def test_flags_a_wikilink_that_resolves_to_no_known_card
    body = "See [[ghost-slug]] for more.\n\n#{sources_section}"
    result = run_guard(SCRIPT, files: {
      "src/_cards/people/matz.md" => card(front_matter: {"type" => "person", "title" => "Matz"}, body: body)
    })

    refute result.success?
    assert_match(/\[\[ghost-slug\]\] does not match any known card slug/, result.stderr)
  end

  def test_accepts_a_wikilink_that_resolves_to_another_card
    body = "See [[why-the-lucky-stiff]] for more.\n\n#{sources_section}"
    result = run_guard(SCRIPT, files: {
      "src/_cards/people/matz.md" => card(front_matter: {"type" => "person", "title" => "Matz"}, body: body),
      "src/_cards/people/why-the-lucky-stiff.md" => valid_card("why")
    })

    assert result.success?, "expected a resolvable wikilink to pass:\n#{result.combined}"
  end

  def test_flags_a_card_with_no_sources_section
    result = run_guard(SCRIPT, files: {
      "src/_cards/people/matz.md" => card(front_matter: {"type" => "person", "title" => "Matz"}, body: "Body only.\n")
    })

    refute result.success?
    assert_match(/missing sources/, result.stderr)
  end

  def test_treats_a_verify_only_sources_section_as_missing_sources
    # A "## Sources" section that contains only a bare [VERIFY] marker (no real
    # citation) must not count as sourced.
    body = "Body.\n\n## Sources\n- [VERIFY]\n"
    result = run_guard(SCRIPT, files: {
      "src/_cards/people/matz.md" => card(front_matter: {"type" => "person", "title" => "Matz"}, body: body)
    })

    refute result.success?
    assert_match(/missing sources/, result.stderr)
  end

  def test_accepts_a_source_line_that_also_carries_a_verify_marker
    # [VERIFY] alongside a real citation on the same line still leaves real
    # content behind once the marker is stripped, so the card is sourced.
    body = "Body.\n\n## Sources\n- [VERIFY] https://example.com/citation\n"
    result = run_guard(SCRIPT, files: {
      "src/_cards/people/matz.md" => card(front_matter: {"type" => "person", "title" => "Matz"}, body: body)
    })

    assert result.success?, "expected a real citation (even with [VERIFY]) to pass:\n#{result.combined}"
  end

  def test_reports_a_card_whose_front_matter_cannot_be_parsed
    result = run_guard(SCRIPT, files: {
      "src/_cards/people/broken.md" => "---bad opener with no closing fence\nbody\n"
    })

    refute result.success?
    assert_match(/could not read this card/, result.stderr)
  end

  def test_aggregates_problems_across_cards_and_leaves_valid_cards_alone
    result = run_guard(SCRIPT, files: {
      "src/_cards/people/good.md" => valid_card("Good"),
      "src/_cards/people/typeless.md" => card(front_matter: {"title" => "Typeless"}, body: sources_section),
      "src/_cards/people/sourceless.md" => card(front_matter: {"type" => "person", "title" => "Sourceless"}, body: "Body.\n")
    })

    refute result.success?
    assert_match(/found 2 problems/, result.stderr)
    assert_match(/missing required 'type' field/, result.stderr)
    assert_match(/missing sources/, result.stderr)
    refute_match(/good\.md/, result.stderr, "the valid card should not be reported")
  end

  private

  def sources_section
    "## Sources\n- Real citation: https://example.com/source\n"
  end

  def card(front_matter:, body: "")
    front = front_matter.map { |k, v| "#{k}: #{v.inspect}" }.join("\n")
    "---\n#{front}\n---\n#{body}"
  end

  def valid_card(title, type: "person")
    card(front_matter: {"type" => type, "title" => title}, body: "A sufficiently real body.\n\n#{sources_section}")
  end
end
