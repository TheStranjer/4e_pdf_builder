# frozen_string_literal: true

require "tmpdir"
require "open3"

RSpec.describe "pdf_builder.rb CLI" do
  let(:script) { File.expand_path("../pdf_builder.rb", __dir__) }

  it "exits 1 with a usage message when called without arguments" do
    out, status = Open3.capture2e(RbConfig.ruby, script)
    expect(status.exitstatus).to eq(1)
    expect(out).to match(/Usage:/)
  end

  it "writes a PDF when given a valid input file" do
    Dir.mktmpdir do |dir|
      output = File.join(dir, "out.pdf")
      out, status = Open3.capture2e(RbConfig.ruby, script, joe_rogan_path, output)
      expect(status.exitstatus).to eq(0), "stderr was: #{out}"
      expect(File.exist?(output)).to be true
      expect(File.size(output)).to be > 1000
    end
  end

  it "exits 1 when the input file does not exist" do
    out, status = Open3.capture2e(RbConfig.ruby, script, "no_such_file.dnd4e")
    expect(status.exitstatus).to eq(1)
    expect(out).to include("No such file")
  end

  describe "PdfBuilder.build" do
    it "returns the output path on success" do
      Dir.mktmpdir do |dir|
        output = File.join(dir, "out.pdf")
        expect(PdfBuilder.build(joe_rogan_path, output)).to eq(output)
        expect(File.exist?(output)).to be true
      end
    end

    it "raises FileNotFoundError when the input is missing" do
      expect { PdfBuilder.build("missing.dnd4e", "x.pdf") }
        .to raise_error(PdfBuilder::FileNotFoundError)
    end
  end
end
