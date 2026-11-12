module RuboCop
  module Cop
    module Readability
      class NoExplicitReturn < RuboCop::Cop::Base
        MSG = "Do not write `return`. Use implicit returns: make the value the method's last expression, use `if`/`else` or a ternary for branches, " \
              "and replace an early return with a condition around the rest of the method or with a named method."

        def on_return(node)
          add_offense(node)
        end
      end
    end
  end
end
