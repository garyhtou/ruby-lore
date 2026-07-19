# frozen_string_literal: true

require "minitest/autorun"
require "open3"
require "tmpdir"
require "fileutils"
require "yaml"

# Shared helpers for the Ruby test suite.
#
# The `lib/slugs.rb` module is exercised directly, in-process, through its
# public API (it's plain Ruby with an injectable `glob:` seam - see
# SlugsTest). The `script/*.rb` content guards are CLIs, so they're exercised
# the way CI runs them: as real subprocesses whose only observable contract is
# an exit status plus a human-readable report. `run_guard` below runs the real,
# unmodified script against a throwaway "mini-repo" of fixture files, so a test
# can drive any success/failure path without touching (or depending on) the
# actual site content under src/_cards or output/.
module GuardRunner
  REPO_ROOT = File.expand_path("..", __dir__)

  Result = Struct.new(:stdout, :stderr, :status) do
    def combined = "#{stdout}\n#{stderr}"

    def success? = status.zero?
  end

  # Copies the real script (and lib/slugs.rb, which every guard leans on)
  # verbatim into a temp directory laid out like the repo, materializes the
  # given fixture `files` (paths relative to that root), then runs
  # `ruby script/<name>` from the root - exactly how .github/workflows/ci.yml
  # invokes it. Returns the captured stdout/stderr/exit-status.
  #
  # Running the script as a child process (rather than `require`-ing it) is
  # deliberate: these files are top-level scripts that call `exit` and define
  # global constants/methods, so requiring them would terminate the test run
  # and leak state between guards. The subprocess is also the honest seam -
  # it's the whole interface CI depends on.
  def run_guard(script_name, files: {})
    Dir.mktmpdir("ruby-lore-guard") do |root|
      FileUtils.mkdir_p(File.join(root, "lib"))
      FileUtils.mkdir_p(File.join(root, "script"))
      FileUtils.cp(File.join(REPO_ROOT, "lib", "slugs.rb"), File.join(root, "lib", "slugs.rb"))
      FileUtils.cp(File.join(REPO_ROOT, "script", script_name), File.join(root, "script", script_name))

      files.each do |relative_path, contents|
        absolute = File.join(root, relative_path)
        FileUtils.mkdir_p(File.dirname(absolute))
        File.write(absolute, contents)
      end

      stdout, stderr, status = Open3.capture3(
        RbConfig.ruby, File.join("script", script_name), chdir: root
      )
      Result.new(stdout, stderr, status.exitstatus)
    end
  end
end

# Builds card markdown files (front matter + body) inside a temp directory and
# yields the glob that Slugs.load_cards should be pointed at. Keeps the fixture
# shape in one place so individual tests read as data, not filesystem plumbing.
module CardFixtures
  # `cards` is a Hash of "segment/slug" => file-contents. Yields the
  # `**/*.md` glob rooted at the temp cards dir.
  def with_card_files(cards)
    Dir.mktmpdir("ruby-lore-cards") do |dir|
      cards.each do |relative_path, contents|
        path = File.join(dir, "#{relative_path}.md")
        FileUtils.mkdir_p(File.dirname(path))
        File.write(path, contents)
      end
      yield File.join(dir, "**", "*.md")
    end
  end

  # Front matter + body assembled into a single card file string. The front
  # matter is serialized with YAML.dump (so nested structures like `dates:`
  # round-trip exactly the way a real card file is written) and re-wrapped in
  # the `---` fences Slugs expects.
  def card_file(front_matter: {}, body: "")
    yaml = front_matter.empty? ? "" : YAML.dump(front_matter).sub(/\A---\n/, "")
    "---\n#{yaml}---\n#{body}"
  end
end
