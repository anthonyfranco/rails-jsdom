module RailsJsdom
  class Bridge # :nodoc:
    def initialize(command:, setup:, logger:)
      @command = command
      @setup = setup
      @logger = logger
    end

    def call(message, &on_fetch)
      start unless started?
      write(message)
      receive(&on_fetch)
    end

    def started?
      !!@input
    end

    def reset
      call(command: "reset") if started?
    end

    private

    def start
      @input, @output, error, @process = Open3.popen3(*@command)
      @log = Thread.new { log(error) }
      write(@setup)
      receive
    end

    def log(error)
      error.each_line { |line| @logger.info("[rails_jsdom] #{line.chomp}") }
      error.close
    end

    def stop
      @input.close
      @output.close
      Process.kill("TERM", @process.pid) if @process&.alive?
      @log.join
      @input = nil
    end

    def receive(&on_fetch)
      message = read
      case message.fetch("type")
      when "fetch"
        write(type: "fetch_response", id: message.fetch("id"), response: answer(message.fetch("request"), &on_fetch))
        receive(&on_fetch)
      when "error"
        raise Error, message.fetch("message")
      else
        message.fetch("value")
      end
    end

    def answer(request, &on_fetch)
      on_fetch.call(request)
    rescue StandardError
      stop
      raise
    end

    def read
      line = @output.gets
      if line
        JSON.parse(line)
      else
        stop
        raise Error, "The RailsJsdom Node process exited. See the [rails_jsdom] lines in the Rails log."
      end
    end

    def write(payload)
      @input.puts(JSON.generate(payload))
      @input.flush
    end
  end
end
