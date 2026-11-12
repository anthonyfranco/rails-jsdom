module RailsJsdom
  class TurboStreamDeliveries # :nodoc:
    def initialize
      @delivered = {}
    end

    def undelivered_messages(session, streams)
      previously_delivered = @delivered.fetch(session, {})
      @delivered[session] = streams.to_h { |stream| [ stream, broadcasts(stream).size ] }
      streams.flat_map { |stream| new_messages(stream, previously_delivered) }
    end

    private

    def new_messages(stream, previously_delivered)
      sent = broadcasts(stream)
      unseen = sent.drop(previously_delivered.fetch(stream, sent.size))
      unseen.map { |payload| ActiveSupport::JSON.decode(payload) }.grep(String)
    end

    def broadcasts(stream)
      ActionCable.server.pubsub.broadcasts(stream)
    end
  end
end
