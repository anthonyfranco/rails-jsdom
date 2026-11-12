# frozen_string_literal: true

require "rubocop"

module RuboCop
  module Cop
    module Readability
      class NoNextUnless < Base
        MSG = "Do not use `next unless`. Use an explicit `if`/`else`, or compose a named action with the predicate."

        def on_if(node)
          add_offense(node) if node.unless? && guards_next?(node)
        end

        private

        def guards_next?(node)
          [ node.if_branch, node.else_branch ].any? { |branch| branch&.next_type? }
        end
      end
    end
  end
end
