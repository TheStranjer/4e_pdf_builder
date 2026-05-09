# 4e PDF Builder

A small Ruby CLI that turns a D&D 4th Edition character file (`.dnd4e`, the XML
save format produced by the Wizards of the Coast Character Builder) into a
printable PDF character sheet.

## What it does

Given a `.dnd4e` file, it parses the character's stats, defenses, hit points,
ability scores, senses, movement, action points, race features, basic attacks,
and attack/damage workspaces, and renders them into a single-page PDF laid out
in the familiar three-column character-sheet style.

## Requirements

- Ruby (see `.ruby-version` / `Gemfile` for the pinned version)
- [Bundler](https://bundler.io/)

Runtime dependencies (installed via Bundler):

- `nokogiri` — XML parsing
- `prawn` — PDF generation
- `ostruct`

## Installation

Clone the repo and install the gems:

```sh
git clone <repo-url> 4e_pdf_builder
cd 4e_pdf_builder
bundle install
```

## Usage

```sh
./pdf_builder.rb <input.dnd4e> [output.pdf]
```

If no output path is given, the PDF is written next to the input with the same
basename (e.g. `Aric.dnd4e` → `Aric.pdf`).

Examples:

```sh
# Write Aric.pdf next to Aric.dnd4e
./pdf_builder.rb characters/Aric.dnd4e

# Choose an explicit output path
./pdf_builder.rb characters/Aric.dnd4e ~/Desktop/aric-sheet.pdf

# Run via bundler if the script isn't on a PATH that has the right Ruby
bundle exec ruby pdf_builder.rb characters/Aric.dnd4e
```

On success it prints `Wrote <path>`. Exit codes:

- `0` — PDF written
- `1` — input file not found / bad usage
- `2` — failed to parse the `.dnd4e` file

## Project layout

```
pdf_builder.rb              # CLI entry point
lib/pdf_builder.rb          # PdfBuilder.build(input, output) convenience API
lib/pdf_builder/
  parser.rb                 # .dnd4e (XML) → Character
  character.rb              # In-memory character model
  renderer.rb               # Top-level Prawn renderer
  renderer/                 # One file per section of the sheet
spec/                       # RSpec suite + a sample fixture
```

A sample character file lives at `spec/fixtures/joe_rogan.dnd4e` if you want
something to try the CLI against.

## Library use

`pdf_builder.rb` is a thin wrapper around the library:

```ruby
require_relative "lib/pdf_builder"

PdfBuilder.build("characters/Aric.dnd4e", "Aric.pdf")
```

## Development

Run the test suite:

```sh
bundle exec rspec
```

Lint:

```sh
bundle exec rubocop
```
