
err=$( git fetch origin master && git diff -z --name-only FETCH_HEAD.. \
 | xargs -0 bundle exec rubocop-select \
 | xargs bundle exec rubocop --force-exclusion --config .rubocop.yml)

echo $err
mess=`bundle exec ruby parse_rubocop_xml.rb $err`
echo $mess
if [ "$mess" ]; then
  POST_BODY="{\"body\": \"RUBOCOP WARNING!!! \n $mess  \n\n $CIRCLE_BUILD_URL\"}"
  curl -XPOST \
    -H "Authorization: token $GITHUB_ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$POST_BODY" \
    https://api.github.com/repos/memsenpai/demo-ci/issues/$CI_PULL_REQUEST/comments
fi