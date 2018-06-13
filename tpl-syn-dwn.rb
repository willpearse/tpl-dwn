#!/usr/bin/ruby
require 'optparse'
require 'open-uri'
require 'nokogiri'
require 'open3'
require 'csv'
require 'rest-client'

options = {}
OptionParser.new do |opts|
  #Defaults
  options[:tpl_dir] = nil
  options[:output] = nil
  options[:delay] = 1
  options[:verbose] = false
  
  opts.banner = "tpl-dwn-syn: Downloading all of The Plant List's synonyms\nUsage: tpl-syn-dwn.rb [options]"
  opts.on_tail("-h", "--help", "Show this message") do
    puts opts
    exit
  end

  opts.on("-t DIRECTORY", "--tpl DIRECTORY", "Directory with TPL dump") {|x| options[:tpl_dir] = x.to_s}
  opts.on("-o DIRECTORY", "--output DIRECTORY", "Directory to store synoynm files") {|x| options[:output] = x.to_s}
  opts.on("-d SECONDS", "--delay SECONDS", "How long to wait between species searches (default: 1 sec)") {|x| options[:delay] = x.to_i}
  opts.on("-v", "--verbose", "Run verbosely") {|x| options[:verbose] = true}
  opts.on("-")
end.parse!

# Argument handling
if not Dir.exist? options[:tpl_dir]
  puts "Must specify (existing) TPL dump directory; exiting"
  puts "Make sure you've run ./tpl-dwn.rb (or similar) first"
  puts "Run ./tpl-dwn-syn.rb --help (or similar) to get options"
  exit(false)
end
if not Dir.exist? options[:output]
  puts "Must specify (existing) folder to store synonyms; exiting"
  puts "Run ./tpl-dwn-syn.rb --help (or similar) to get options"
  exit(false)
end

# Doing work
Dir["#{options[:tpl_dir]}*.csv"].each do |tpl_file|
  if options[:verbose] then puts "Searching #{tpl_file}" end
  CSV.open("#{options[:output]}/#{File.basename(tpl_file)}", "wb") do |output|
    output << ["accepted", "synonym", "status"]
    CSV.foreach("#{tpl_file}", headers: true) do |row|
      search_term = "#{row[4]}+#{row[6]}"
      puts search_term
      species = search_term.sub("+", "_")
      page = Nokogiri::HTML(RestClient.get("http://www.theplantlist.org/tpl1.1/search?q=#{search_term}").body)
      page.xpath("//tr").each_with_index do |entry, i|
        if i == 0 then next end
        synonym = entry.element_children[0].text
        status = entry.element_children[1].text
        output << [species, synonym, status]
      end
      sleep options[:delay]
      break
    end
  end
end
