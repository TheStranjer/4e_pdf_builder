#!/usr/bin/env ruby
# Usage:
#   ./pdf_builder.rb <input.dnd4e> [output.pdf]
#
# Reads a D&D Insider Character Builder save file and writes a PDF
# character sheet next to it (or to the given output path).

require_relative "lib/pdf_builder"

def usage_and_exit
  warn "Usage: #{File.basename($PROGRAM_NAME)} <input.dnd4e> [output.pdf]"
  exit 1
end

usage_and_exit if ARGV.empty? || %w[-h --help].include?(ARGV.first)

input  = ARGV[0]
output = ARGV[1] || input.sub(/\.dnd4e\z/i, "") + ".pdf"

begin
  path = PdfBuilder.build(input, output)
  puts "Wrote #{path}"
rescue PdfBuilder::FileNotFoundError => e
  warn e.message
  exit 1
rescue PdfBuilder::Parser::ParseError => e
  warn "Failed to parse: #{e.message}"
  exit 2
end
