require "simplecov"
SimpleCov.start do
  skip "/test/"
  enable_coverage :branch
  minimum_coverage line: 100, branch: 100
end

ENV["RAILS_ENV"] = "test"
require_relative "dummy/config/environment"
require "rails/test_help"
require "mocha/minitest"
require "rails_jsdom"
