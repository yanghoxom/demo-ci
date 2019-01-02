# ruby lencop_parser.rb http://droneci.basicinc.jp/orcainc/homeup/18038 e32d1d8ca46dc61de09e7d930b4684b996a3d932 20840 github_token
require 'nokogiri'
require "cgi"
require 'httparty'

@drone_link = ARGV[0]
@commit_id = ARGV[1]
@pull_number = ARGV[2]
@github_token = ARGV[3]
@hunk_headers_data = {}


def push_review_code_to_github
  commit_diff_hunks
  mess = pretty_rubocop_error
  push_to_github mess
end

def pretty_rubocop_error
  xml_doc = Nokogiri::XML(rubocop_errors)
  error_messages = []
  xml_doc.xpath("//file").each do |elm|
    # begin
      elm.children.search("error").each do |error|
        err_line = error.attributes["line"].value
        file_name = elm.attributes["name"].value
        error_messages <<  {path: file_name,
                            position: get_position_of_comment(file_name, Integer(err_line)),
                            body: error.attributes["message"].value
                            }
      end
    # rescue
    #   next
    # end
  end
  error_messages
end

def rubocop_errors
  data_message_errors = `git fetch origin master && git diff -z --name-only FETCH_HEAD.. \
  | xargs -0 bundle exec rubocop-select \
  | xargs bundle exec rubocop --force-exclusion --config .rubocop.yml \
    --require rubocop/formatter/checkstyle_formatter \
    --format RuboCop::Formatter::CheckstyleFormatter \
  | bundle exec checkstyle_filter-git diff FETCH_HEAD`
  data_message_errors
end

def get_position_of_comment file_name, line
  comment_pos = 0
  all_pos = @hunk_headers_data[file_name]["all_hunks_pos"].dup
  chain_pos = all_pos.keep_if {|v| v < line}
  if chain_pos.length > 1
    pivot = chain_pos.pop
    chain_pos.each do |po|
      comment_pos += get_range_from_hunk file_name, po
    end
    comment_pos += (line - pivot + 2)
  else
    comment_pos = line
  end
  comment_pos
end

def get_range_from_hunk key, pos
  @hunk_headers_data[key]["hunks"].detect {|hunk| hunk[:position] == pos}[:range]
end

def commit_diff_hunks
  diff = fetch_commit_diff
  @hunk_headers_data = parse_diff diff || []
end

def fetch_commit_diff
  HTTParty.get("https://api.github.com/repos/memsenpai/demo-ci/commits/#{@commit_id}",
    headers: {
      "Authorization": "token #{@github_token}",
      "Content-Type": "application/json",
      "Accept": "application/vnd.github.v3.diff",
      "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/69.0.3497.100 Safari/537.36"
    }
  )
end

def parse_diff diff
  res = {}
  key = nil
  diff.each_line do |str|
    new_key = str.scan(/diff --git a\/(.*)b\//).flatten[0]
    if new_key
      key = new_key.strip
      res[key] = {}
    end
    hunk_header = str.scan(/@@ \-\d+,\d+ \+(\d+),(\d+) @@/).flatten.map(&:to_i)
    if hunk_header.length > 0
      res[key]["hunks"] ||= []
      res[key]["all_hunks_pos"] ||= []
      res[key]["hunks"] << {position: hunk_header[0], range: hunk_header[1]}
      res[key]["all_hunks_pos"] << hunk_header[0]
    end
  end
  res
end

def push_to_github mess
  puts mess
  binding.pry
  HTTParty.post("https://api.github.com/repos/memsenpai/demo-ci/pulls/#{@pull_number}/reviews",
    headers: {
      "Authorization": "token #{@github_token}",
      "Content-Type": "application/json",
      "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/69.0.3497.100 Safari/537.36"
    },
    body: {
      "body": "test lencop",
      "event": "COMMENT",
      "comments": mess.to_json,
    }
  )
end


commit_diff_hunks


# pretty_rubocop_error
# rubocop_errors

# push_review_code_to_github

puts pretty_rubocop_error.to_json
