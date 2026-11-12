module RuboCop
  module Cop
    module Readability
      class NoNilConditionCheck < Base
        MSG = "Do not use `.nil?` as a condition. Test the value itself (`if value`) and swap the branches."

        def on_if(node)
          condition = node.condition
          add_offense(condition) if nil_predicate?(condition)
        end

        private

        def nil_predicate?(node)
          node.send_type? && node.method_name == :nil? && node.arguments.empty?
        end
      end
    end
  end
end
