# frozen_string_literal: true

require "test_helper"
require "digest"
require "json"

# Integration tests for script/check_bundle_size.rb - the JS bundle-size budget
# guard. It reads the esbuild manifest, gzips each budgeted asset, and blocks if
# any bundle exceeds its ceiling. Driven as a subprocess over a fixture manifest
# + static-asset tree.
#
# The over-budget fixture uses deterministic *incompressible* bytes (chained
# SHA-256 digests) so the gzipped size is stable across platforms and reliably
# above the 15KB initial-load ceiling - no random seeds, no flakiness.
class CheckBundleSizeTest < Minitest::Test
  include GuardRunner

  SCRIPT = "check_bundle_size.rb"
  MANIFEST_PATH = ".bridgetown-cache/frontend-bundling/manifest.json"
  STATIC = "output/_bridgetown/static"

  def test_errors_clearly_when_there_is_no_manifest_to_inspect
    result = run_guard(SCRIPT) # nothing built

    refute result.success?, result.combined
    assert_match(/no frontend bundling manifest found/, result.stderr)
  end

  def test_passes_when_every_bundle_is_within_budget
    result = run_guard(SCRIPT, files: manifest_and_assets(
      index: "console.log('tiny loader')\n",
      experience: "console.log('tiny experience bundle')\n"
    ))

    assert result.success?, "expected small bundles to pass:\n#{result.combined}"
    assert_match(/All JS bundles within budget/, result.stdout)
    # The per-asset report line renders (size / budget / percentage).
    assert_match(/initial-load JS.*\d+ B gzip.*budget.*%/, result.stdout)
  end

  def test_blocks_when_the_initial_bundle_is_over_budget
    result = run_guard(SCRIPT, files: manifest_and_assets(
      index: incompressible(20 * 1024), # > 15KB gzipped ceiling
      experience: "console.log('small')\n"
    ))

    refute result.success?, result.combined
    assert_match(/initial-load JS.*over its \d+-byte budget/m, result.stderr)
  end

  def test_blocks_when_the_lazy_experience_bundle_is_over_budget
    result = run_guard(SCRIPT, files: manifest_and_assets(
      index: "console.log('small')\n",
      experience: incompressible(110 * 1024) # > 100KB gzipped ceiling
    ))

    refute result.success?, result.combined
    assert_match(/lazy-loaded experience bundle.*over its \d+-byte budget/m, result.stderr)
  end

  def test_reports_every_over_budget_bundle_together
    result = run_guard(SCRIPT, files: manifest_and_assets(
      index: incompressible(20 * 1024),
      experience: incompressible(110 * 1024)
    ))

    refute result.success?, result.combined
    assert_match(/found 2 problems/, result.stderr)
  end

  def test_blocks_when_a_budgeted_entry_is_missing_from_the_manifest
    files = {
      MANIFEST_PATH => JSON.generate("javascript/experience.js" => "experience.js"),
      "#{STATIC}/experience.js" => "console.log('x')\n"
    }
    result = run_guard(SCRIPT, files: files)

    refute result.success?, result.combined
    assert_match(/no `javascript\/index\.js` entry in the frontend bundling manifest/, result.stderr)
  end

  def test_blocks_when_the_manifest_points_at_a_missing_asset
    files = {
      MANIFEST_PATH => JSON.generate(
        "javascript/index.js" => "index.js",
        "javascript/experience.js" => "experience.js"
      ),
      "#{STATIC}/experience.js" => "console.log('x')\n"
      # index.js referenced by the manifest but never written
    }
    result = run_guard(SCRIPT, files: files)

    refute result.success?, result.combined
    assert_match(/which doesn't exist/, result.stderr)
  end

  private

  def manifest_and_assets(index:, experience:)
    {
      MANIFEST_PATH => JSON.generate(
        "javascript/index.js" => "index.js",
        "javascript/experience.js" => "experience.js"
      ),
      "#{STATIC}/index.js" => index,
      "#{STATIC}/experience.js" => experience
    }
  end

  # Deterministic bytes that gzip cannot meaningfully shrink: each 32-byte block
  # is the SHA-256 of the previous one, so the output is stable but has ~no
  # exploitable redundancy.
  def incompressible(bytes)
    out = +""
    block = "ruby-lore-bundle-fixture"
    out << (block = Digest::SHA256.digest(block)) while out.bytesize < bytes
    out.byteslice(0, bytes)
  end
end
