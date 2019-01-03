require 'nokogiri'
require "cgi"
require 'pry'
require 'pry-byebug'
xml_doc = Nokogiri::XML(ARGV[0])
error_messages = []
xml_doc.xpath("//file").each do |elm|
  begin
    elm.children.search("error").each do |error|
      # error_messages << "- #{elm.attributes["name"].value}:#{error.attributes["line"].value}: #{error.attributes["message"].value}\\n"
      error_messages.push({
        "path": elm.attributes['name'].value,
        "position": error.attributes['line'].value.to_i,
        "body": error.attributes['message'].value
      })
    end
  rescue => e
    next
  end
end
data = {
  "commit_id": ARGV[-1],
  "body": 'RUBOCOP WARNING!!!',
  "event": 'COMMENT',
  "comments": error_messages
}
puts data.to_s.gsub(/:([^=]*)=>([^\,\}]*)/, "\"\\1\": \\2").gsub(/{:([^=]*)=>([^\,\}]*)/, "{\"\\1\": \\2")
