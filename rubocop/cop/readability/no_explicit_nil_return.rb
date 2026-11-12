module RuboCop
  module Cop
    module Readability
      class NoExplicitNilReturn < RuboCop::Cop::Base
        MSG_BARE      = "Do not return `nil` explicitly. Make the value the method's last expression; a branch with no value already evaluates to nil."
        MSG_MODIFIER  = "Do not write `return nil %<modifier>s ...`. Put the condition around the value instead (`value if condition`); the branch that does not run evaluates to nil."

        def on_return(node)
          add_offense(node, message: message(node.parent)) if nil_return?(node)
        end

        private

        def nil_return?(node)
          node.arguments.one? && node.arguments.first.nil_type?
        end

        def message(parent)
          if modifier?(parent)
            format(MSG_MODIFIER, modifier: parent.keyword)
          else
            MSG_BARE
          end
        end

        def modifier?(parent)
          parent&.type?(:if, :while, :until) && parent.modifier_form?
        end
      end
    end
  end
end
