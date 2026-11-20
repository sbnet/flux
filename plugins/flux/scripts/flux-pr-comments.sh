#!/usr/bin/env bash
# flux-pr-comments: the open review feedback of a PR, compact, for triage.
#
# Usage: flux-pr-comments.sh <pr-number>
#
# Prints one JSON object per line on stdout:
#   {"kind":"thread", id, path, line, start_line, outdated, commit,
#    comments:[{id,author,body}]}
#     an unresolved review thread (resolved ones are omitted). `id` is the
#     numeric REST id of its first comment, the one to reply to; `line`
#     falls back to the original line when the thread is outdated;
#     `commit` is the commit the first comment was posted on;
#   {"kind":"comment", id, author, created, body}
#     a top-level PR comment; flux's own summary (a body starting with
#     <!-- flux-review --> posted by the current gh user) is excluded;
#   {"kind":"review", id, author, state, submitted, body}
#     a submitted, non-dismissed review with a non-empty body.
# Notes on fetch limits reached go to stderr.
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
  viewer { login }
  repository(owner:$owner, name:$repo) {
    pullRequest(number:$pr) {
      reviewThreads(first:$threads) {
        pageInfo { hasNextPage }
        nodes {
          isResolved isOutdated path line originalLine startLine originalStartLine
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
filter='.data.viewer.login as $me
| .data.repository.pullRequest as $p
| ($p.reviewThreads.nodes[] | select(.isResolved | not)
   | {kind: "thread", id: (.comments.nodes[0].databaseId // null), path,
      line: (.line // .originalLine),
      start_line: (.startLine // .originalStartLine),
      outdated: .isOutdated,
      commit: (.comments.nodes[0].originalCommit.oid // null),
      comments: [.comments.nodes[]
                 | {id: .databaseId, author: (.author.login // "ghost"), body}]}),
  ($p.comments.nodes[]
   | select(((.body | startswith("<!-- flux-review -->")) and .author.login == $me) | not)
   | {kind: "comment", id: .databaseId, author: (.author.login // "ghost"),
      created: .createdAt, body}),
  ($p.reviews.nodes[]
   | select(.body != "" and .state != "PENDING" and .state != "DISMISSED")
   | {kind: "review", id: .databaseId, author: (.author.login // "ghost"),
      state, submitted: .submittedAt, body}),
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
