module RuboCop
  module Cop
    module Readability
      class NoBooleanTernaryBranch < Base
        MSG = "Ternary with a boolean-literal branch — use `&&`/`||` instead " \
              "(`cond ? y : false` is `cond && y`; `cond ? true : y` is `cond || y`)."

        def on_if(node)
          add_offense(node) if node.ternary? && boolean_branch?(node)
        end

        private

        def boolean_branch?(node)
          boolean_literal?(node.if_branch) || boolean_literal?(node.else_branch)
        end

        def boolean_literal?(branch)
          branch && (branch.true_type? || branch.false_type?)
        end
      end
    end
  end
end
