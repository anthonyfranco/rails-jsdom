module RuboCop
  module Cop
    module Readability
      class StrictUnlessPredicate < Base
        MSG = "Invalid use of 'unless'. Only single-line statements paired with a predicate method (ending in '?') are allowed (e.g., 'do_something unless model.valid?')."

        def on_if(node)
          add_offense(node) if node.unless? && !allowed?(node)
        end

        private

        def allowed?(node)
          node.modifier_form? && !node.multiline? && predicate_method?(node.condition)
        end

        def predicate_method?(condition_node)
          condition_node.send_type? && condition_node.method_name.to_s.end_with?("?")
        end
      end
    end
  end
end
