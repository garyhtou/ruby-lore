# frozen_string_literal: true

require "test_helper"

# Integration tests for script/check_no_js_content.rb - the "zero-JS-content"
# tripwire. For every card it strips <script> blocks from the built page and
# asserts that each substantial body paragraph, and every [[slug]] cross-link,
# still survives. This proves the content layer is real static HTML, not
# JS-injected.
#
# The script renders card bodies through the real Kramdown engine, so it's run
# as a subprocess under the active bundle (Kramdown is a bundled gem). Fixtures
# use plain, punctuation-free sentences so the rendered/normalized text is
# predictable without re-modeling Kramdown's typography.
class CheckNoJsContentTest < Minitest::Test
  include GuardRunner

  SCRIPT = "check_no_js_content.rb"

  # A body paragraph well over the 8-word signal threshold, with no quotes,
  # apostrophes or ellipses (so normalization is effectively identity).
  PARAGRAPH = "Ruby grew from a small personal project into a language that many people around the world genuinely enjoy using"
  SECOND_PARAGRAPH = "The community coalesced around the idea that Matz is nice and so we are nice to one another"

  def test_errors_clearly_when_there_is_no_build_to_inspect
    result = run_guard(SCRIPT, files: {"src/_cards/stories/origin.md" => card(body: story_body)})

    refute result.success?
    assert_match(/no output\/ directory found/, result.stderr)
  end

  def test_passes_when_body_content_survives_script_stripping
    result = run_guard(SCRIPT, files: {
      "src/_cards/stories/origin.md" => card(body: story_body),
      "output/stories/origin/index.html" => page("<p>#{PARAGRAPH}.</p><script>console.log('decoration only')</script>")
    })

    assert result.success?, "expected surviving content to pass:\n#{result.combined}"
    assert_match(/\b1 card page checked\b/, result.stdout)
  end

  def test_blocks_when_a_paragraph_lives_only_inside_a_script
    # The paragraph text appears ONLY inside a <script>; once stripped it's gone.
    result = run_guard(SCRIPT, files: {
      "src/_cards/stories/origin.md" => card(body: story_body),
      "output/stories/origin/index.html" => page("<script>document.write('#{PARAGRAPH}.')</script><p>Unrelated visible text.</p>")
    })

    refute result.success?, result.combined
    assert_match(/body paragraph is missing/, result.stderr)
  end

  def test_blocks_when_a_later_paragraph_lives_only_inside_a_script
    # EVERY substantial paragraph must survive, not just the first. Here the
    # first paragraph is present in the static HTML but a later one is only in a
    # <script> - the exact regression the per-paragraph check exists to catch.
    body = "#{PARAGRAPH}.\n\n#{SECOND_PARAGRAPH}.\n\n#{sources}"
    result = run_guard(SCRIPT, files: {
      "src/_cards/stories/origin.md" => card(body: body),
      "output/stories/origin/index.html" =>
        page("<p>#{PARAGRAPH}.</p><script>document.write('#{SECOND_PARAGRAPH}.')</script>")
    })

    refute result.success?, result.combined
    assert_match(/body paragraph is missing/, result.stderr)
    assert_match(/community coalesced/, result.stderr) # names the missing (second) paragraph
  end

  def test_reconciles_smart_typography_between_source_and_rendered_html
    # The built HTML uses straight quotes/ellipsis while Kramdown renders the
    # source paragraph with curly ones (or vice versa). Only normalize() lets
    # them compare equal - if it regressed to a no-op this would falsely fail.
    typographic = "Matz said Ruby is designed to make programmers genuinely happy... and it's all about optimizing for their happiness"
    body = "#{typographic}\n\n#{sources}"
    result = run_guard(SCRIPT, files: {
      "src/_cards/stories/origin.md" => card(body: body),
      # straight apostrophe + straight ... in the page; Kramdown curls them.
      "output/stories/origin/index.html" => page("<p>#{typographic}</p>")
    })

    assert result.success?, "smart-typography differences must not read as missing content:\n#{result.combined}"
  end

  def test_blocks_when_a_cross_link_is_absent_from_the_static_html
    # The prose text is present, but the [[matz]] cross-link's href is not in
    # the static HTML - so the link would only exist if injected by script.
    body = "Ruby was created by [[matz]] and became a language that people around the world genuinely enjoy.\n\n#{sources}"
    result = run_guard(SCRIPT, files: {
      "src/_cards/stories/origin.md" => card(body: body),
      "src/_cards/people/matz.md" => card(type: "person", title: "Matz", body: person_body),
      # origin page has the prose but NOT href="/people/matz/"
      "output/stories/origin/index.html" =>
        page("<p>Ruby was created by Matz and became a language that people around the world genuinely enjoy.</p>"),
      "output/people/matz/index.html" => page("<p>#{PERSON_PARAGRAPH}.</p>")
    })

    refute result.success?, result.combined
    assert_match(/cross-link to \[\[matz\]\].*is missing/, result.stderr)
  end

  def test_passes_when_cross_link_href_is_present_in_the_static_html
    body = "Ruby was created by [[matz]] and became a language that people around the world genuinely enjoy.\n\n#{sources}"
    result = run_guard(SCRIPT, files: {
      "src/_cards/stories/origin.md" => card(body: body),
      "src/_cards/people/matz.md" => card(type: "person", title: "Matz", body: person_body),
      "output/stories/origin/index.html" => page(
        %(<p>Ruby was created by <a href="/people/matz/">Matz</a> and became a language that people around the world genuinely enjoy.</p>)
      ),
      "output/people/matz/index.html" => page("<p>#{PERSON_PARAGRAPH}.</p>")
    })

    assert result.success?, "expected present cross-links to pass:\n#{result.combined}"
    assert_match(/\b2 card pages checked\b/, result.stdout)
  end

  def test_does_not_require_the_sources_section_to_survive
    # prose_body drops the "## Sources" section before deriving signals, so a
    # citation line (even a wordy one) is NOT required to appear in the page.
    wordy_citation = "This fabricated citation line has more than eight words on purpose so it would count"
    body = "#{PARAGRAPH}.\n\n## Sources\n- #{wordy_citation}: https://example.com\n"
    result = run_guard(SCRIPT, files: {
      "src/_cards/stories/origin.md" => card(body: body),
      # page has the prose but NOT the citation line
      "output/stories/origin/index.html" => page("<p>#{PARAGRAPH}.</p>")
    })

    assert result.success?, "sources-section content should not be a required signal:\n#{result.combined}"
  end

  def test_blocks_when_the_built_page_is_missing_entirely
    result = run_guard(SCRIPT, files: {
      "src/_cards/stories/origin.md" => card(body: story_body),
      "output/.keep" => "" # output/ exists, but the card's page does not
    })

    refute result.success?, result.combined
    assert_match(/expected built page.*but it doesn't exist/, result.stderr)
  end

  def test_blocks_a_body_too_thin_to_provide_a_content_signal
    thin = "Ruby is nice.\n\n#{sources}"
    result = run_guard(SCRIPT, files: {
      "src/_cards/stories/origin.md" => card(body: thin),
      "output/stories/origin/index.html" => page("<p>Ruby is nice.</p>")
    })

    refute result.success?, result.combined
    assert_match(/could not find any body paragraph with 8\+ words/, result.stderr)
  end

  private

  PERSON_PARAGRAPH = "Matz is the creator of Ruby and has guided its friendly and welcoming community for many years"

  def sources
    "## Sources\n- Real citation: https://example.com/source\n"
  end

  def story_body
    "#{PARAGRAPH}.\n\n#{sources}"
  end

  def person_body
    "#{PERSON_PARAGRAPH}.\n\n#{sources}"
  end

  def card(type: "story", title: "Origin", body: "")
    "---\ntype: #{type.inspect}\ntitle: #{title.inspect}\n---\n#{body}"
  end

  def page(body)
    "<!doctype html>\n<html><head></head><body>#{body}</body></html>\n"
  end
end
