#!/usr/bin/env ruby
# Sync MathML Core tests from the WPT (Web Platform Tests) repository.
# The WPT MathML Core tests live at:
#   https://github.com/web-platform-tests/wpt/tree/master/mathml
#
# This script extracts <math> elements from the WPT HTML/XHTML test files
# and writes them as standalone .mml files into mathml/, preserving the
# directory structure of the WPT mathml/ subtree.

require 'fileutils'
require 'pathname'
require 'nokogiri'

SCRIPT_DIR = Pathname.new(__dir__).realpath
REPO_DIR   = SCRIPT_DIR.parent
WPT_MATHML = REPO_DIR.join('.wpt-cache', 'mathml')
MATHML_DIR = REPO_DIR.join('mathml')

puts "=== MathML Core Test Sync ==="
puts "Repo:      #{REPO_DIR}"
puts "WPT cache: #{WPT_MATHML}"

# Clone the wpt monorepo shallowly if not present
unless REPO_DIR.join('.wpt-cache', '.git').exist?
  puts "Cloning wpt monorepo (shallow, mathml only)..."
  system('git', 'clone', '--depth=1', '--filter=blob:none', '--sparse',
         'https://github.com/web-platform-tests/wpt.git', REPO_DIR.join('.wpt-cache').to_s) || exit(1)
end

Dir.chdir(REPO_DIR.join('.wpt-cache'))

# Sparse checkout to only the mathml/ directory
puts "Setting up sparse checkout for mathml/..."
system('git', 'sparse-checkout', 'set', 'mathml') || exit(1)

# Pull latest
puts "Pulling latest..."
system('git', 'pull', 'origin', 'master') || exit(1)

# Extract <math> elements from WPT mathml/ into REPO_DIR/mathml/
puts "Extracting MathML to #{MATHML_DIR}/..."
FileUtils.rm_rf(MATHML_DIR)
FileUtils.mkdir_p(MATHML_DIR)

total_files = 0
total_maths = 0

Dir.glob(WPT_MATHML.join('**', '*.{html,xhtml,xml}')).each do |filepath|
  next if File.basename(filepath).start_with?('.')
  next if filepath =~ /-ref(\.|$)/

  begin
    content = File.read(filepath, encoding: 'UTF-8', invalid: :replace)

    doc = if filepath.end_with?('.xhtml')
      Nokogiri::XML(content) do |config|
        config.options = Nokogiri::XML::ParseOptions::NOERROR | Nokogiri::XML::ParseOptions::NONET
      end
    else
      Nokogiri::HTML(content) do |config|
        config.options = Nokogiri::XML::ParseOptions::RECOVER | Nokogiri::XML::ParseOptions::NOERROR
      end
    end

    doc.remove_namespaces!
    math_elements = doc.xpath('//math')

    next if math_elements.empty?

    # Preserve WPT directory structure inside mathml/
    rel_path = Pathname.new(filepath).relative_path_from(WPT_MATHML)
    base_name = rel_path.sub_ext('')
    dest_subdir = MATHML_DIR.join(rel_path.dirname)

    math_elements.each_with_index do |math, i|
      output_name = math_elements.size == 1 ? "#{base_name}.mml" : "#{base_name}.math#{i}.mml"
      output_path = MATHML_DIR.join(output_name)
      FileUtils.mkdir_p(output_path.dirname)
      File.write(output_path, math.to_xml + "\n")

      total_maths += 1
    end

    total_files += 1
  rescue => e
    warn "  Warning: Failed to parse #{filepath}: #{e.message}"
  end
end

puts "Extracted #{total_maths} MathML elements from #{total_files} files"
puts "Done. Extracted .mml files are in #{MATHML_DIR}/"
