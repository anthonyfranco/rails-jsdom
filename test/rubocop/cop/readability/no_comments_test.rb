# frozen_string_literal: true

require "minitest/autorun"
require "rubocop"
require "active_support/testing/declarative"
require_relative "../../../../rubocop/cop/readability/no_comments"

class RuboCop::Cop::Readability::NoCommentsTest < Minitest::Test
  extend ActiveSupport::Testing::Declarative

  LEADING_PATTERNS = [ "\\A#!", "\\A#\\s*frozen_string_literal:" ].freeze

  def offenses_for(source)
    config = RuboCop::Config.new(
      "Readability/NoComments" => { "Enabled" => true, "AllowedLeadingPatterns" => LEADING_PATTERNS }
    )
    cop = RuboCop::Cop::Readability::NoComments.new(config)
    processed = RuboCop::ProcessedSource.new(source, RUBY_VERSION.to_f)
    processed.config = config
    processed.registry = RuboCop::Cop::Registry.new([ RuboCop::Cop::Readability::NoComments ])
    commissioner = RuboCop::Cop::Commissioner.new([ cop ])
    commissioner.investigate(processed).offenses.reject(&:disabled?)
  end

  test "#on_new_investigation flags a full line comment" do
    assert_equal [ 1 ], offenses_for("# explains\nx = 1\n").map(&:line)
  end

  test "#on_new_investigation flags a trailing comment" do
    assert_equal [ 1 ], offenses_for("x = 1 # explains\n").map(&:line)
  end

  test "#on_new_investigation flags a comment inside a method" do
    source = "def run\n  # step one\n  call\nend\n"

    assert_equal [ 2 ], offenses_for(source).map(&:line)
  end

  test "#on_new_investigation flags rubocop disable and todo directives" do
    source = "x = 1 # rubocop:disable Style/Foo\ny = 2 # rubocop:todo Style/Bar\n"

    assert_equal [ 1, 2 ], offenses_for(source).map(&:line)
  end

  test "#on_new_investigation flags a directive that tries to silence the cop" do
    source = "# rubocop:disable Readability/NoComments\n# hidden\nx = 1\n# rubocop:enable Readability/NoComments\n"

    assert_equal [ 1, 2, 4 ], offenses_for(source).map(&:line)
  end

  test "#on_new_investigation flags disable all" do
    source = "x = 1 # rubocop:disable all\n"

    assert_equal [ 1 ], offenses_for(source).map(&:line)
  end

  test "#on_new_investigation allows configured leading comments" do
    source = "#!/usr/bin/env ruby\n# frozen_string_literal: true\n\nputs 1\n"

    assert_empty offenses_for(source)
  end

  test "#on_new_investigation flags a configured pattern after the first code" do
    source = "puts 1\n# frozen_string_literal: true\n"

    assert_equal [ 2 ], offenses_for(source).map(&:line)
  end

  test "#on_new_investigation flags a leading comment that matches no pattern" do
    source = "# frozen_string_literal: true\n# Explains the file\nputs 1\n"

    assert_equal [ 2 ], offenses_for(source).map(&:line)
  end

  test "#on_new_investigation accepts hashes in strings" do
    assert_empty offenses_for("x = \"# not a comment\"\ny = \"\#{x}\"\n")
  end

  test "#on_new_investigation allows RDoc above a class, module, method, constant, attribute, alias or delegation" do
    source = <<~RUBY
      # The library.
      module Library
        # A book.
        class Book
          # The title.
          attr_reader :title

          # How many pages.
          PAGES = 1

          # Reads it.
          #
          #   book.read
          def read
          end

          # Another name.
          alias_method :open, :read

          # Also another name.
          alias skim read

          # From the shelf.
          delegate :shelf, to: :library
        end
      end
    RUBY

    assert_empty offenses_for(source)
  end

  test "#on_new_investigation allows an RDoc block with a directive or the meta marker anywhere in the block" do
    source = "class Book\n  ##\n  # :method: read\n  # Reads it.\n\n  # :stopdoc:\n  # internal\n  x = 1\nend\n"

    assert_empty offenses_for(source)
  end

  test "#on_new_investigation allows a trailing RDoc directive" do
    assert_empty offenses_for("def read # :nodoc:\nend\n")
  end

  test "#on_new_investigation flags a trailing comment before a method" do
    assert_equal [ 1 ], offenses_for("x = 1 # explains\ndef read\nend\n").map(&:line)
  end

  test "#on_new_investigation flags a comment separated from the code it describes" do
    assert_equal [ 1 ], offenses_for("# Reads it.\n\ndef read\nend\n").map(&:line)
  end

  test "#on_new_investigation flags a comment above a comparison with a constant" do
    assert_equal [ 1 ], offenses_for("# checks\nPAGES == 1\n").map(&:line)
  end

  test "#on_new_investigation flags a comment at the end of the file" do
    assert_equal [ 2 ], offenses_for("x = 1\n# done\n").map(&:line)
  end
end
