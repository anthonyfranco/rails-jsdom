require "test_helper"

class SessionInteractionTest < RailsJsdom::TestCase
  test "each session has its own cookies" do
    using_session(:ada) { sign_in "Ada" }
    using_session(:grace) { visit messages_path }

    using_session(:ada) do
      visit messages_path

      assert_text "Signed in as Ada"
    end
  end

  test "a session that never signed in stays signed out" do
    using_session(:ada) { sign_in "Ada" }
    using_session(:grace) { visit messages_path }

    using_session(:grace) { assert_text "Signed in as nobody" }
  end

  test "a broadcast from one session reaches the page of another" do
    using_session(:ada) do
      sign_in "Ada"
      visit messages_path
    end
    using_session(:grace) do
      sign_in "Grace"
      visit messages_path
      fill_in "Message", with: "Hello Ada"
      click_on "Send"
    end

    using_session(:ada) { assert_selector "#messages li", text: "Grace: Hello Ada" }
  end

  test "the default session keeps its page while another session runs" do
    visit forms_path
    using_session(:other) { visit root_path }

    assert_current_path "/forms"
  end

  test "the default session keeps its cookies while another session signs in" do
    using_session(:other) { sign_in "Other" }
    visit messages_path

    assert_text "Signed in as nobody"
  end

  test "using_session returns to the previous session when its block raises" do
    visit forms_path
    assert_raises(RuntimeError) { using_session(:other) { raise "stop" } }

    assert_current_path "/forms"
  end

  test "a session can be named with a string" do
    using_session("ada") { sign_in "Ada" }

    using_session(:ada) do
      visit messages_path

      assert_text "Signed in as Ada"
    end
  end

  private

  def sign_in(name)
    visit login_path
    fill_in "Your name", with: name
    click_on "Sign in"
  end
end
