# frozen_string_literal: true

require "rspec"
require_relative "../lib/pdf_builder"

module SpecHelpers
  FIXTURE_DIR = File.expand_path("fixtures", __dir__)

  def fixture_path(name)
    File.join(FIXTURE_DIR, name)
  end

  def joe_rogan_path
    fixture_path("joe_rogan.dnd4e")
  end

  def joe_rogan_character
    @joe_rogan_character ||= PdfBuilder::Parser.parse_file(joe_rogan_path)
  end
end

RSpec.configure do |config|
  config.include SpecHelpers
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
  config.example_status_persistence_file_path = ".rspec_status"
end
