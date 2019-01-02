err=$( git fetch origin master && git diff -z --name-only FETCH_HEAD.. \
 | xargs -0 bundle exec rubocop-select \
 | xargs bundle exec rubocop --force-exclusion --config .rubocop.yml \
  --require rubocop/formatter/checkstyle_formatter \
  --format RuboCop::Formatter::CheckstyleFormatter \
 | bundle exec checkstyle_filter-git diff FETCH_HEAD)

echo $err
mess=`bundle exec ruby parse_rubocop_xml.rb $err`
echo $mess
if [ "$mess" ]; then
  POST_BODY="{\"body\": \"RUBOCOP WARNING!!! \n $mess  \n\n $CIRCLE_BUILD_URL\"}"
  curl -XPOST \
    -H "Authorization: token $GITHUB_ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$POST_BODY" \
    https://api.github.com/repos/memsenpai/demo-ci/issues/${CI_PULL_REQUEST##*/}/comments
fi

# # @drone_link = ARGV[0]
# # @commit_id = ARGV[1]

# pull_number=${CI_PULL_REQUEST##*/}
# echo $pull_number
# # @github_token = ARGV[3]

# mess=$(bundle exec ruby auto_comment.rb $CIRCLE_BUILD_URL $CIRCLE_SHA1 $pull_number $GITHUB_ACCESS_TOKEN)
# echo $mess
# if [ "$mess" ]; then
#   curl -X POST \
#   -H "Authorization: token $GITHUB_ACCESS_TOKEN"\
#   -H "Content-Type: application/json"\
#   -d "{\
#         \"body\": \":warning: :warning: :warning: **RUBOCOP WARNING!!!** PLEASE CHECK IT AGAIN \",\
#         \"event\": \"COMMENT\",\
#         \"comments\": $mess \
#   }" -v https://api.github.com/repos/memsenpai/demo-ci/pulls/$pull_number/reviews
# fi
