# frozen_string_literal: true

require_relative "pdf_builder/character"
require_relative "pdf_builder/parser"
require_relative "pdf_builder/renderer"

module PdfBuilder
  VERSION = "0.1.0"

  class Error < StandardError; end
  class FileNotFoundError < Error; end

  # Convenience entry point: parse `input` and write a PDF to `output`.
  def self.build(input_path, output_path)
    raise FileNotFoundError, "No such file: #{input_path}" unless File.exist?(input_path)

    character = Parser.parse_file(input_path)
    Renderer.render(character, output_path)
    output_path
  end
end
