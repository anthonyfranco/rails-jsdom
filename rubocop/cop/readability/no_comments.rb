module RuboCop
  module Cop
    module Readability
      # Allows only magic comments and RDoc documentation, so every other note
      # is turned into a name, a method or a test.
      #
      # An RDoc comment is a block of whole-line comments directly above a
      # class, module, method, constant, attribute, alias or delegation; a
      # block that holds an RDoc directive such as `:nodoc:` or `:method:`, or
      # starts with RDoc's `##` marker; or a directive at the end of a line.
      class NoComments < RuboCop::Cop::Base
        MSG = "Do not write comments. Put the meaning into a name, a method or a test. Only RDoc documentation is allowed."
        DIRECTIVE = /\A#\s*:(?:nodoc|doc|stopdoc|startdoc|enddoc|method|singleton-method|attr(?:_reader|_writer|_accessor)?|call-seq|section|title|main|include|category):/
        META_MARKER = /\A##\s*\z/
        DOCUMENTED = /\A\s*(?:(?:class|module|def|alias_method|alias|attr_reader|attr_writer|attr_accessor|delegate)\b|[A-Z][A-Za-z0-9_]*\s*=(?!=))/

        def on_new_investigation
          @blocks = comment_blocks
          processed_source.comments.each do |comment|
            add_offense(comment) unless allowed?(comment)
          end
        end

        private

        def comment_blocks
          processed_source.comments.select { |comment| whole_line?(comment) }.slice_when { |previous, following| following.loc.line != previous.loc.line + 1 }.to_a
        end

        def enabled_lines?(_range)
          true
        end

        def allowed?(comment)
          magic?(comment) || DIRECTIVE.match?(comment.text) || (whole_line?(comment) && documentation?(block_of(comment)))
        end

        def magic?(comment)
          leading?(comment) && leading_patterns.any? { |pattern| pattern.match?(comment.text) }
        end

        def leading?(comment)
          first_token = processed_source.tokens.find { |token| !token.comment? }
          first_token.nil? || comment.loc.line < first_token.line
        end

        def whole_line?(comment)
          processed_source.lines[comment.loc.line - 1].lstrip.start_with?("#")
        end

        def documentation?(block)
          block.any? { |comment| DIRECTIVE.match?(comment.text) || META_MARKER.match?(comment.text) } || DOCUMENTED.match?(line_after(block))
        end

        def block_of(comment)
          @blocks.find { |block| block.include?(comment) }
        end

        def line_after(block)
          processed_source.lines[block.last.loc.line].to_s
        end

        def leading_patterns
          @leading_patterns ||= Array(cop_config["AllowedLeadingPatterns"]).map { |pattern| Regexp.new(pattern) }
        end
      end
    end
  end
end
