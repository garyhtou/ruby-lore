# frozen_string_literal: true

require "test_helper"
require "slugs"

# Unit tests for lib/slugs.rb - the plain-Ruby resolver that turns the on-disk
# card collection into a slug => Card map. It's the shared foundation under
# script/validate.rb, plugins/wiki_links.rb and src/_components/json_ld.rb, so
# its behavior is pinned down carefully here.
#
# Every load_cards test injects a `glob:` pointed at throwaway fixture files, so
# nothing here depends on the real src/_cards content.
class SlugsTest < Minitest::Test
  include CardFixtures

  # --- TYPE_SEGMENTS -------------------------------------------------------

  def test_type_segments_maps_each_card_type_to_its_url_segment
    assert_equal "people", Slugs::TYPE_SEGMENTS["person"]
    assert_equal "stories", Slugs::TYPE_SEGMENTS["story"]
    assert_equal "talks", Slugs::TYPE_SEGMENTS["talk"]
    assert_equal "glossary", Slugs::TYPE_SEGMENTS["vocabulary"]
    assert_equal "timeline", Slugs::TYPE_SEGMENTS["release"]
  end

  def test_type_segments_is_frozen
    assert_predicate Slugs::TYPE_SEGMENTS, :frozen?
  end

  # --- Card struct ---------------------------------------------------------

  def test_card_accepts_keyword_attributes_and_defaults_the_rest_to_nil
    card = Slugs::Card.new(slug: "matz", title: "Matz", type: "person")

    assert_equal "matz", card.slug
    assert_equal "Matz", card.title
    assert_equal "person", card.type
    assert_nil card.href # unspecified members default to nil
  end

  # --- parse_front_matter --------------------------------------------------
  #
  # Cases mirror the behavior verified empirically against the real module;
  # front_matter is ALWAYS a Hash so callers never need a nil-guard.

  def test_parse_front_matter_returns_empty_hash_and_whole_content_when_absent
    with_file("Just a body\nsecond line\n") do |path|
      front_matter, body, error = Slugs.parse_front_matter(path)

      assert_equal({}, front_matter)
      assert_equal "Just a body\nsecond line\n", body
      assert_nil error
    end
  end

  def test_parse_front_matter_parses_valid_block_and_returns_body_after_it
    with_file("---\ntype: person\ntitle: Matz\n---\nHello **world**\n") do |path|
      front_matter, body, error = Slugs.parse_front_matter(path)

      assert_equal({"type" => "person", "title" => "Matz"}, front_matter)
      assert_equal "\nHello **world**\n", body
      assert_nil error
    end
  end

  def test_parse_front_matter_permits_date_values
    with_file("---\ndates:\n  - {date: 1996-12-25, label: released}\n---\nbody\n") do |path|
      front_matter, _body, error = Slugs.parse_front_matter(path)

      assert_nil error
      assert_equal Date.new(1996, 12, 25), front_matter.dig("dates", 0, "date")
    end
  end

  def test_parse_front_matter_flags_missing_closing_delimiter
    # Starts with "---" but no line is a bare "---" delimiter, so the block is
    # never closed.
    with_file("---junk on the opening line\nbody here\n") do |path|
      front_matter, body, error = Slugs.parse_front_matter(path)

      assert_equal({}, front_matter)
      assert_equal "---junk on the opening line\nbody here\n", body
      assert_match(/no closing '---' found/, error)
    end
  end

  def test_parse_front_matter_reports_invalid_yaml_without_raising
    with_file("---\ntype: : :\n  bad\n---\nbody\n") do |path|
      front_matter, body, error = Slugs.parse_front_matter(path)

      assert_equal({}, front_matter)
      assert_equal "", body
      assert_match(/could not parse YAML front matter/, error)
    end
  end

  def test_parse_front_matter_rejects_disallowed_classes
    with_file("---\nx: !ruby/symbol danger\n---\nbody\n") do |path|
      front_matter, _body, error = Slugs.parse_front_matter(path)

      assert_equal({}, front_matter)
      assert_match(/could not parse YAML front matter/, error)
    end
  end

  def test_parse_front_matter_coerces_non_hash_front_matter_to_empty_hash
    # A bare scalar or a list is valid YAML but not a mapping; callers still
    # get a Hash (empty) rather than a surprise type.
    with_file("---\njust a string\n---\nbody\n") do |path|
      front_matter, body, error = Slugs.parse_front_matter(path)

      assert_equal({}, front_matter)
      assert_equal "\nbody\n", body
      assert_nil error
    end
  end

  def test_parse_front_matter_handles_empty_front_matter_block
    with_file("---\n---\nbody\n") do |path|
      front_matter, body, error = Slugs.parse_front_matter(path)

      assert_equal({}, front_matter)
      assert_equal "\nbody\n", body
      assert_nil error
    end
  end

  def test_parse_front_matter_reads_utf8_regardless_of_locale
    # The card files are UTF-8; parsing must not depend on the ambient locale's
    # default external encoding (this guards the require "date" / UTF-8 read
    # fix in lib/slugs.rb).
    with_file("---\ntitle: \"Matz, “MINASWAN”\"\n---\nem—dash\n") do |path|
      front_matter, body, error = Slugs.parse_front_matter(path)

      assert_nil error
      assert_equal "Matz, “MINASWAN”", front_matter["title"]
      assert_includes body, "em—dash"
    end
  end

  # --- load_cards ----------------------------------------------------------

  def test_load_cards_keys_the_map_by_slug_derived_from_the_filename
    with_card_files("people/matz" => person_card("Matz")) do |glob|
      cards = Slugs.load_cards(glob: glob)

      assert_equal ["matz"], cards.keys
      assert_equal "matz", cards["matz"].slug
    end
  end

  def test_load_cards_derives_href_from_type_segment_and_slug
    with_card_files(
      "people/matz" => person_card("Matz"),
      "timeline/ruby-1-0" => release_card("Ruby 1.0")
    ) do |glob|
      cards = Slugs.load_cards(glob: glob)

      assert_equal "/people/matz/", cards["matz"].href
      assert_equal "/timeline/ruby-1-0/", cards["ruby-1-0"].href
    end
  end

  def test_load_cards_leaves_href_nil_for_unknown_type
    with_card_files("misc/mystery" => card_file(front_matter: {"type" => "unknowable", "title" => "?"})) do |glob|
      cards = Slugs.load_cards(glob: glob)

      assert_nil cards["mystery"].href
      assert_equal "unknowable", cards["mystery"].type
    end
  end

  def test_load_cards_captures_title_type_body_and_path
    body = "The prose body.\n"
    with_card_files("people/matz" => person_card("Matz", body: body)) do |glob|
      cards = Slugs.load_cards(glob: glob)
      card = cards["matz"]

      assert_equal "Matz", card.title
      assert_equal "person", card.type
      assert_includes card.body, "The prose body."
      assert card.path.end_with?("people/matz.md"), "expected path to point at the source file"
      assert_nil card.error
    end
  end

  def test_load_cards_propagates_parse_errors_without_raising
    with_card_files("broken/oops" => "---broken opener\nbody\n") do |glob|
      cards = Slugs.load_cards(glob: glob)
      card = cards["oops"]

      refute_nil card.error
      assert_nil card.type
      assert_nil card.title
      assert_nil card.href
    end
  end

  def test_load_cards_returns_slugs_in_sorted_path_order
    with_card_files(
      "people/zeal" => person_card("Zeal"),
      "people/adam" => person_card("Adam"),
      "people/mona" => person_card("Mona")
    ) do |glob|
      cards = Slugs.load_cards(glob: glob)

      assert_equal %w[adam mona zeal], cards.keys
    end
  end

  def test_load_cards_returns_empty_hash_when_nothing_matches
    with_card_files({}) do |glob|
      assert_empty Slugs.load_cards(glob: glob)
    end
  end

  def test_load_cards_last_file_wins_for_a_duplicated_slug
    # Two files in different segments share a basename -> same slug. The sorted
    # traversal means the later path's card is the one retained.
    with_card_files(
      "aaa/dup" => person_card("From A"),
      "zzz/dup" => person_card("From Z")
    ) do |glob|
      cards = Slugs.load_cards(glob: glob)

      assert_equal 1, cards.size
      assert_equal "From Z", cards["dup"].title
    end
  end

  def test_default_glob_points_at_the_repositorys_card_collection
    assert Slugs.default_glob.end_with?("src/_cards/**/*.md"),
      "expected default glob under src/_cards, got #{Slugs.default_glob.inspect}"
  end

  private

  def with_file(contents)
    Dir.mktmpdir("slugs-test") do |dir|
      path = File.join(dir, "card.md")
      File.write(path, contents)
      yield path
    end
  end

  def person_card(title, body: "Body text.\n")
    card_file(front_matter: {"type" => "person", "title" => title}, body: body)
  end

  def release_card(title, body: "Body text.\n")
    card_file(front_matter: {"type" => "release", "title" => title}, body: body)
  end
end
