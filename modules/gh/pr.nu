use std/log

const command_base = 'gh pr'

# List github pull requests
#
# Parameters can specified with --filter to narrow down the resulting list.
# Useful filters:
#   state - open, closed, all, default: open
#   head - org:ref-name, eg: octocat:test-branch
#   base - filter pulls by base branch name, 
#   For more filters see
#       ref: https://docs.github.com/en/rest/pulls/pulls?apiVersion=2022-11-28#list-pull-requests--parameters
#
export def --env list [
    --repo: string                # repository, e.g. dennybaa/foobar
    --filter: record={}           # parameters to filter results
    --args: list<string>=[]
] {
    log debug $'=> ($command_base) list --repo=($repo)'
    let query = $filter | url build-query
    api ...$args (
        $'repos/($repo | default-repo)/pulls'
          | if ($query | is-empty) { $in } else { $'($in)?($query)' }
    )
}

# Get a github pull request by number
#
# Returns pull request.
export def --env get [
    pull_number: int
    --repo: string
    --args: list<string>=[]
] {
    log debug $'=> ($command_base) get --repo=($repo)'
    (api ...$args
        $'repos/($repo | default-repo)/pulls/($pull_number)'
    )
}
