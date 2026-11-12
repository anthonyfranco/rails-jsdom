# frozen_string_literal: true

require "rubocop"

module RuboCop
  module Cop
    module Readability
      class VerbLedBangMethod < Base
        MSG = "Begin the bang method `%<name>s` with a verb that describes the operation (for example `disable_strict_loading!`)."

        VERBS = %w[
          accept acknowledge activate add adopt advance allocate apply approve archive assess assign attach authenticate
          authorize begin block broadcast build bump calculate cancel canonicalize capture change charge check claim
          clean clear close collect commit complete compute confirm connect consume continue convert copy create
          deactivate decide decline decrement defer delete deliver deny deploy destroy detach disable discard dismiss
          dispatch drain drop emit enable end enqueue ensure enter establish evaluate execute expire extend fail fetch
          fill finalize finish flag flush follow force freeze generate grant handle hide import increment initialize
          initiate insert install invalidate invoke issue join link load lock log mark merge migrate move notify open
          pause perform persist pick place post preflight prepare process promote propose provision publish pull purge
          push put queue raise read rebuild receive recompute reconcile record recover refresh register reject release
          reload remove rename render reopen replace report request require reschedule reserve reset resolve restart
          restore resume retry return revert revoke roll rotate run save schedule seed send set settle show
          shutdown skip soft_delete sort split start stop store submit sunset supersede supply suspend switch sync
          take terminate toggle touch track transition trigger unarchive unblock unlink unlock unpause update upgrade
          upsert use validate verify void wait write
        ].freeze

        def on_def(node)
          check(node)
        end

        def on_defs(node)
          check(node)
        end

        private

        def check(node)
          name = node.method_name.to_s
          add_offense(node.loc.name, message: format(MSG, name: name)) if name.end_with?("!") && !verb_led?(name.delete_suffix("!"))
        end

        def verb_led?(stem)
          verbs.any? { |verb| stem == verb || stem.start_with?("#{verb}_") }
        end

        def verbs
          VERBS + Array(cop_config["AllowedVerbs"]).map(&:to_s)
        end
      end
    end
  end
end
