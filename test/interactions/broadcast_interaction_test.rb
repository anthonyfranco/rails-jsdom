require "test_helper"

class BroadcastInteractionTest < RailsJsdom::TestCase
  test "a page subscribed with turbo_stream_from receives a broadcast" do
    visit root_path
    Turbo::StreamsChannel.broadcast_append_to("items", target: "items", html: "<li>Broadcast item</li>")

    assert_text "Broadcast item"
  end

  test "a subscribed stream receives a broadcast append" do
    mount_html stream_page(Turbo::StreamsChannel.signed_stream_name("rails_jsdom"))
    Turbo::StreamsChannel.broadcast_append_to("rails_jsdom", target: "list", html: "<p>Delivered</p>")

    assert_dom "#list p", text: "Delivered"
  end

  test "a broadcast to a stream the page does not subscribe to stays off the page" do
    mount_html stream_page(Turbo::StreamsChannel.signed_stream_name("rails_jsdom"))
    Turbo::StreamsChannel.broadcast_append_to("elsewhere", target: "list", html: "<p>Delivered</p>")

    assert_dom "#list p", count: 0
  end

  test "a stream source with a forged signature receives no broadcast" do
    mount_html stream_page("forged--signature")
    Turbo::StreamsChannel.broadcast_append_to("rails_jsdom", target: "list", html: "<p>Delivered</p>")

    assert_dom "#list p", count: 0
  end

  test "a broadcast made before the page subscribed stays off the page" do
    Turbo::StreamsChannel.broadcast_append_to("rails_jsdom", target: "list", html: "<p>Early</p>")
    mount_html stream_page(Turbo::StreamsChannel.signed_stream_name("rails_jsdom"))

    assert_dom "#list p", count: 0
  end

  test "a broadcast from a job the test performs reaches the page" do
    mount_html stream_page(Turbo::StreamsChannel.signed_stream_name("rails_jsdom"))
    perform_enqueued_jobs { Turbo::StreamsChannel.broadcast_append_later_to("rails_jsdom", target: "list", html: "<p>Later</p>") }

    assert_dom "#list p", text: "Later"
  end

  test "a delivered broadcast is not applied again by later actions" do
    mount_html stream_page(Turbo::StreamsChannel.signed_stream_name("rails_jsdom"))
    Turbo::StreamsChannel.broadcast_append_to("rails_jsdom", target: "list", html: "<p>Once</p>")
    evaluate_script("document.title")
    evaluate_script("document.title")

    assert_dom "#list p", count: 1
  end

  test "a stream source added to the page later receives broadcasts" do
    mount_html "<div id='list'></div>"
    evaluate_script("document.body.insertAdjacentHTML('beforeend', #{stream_source(Turbo::StreamsChannel.signed_stream_name('rails_jsdom')).to_json})")
    Turbo::StreamsChannel.broadcast_append_to("rails_jsdom", target: "list", html: "<p>Late subscriber</p>")

    assert_dom "#list p", text: "Late subscriber"
  end

  private

  def stream_page(signed_name)
    "#{stream_source(signed_name)}<div id='list'></div>"
  end

  def stream_source(signed_name)
    "<turbo-cable-stream-source channel=\"Turbo::StreamsChannel\" signed-stream-name=\"#{signed_name}\"></turbo-cable-stream-source>"
  end
end
