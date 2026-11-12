require "test_helper"

module RailsJsdom
  class TestCaseTest < ActiveSupport::TestCase
    test "#run_callbacks resets Node after each test" do
      test_case = RailsJsdom::TestCase.new("reset")
      RailsJsdom.stubs(:bridge).returns(bridge = mock)
      bridge.expects(:reset)

      test_case.run_callbacks(:teardown)
    end
  end
end
