# frozen_string_literal: true

require "rubocop"

module RuboCop
  module Cop
    module Readability
      class NoUnnecessaryBoolean < Base
        RESTATED_CONDITION_MSG = "Every branch is a boolean literal: use the condition itself."
        FLAG_MSG = "Boolean flag `%<name>s` is set more than once: compose a predicate instead."
        CONSTANT_RESULT_MSG = "Do not end with the constant `%<value>s` after an action. Make the action's own return value the last expression."

        def on_if(node)
          add_offense(node, message: RESTATED_CONDITION_MSG) if restated_if?(node)
        end

        def on_case(node)
          add_offense(node, message: RESTATED_CONDITION_MSG) if all_boolean?(node.branches) && node.else?
        end

        def on_def(node)
          flags(node).each { |name, first| add_offense(first, message: format(FLAG_MSG, name: name)) }
          check_constant_result(node.body)
        end
        alias on_defs on_def

        def on_block(node)
          check_constant_result(node.body)
        end
        alias on_numblock on_block

        private

        def restated_if?(node)
          !node.ternary? && !node.elsif? && node.else? && all_boolean?(if_branches(node))
        end

        def if_branches(node)
          node.else_branch&.if_type? && node.else_branch.elsif? ? [ node.if_branch, *if_branches(node.else_branch) ] : [ node.if_branch, node.else_branch ]
        end

        def all_boolean?(branches)
          branches.size > 1 && branches.all? { |branch| boolean_literal?(branch) }
        end

        def boolean_literal?(node)
          node&.true_type? || node&.false_type?
        end

        def flags(def_node)
          assignments = def_node.each_descendant(:lvasgn).select { |asgn| boolean_literal?(asgn.expression) }
          assignments.group_by(&:name).select { |_name, group| group.size > 1 }.transform_values(&:first)
        end

        def check_constant_result(body)
          last = body.children.last if body&.begin_type?
          add_offense(last, message: format(CONSTANT_RESULT_MSG, value: last.source)) if boolean_literal?(last)
        end
      end
    end
  end
end
