module RuboCop
  module Cop
    module Readability
      class NoNilTernaryBranch < Base
        MSG = "Ternary with a `nil` branch — use a modifier `if`/`unless` instead."

        def on_if(node)
          add_offense(node) if node.ternary? && nil_branch?(node)
        end

        private

        def nil_branch?(node)
          node.if_branch.nil_type? || node.else_branch.nil_type?
        end
      end
    end
  end
end
