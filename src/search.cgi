#!/usr/bin/env ruby
# coding: utf-8

require 'cgi'


require_relative "../conf/conf"
require_relative "lib/generate_searchpage"

Encoding.default_external = Encoding::UTF_8

cgi = CGI.new

begin

if ARGV.empty? then
  $debug = File.open("/dev/pts/10", "r+") rescue StringIO.new
else
  $debug = $stdout
end

$debug.puts cgi.params

unless (id = cgi["expire"]).empty? then

  id = id.to_i
  FileUtils.rm(SEARCH_CACHE_ROOT + "/#{id}")
  print <<-"HTML"
Content-type: text/html

OK
HTML

else
  print generate_search_page(cgi)
end

rescue Exception => ex

print <<-"HTML"
Content-type: text/html

<html>
  Error
  <pre>
#{StringIO === $debug ? $debug.string : ""}
#{ex.message}
#{ex.backtrace.join "\n"}
</html>
HTML

end
