#!/usr/bin/env bash
# flux-pr-comments: the open review feedback of a PR, compact, for triage.
#
# Usage: flux-pr-comments.sh <pr-number>
#
# Prints one JSON object per line on stdout:
#   {"kind":"thread", path, line, outdated, commit, comments:[{id,author,body}]}
#     an unresolved review thread (resolved ones are omitted); `commit` is
#     the commit the first comment was posted on, `id` the numeric REST id
#     to reply to;
#   {"kind":"comment", id, author, created, body}
#     a top-level PR comment (the <!-- flux-review --> summary is excluded);
#   {"kind":"review", id, author, state, submitted, body}
#     a submitted review with a non-empty body.
# Notes (omitted resolved threads, fetch limits hit) go to stderr.
# Dependency: gh (authenticated), run from inside the repository.

set -euo pipefail

pr="${1:?usage: flux-pr-comments.sh <pr-number>}"
case "$pr" in
  *[!0-9]*) echo "[flux-pr-comments] not a PR number: $pr" >&2; exit 1 ;;
esac

# Fetch limits; a warning is printed when one is reached.
threads=100 per_thread=50 comments=100 reviews=100

# shellcheck disable=SC2016  # $-names are GraphQL variables, not shell
query='query($owner:String!, $repo:String!, $pr:Int!, $threads:Int!, $per_thread:Int!, $comments:Int!, $reviews:Int!) {
  repository(owner:$owner, name:$repo) {
    pullRequest(number:$pr) {
      reviewThreads(first:$threads) {
        pageInfo { hasNextPage }
        nodes {
          isResolved isOutdated path line
          comments(first:$per_thread) {
            totalCount
            nodes { databaseId author { login } body originalCommit { oid } }
          }
        }
      }
      comments(first:$comments) {
        pageInfo { hasNextPage }
        nodes { databaseId author { login } createdAt body }
      }
      reviews(first:$reviews) {
        pageInfo { hasNextPage }
        nodes { databaseId author { login } state submittedAt body }
      }
    }
  }
}'

# Records are objects; notes are plain strings prefixed with "NOTE:".
# shellcheck disable=SC2016  # jq program, not shell
filter='.data.repository.pullRequest as $p
| ($p.reviewThreads.nodes[] | select(.isResolved | not)
   | {kind: "thread", path, line, outdated: .isOutdated,
      commit: (.comments.nodes[0].originalCommit.oid // null),
      comments: [.comments.nodes[]
                 | {id: .databaseId, author: (.author.login // "ghost"), body}]}),
  ($p.comments.nodes[] | select(.body | contains("<!-- flux-review") | not)
   | {kind: "comment", id: .databaseId, author: (.author.login // "ghost"),
      created: .createdAt, body}),
  ($p.reviews.nodes[] | select(.body != "")
   | {kind: "review", id: .databaseId, author: (.author.login // "ghost"),
      state, submitted: .submittedAt, body}),
  ([$p.reviewThreads.nodes[] | select(.isResolved)] | length
   | select(. > 0) | "NOTE: \(.) resolved thread(s) omitted"),
  (select($p.reviewThreads.pageInfo.hasNextPage)
   | "NOTE: limit reached, only the first \($threads) review threads are listed"),
  ($p.reviewThreads.nodes[] | select(.comments.totalCount > $per_thread)
   | "NOTE: limit reached, a thread on \(.path) has \(.comments.totalCount) comments, only the first \($per_thread) are listed"),
  (select($p.comments.pageInfo.hasNextPage)
   | "NOTE: limit reached, only the first \($comments) top-level comments are listed"),
  (select($p.reviews.pageInfo.hasNextPage)
   | "NOTE: limit reached, only the first \($reviews) reviews are listed")'

# Inject the limits into the jq program (gh --jq takes no --arg).
filter="$threads as \$threads | $per_thread as \$per_thread | $comments as \$comments | $reviews as \$reviews | $filter"

gh api graphql \
  -F owner='{owner}' -F repo='{repo}' -F pr="$pr" \
  -F threads="$threads" -F per_thread="$per_thread" \
  -F comments="$comments" -F reviews="$reviews" \
  -f query="$query" --jq "$filter" |
  while IFS= read -r line; do
    case "$line" in
      NOTE:*) printf '[flux-pr-comments] %s\n' "${line#NOTE: }" >&2 ;;
      *) printf '%s\n' "$line" ;;
    esac
  done
