require "active_support/core_ext/module/delegation"

module RailsJsdom
  # The object behind TestHelper#page, for tests written as
  # `page.has_css?(...)` or `page.find(...)`. Every TestHelper method can be
  # called on it.
  #
  #   assert page.has_css?(".cart-item", count: 2)
  #   page.find("#menu").click
  class Page
    delegate(*TestHelper.public_instance_methods - [ :page ], to: :@test)

    def initialize(test) # :nodoc:
      @test = test
    end

    # The HTML of the whole page.
    def body
      @test.rails_jsdom_page_snapshot.fetch("html")
    end
    alias_method :html, :body

    # The page title.
    def title
      @test.rails_jsdom_page_snapshot.fetch("title")
    end

    # The visible text of the page, or of the current TestHelper#within scope.
    def text
      @test.page_text
    end
  end
end
