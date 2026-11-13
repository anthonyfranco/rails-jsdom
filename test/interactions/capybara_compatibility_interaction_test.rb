require "test_helper"

class CapybaraCompatibilityInteractionTest < RailsJsdom::TestCase
  FILES = File.expand_path("../fixtures/files", __dir__)

  setup do
    mount_html <<~HTML
      <ul id="menu">
        <li id="outer"><ul><li id="inner" class="item"><button type="button" onclick="this.textContent = 'Clicked'">Tap</button><span id="leaf">Leaf</span></li></ul></li>
      </ul>
      <form id="search">
        <input placeholder="Search" value="">
        <input placeholder="Filter" value="">
        <input type="checkbox" id="plain" hidden><label for="plain">Plain</label>
        <input type="radio" name="size" id="large" hidden><label for="large">Large</label>
        <button type="button" onclick="this.dataset.sent = 'yes'">Send</button>
        <a href="/one" onclick="this.dataset.hit = 'one'; return false">Edit</a>
        <a href="/two" onclick="this.dataset.hit = 'two'; return false">Edit</a>
        <input type="file" id="doc" placeholder="Doc">
        <div class="row" id="first-row">Row A</div>
        <div class="row" id="second-row">Row B</div>
      </form>
    HTML
  end

  test "ancestor returns the nearest ancestor that matches" do
    assert_equal "inner", find("#leaf").ancestor("li")["id"]
    assert_equal "outer", find("#leaf").ancestor("#outer")["id"]
  end

  test "ancestor applies filters" do
    assert_equal "outer", find("#leaf").ancestor("li:not(.item)")["id"]
    assert_equal "inner", find("#leaf").ancestor("li", text: "Tap", visible: true)["id"]
  end

  test "ancestor fails when no ancestor matches" do
    assert_raises(RailsJsdom::Error) { find("#leaf").ancestor("table") }
    assert_raises(RailsJsdom::Error) { find("#leaf").ancestor("li", text: "Missing") }
  end

  test "an element fills in a field inside it" do
    find("#search").fill_in "Search", with: "mugs"

    assert_equal "mugs", find_field("Search").value
  end

  test "an element clicks buttons and links inside it" do
    find("#search").click_on "Send"

    assert_selector "#search button[data-sent]"
    find("#search").click_link "Edit", href: "/two"

    assert_selector "a[data-hit=two]"
    find("#menu").click_button "Tap"

    assert_selector "#menu button", text: "Clicked"
  end

  test "an element checks, unchecks and chooses fields inside it" do
    form = find("#search")
    form.check "Plain"

    assert_checked_field "Plain", visible: :all
    form.uncheck "Plain"

    assert_unchecked_field "Plain", visible: :all
    form.choose "Large"

    assert_checked_field "Large", visible: :all
  end

  test "an element asserts and predicates fields, buttons, links and css inside it" do
    form = find("#search")

    form.assert_field "Search"
    form.assert_no_field "Missing"
    form.assert_button "Send"
    form.assert_no_button "Missing"
    form.assert_link "Edit", count: 2
    form.assert_no_link "Missing"

    assert form.has_field?("Filter")
    assert form.has_no_field?("Missing")
    assert form.has_button?("Send")
    assert form.has_no_button?("Missing")
    assert form.has_link?("Edit", href: "/one")
    assert form.has_no_link?("Missing")
    assert form.has_css?("button")
    assert form.has_no_css?("table")
  end

  test "an element selects, unselects and attaches files inside it" do
    mount_html <<~HTML
      <div id="box"><select id="s" multiple><option>Red</option><option selected>Blue</option></select><input type="file" id="f"></div>
    HTML

    box = find("#box")
    box.select "Red", from: "s"
    box.unselect "Blue", from: "s"
    box.attach_file "f", "#{FILES}/hello.txt"

    assert_equal "Red", evaluate_script("[...document.querySelector('#s').selectedOptions].map(o => o.text).join()")
    assert_equal "hello.txt", evaluate_script("document.querySelector('#f').files[0].name")
  end

  test "using_wait_time yields and returns the block's value" do
    ran = false
    using_wait_time(10) { ran = true }

    assert ran
    assert_equal 3, using_wait_time(1) { 3 }
  end

  test "wait: is ignored by finders, predicates and assertions" do
    assert_equal "Send", find_button("Send", wait: 5).text
    assert_equal "form", find("#search", wait: 5).tag_name
    assert_equal 2, all(".row", wait: 5).size
    assert_equal "Row A", first(".row", wait: 5).text
    assert_equal "Search", find_field("Search", wait: 5)["placeholder"]
    assert_equal "Edit", find_link("Edit", href: "/one", wait: 5).text
    assert has_selector?("#menu", wait: 5)
    assert has_no_selector?("#missing", wait: 5)
    assert has_css?("#menu", wait: 5)
    assert has_field?("Search", wait: 5)
    assert has_no_field?("Missing", wait: 5)
    assert has_button?("Send", wait: 5)
    assert has_no_button?("Missing", wait: 5)
    assert has_link?("Edit", count: 2, wait: 5)
    assert has_no_link?("Missing", wait: 5)
    assert has_text?("Row A", wait: 5)
    assert has_no_text?("Missing", wait: 5)
    assert has_title?("", wait: 5)
    assert has_no_title?("Missing", wait: 5)
    assert has_current_path?("/", wait: 5)
    assert has_no_current_path?("/missing", wait: 5)
    assert_text "Row A", wait: 5
    assert_no_text "Missing", wait: 5
    assert_title "", wait: 5
    assert_no_title "Missing", wait: 5
    assert_current_path "/", wait: 5
    assert_no_current_path "/missing", wait: 5
    assert_selector "#menu", wait: 5
    assert_no_selector "#missing", wait: 5
    assert_field "Search", wait: 5
    assert_no_field "Missing", wait: 5
    assert_button "Send", wait: 5
    assert_no_button "Missing", wait: 5
    assert_link "Edit", count: 2, wait: 5
    assert_no_link "Missing", wait: 5
  end

  test "wait: is ignored by actions and scopes" do
    fill_in "Search", with: "mugs", wait: 5
    click_on "Send", wait: 5
    click_button "Send", wait: 5
    click_link "Edit", href: "/one", wait: 5
    click "Send", wait: 5
    hover "Send", wait: 5
    double_click "Send", wait: 5
    right_click "Send", wait: 5
    check "Plain", wait: 5
    uncheck "Plain", wait: 5
    choose "Large", wait: 5
    attach_file "Doc", "#{FILES}/hello.txt", wait: 5

    within("#search", wait: 5) { assert_field "Search" }
    mount_html "<fieldset id='f'><input placeholder='x'></fieldset><table id='t'><tr><td>c</td></tr></table><select id='s'><option>A</option></select>"

    within_fieldset("f", wait: 5) { assert_field "x" }
    within_table("t", wait: 5) { assert_text "c" }
    select "A", from: "s", wait: 5
  end

  test "unknown keywords still raise" do
    assert_raises(ArgumentError) { has_text?("x", focused: true) }
    assert_raises(ArgumentError) { assert_current_path("/", scroll: true) }
    assert_raises(ArgumentError) { select "A", scroll_to: true }
    assert_raises(ArgumentError) { within_table("t", focused: true) { nil } }
    assert_raises(ArgumentError) { within_fieldset("t", focused: true) { nil } }
    assert_raises(ArgumentError) { find("#search", focused: true) }
  end

  test "within filters pick one of several matches" do
    within("div.row", text: "Row B") { assert_text "Row B" }
    within(find("#search"), wait: 5) { assert_field "Search" }
    assert_raises(RailsJsdom::Error) { within("div.row", text: "Missing", &:itself) }
  end

  test "choose, check and uncheck accept allow_label_click and work on inputs only a label shows" do
    check "Plain", allow_label_click: true

    assert_checked_field "Plain", visible: :all
    uncheck "Plain", allow_label_click: true

    assert_unchecked_field "Plain", visible: :all
    choose "Large", allow_label_click: true

    assert_checked_field "Large", visible: :all
  end

  test "has_css? and assert_css are aliases of the selector methods" do
    assert has_css?(".row", count: 2)
    assert has_no_css?(".missing")
    assert_css ".row", count: 2
    assert_no_css ".missing"
  end

  test "fill_in filters by placeholder, with or without a locator" do
    fill_in placeholder: "Filter", with: "x"
    fill_in "Search", placeholder: "Search", with: "y"

    assert_equal "x", find_field(placeholder: "Filter").value
    assert_equal "y", find_field(placeholder: "Search").value
    assert_raises(RailsJsdom::Error) { fill_in "Search", placeholder: "Filter", with: "z" }
    assert_raises(RailsJsdom::Error) { fill_in placeholder: "Nope", with: "z" }
  end

  test "find_field, has_field? and assert_field filter by placeholder, as a String or a Regexp" do
    assert_equal "Search", find_field(placeholder: "Search")["placeholder"]
    assert has_field?(placeholder: /Fil/)
    assert has_no_field?(placeholder: "Nope")
    assert_field placeholder: "Filter"
    assert_no_field placeholder: "Nope"
  end

  test "click_link filters by href, with or without a locator" do
    click_link "Edit", href: "/two"

    assert_selector "a[data-hit=two]"
    click_link href: "/one"

    assert_selector "a[data-hit=one]"
    assert_raises(RailsJsdom::Error) { click_link "Edit" }
    assert_raises(RailsJsdom::Error) { click_link "Edit", href: "/three" }
  end

  test "click_button and click_on without a locator use the filters" do
    click_button text: "Send"

    assert_selector "#search button[data-sent]"
    click_on href: "/one"

    assert_selector "a[data-hit=one]"
  end

  test "click accepts filters that pick one of several matches" do
    click "Edit", href: "/one"
    double_click "Send", text: "Send"
    right_click "Send", text: "Send"
    hover "Send", text: "Send"

    assert_selector "a[data-hit=one]"
  end

  test "an action's filter does not fit the wrong kind of element" do
    assert_raises(RailsJsdom::Error) { fill_in placeholder: "Doc", with: "x" }
  end
end
