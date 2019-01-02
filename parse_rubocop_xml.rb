require 'nokogiri'
require "cgi"
xml_doc = Nokogiri::XML(ARGV.join(" "))
error_messages = ""
xml_doc.xpath("//file").each do |elm|
  begin
    elm.children.search("error").each do |error|
      error_messages << "- #{elm.attributes["name"].value}:#{error.attributes["line"].value}: #{error.attributes["message"].value}\\n"
    end
  rescue => e
    next
  end
end
puts CGI::escapeHTML(error_messages)
