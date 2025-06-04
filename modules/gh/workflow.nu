use std/log
use ./branch.nu

const command_base = 'gh workflow'


# List github workflows
#
# Returns the list of workflows.
export def list [
    --repo: string
    --args: list<string>=[]
]: nothing -> any {
    log debug $'=> ($command_base) list --repo=($repo)'
    (api ...$args
        $'repos/($repo | default-repo)/actions/workflows'
    )
    | api-wrap
}


# List workflow runs by workflow id or filename
#
# Parameters can specified with --filter to narrow down the result list, such as
# for example: actor, branch, check_suite_id, created, event, head_sha, status.
export def "run list" [
    workflow                      # workflow id or filename (e.g. test.yaml)
    --repo: string                # repository, e.g. dennybaa/foobar
    --filter: record={}           # parameters to filter results
    --args: list<string>=[]
] {
    log debug $'=> ($command_base) run list --repo=($repo)'
    let query = $filter | url build-query
    api ...$args (
        $'repos/($repo | default-repo)/actions/workflows/($workflow)/runs'
        | if ($query | is-empty) { $in } else { $'($in)?($query)' }
    )
}


# Run a workflow (create the workflow_dispatch event)
#
# Find matching workflows and dispatch the first found.
# Note: workflow file must have on.workflow_dispatch!
#
# Returns workflow record {workflow: record, error?: record}
export def run [
    workflow: string        # lookup workflow by name or filename
    --repo: string          # repository, e.g. dennybaa/foobar
    --ref: string = main    # ref/branch, e.g: v1.2.3
    --inputs: record        # workflow input parameters
    --args: list<any>=[]
] {
    log debug $'=> ($command_base) run ($workflow) --repo=($repo) --ref=($ref)'

    let found = list --args=$args --repo=$repo
      | if ($in.error? != null) {
            return $in
        } else { $in }

    let matched = $found.workflows
      | find --columns=['name','path'] --regex=$workflow
      | if ($in | length) == 0 {
            let err = $"No workflow found matching /($workflow)/!"
            log error $err; return {error: {message: $err}}
        } else { $in }
      | if ($in | length) > 1 {
            log warning $"Multiple workflows found, the first will be only dispatched!"
            $in
        }

    let result = { workflow: $matched.0 }
    let body = {
        ref: ($ref | default 'main')
        inputs: ($inputs | default {})
    }

    let dispatch = $body | to json | (api
        --method 'POST'
        $'repos/($repo | default-repo)/actions/workflows/($matched.0.id)/dispatches'
        --input '-'
    )

    if ($dispatch.error? | is-not-empty) {
        log error ($dispatch.error | to text)
        return ( $result | insert "error" $dispatch.error )
    }

    log info $"Dispatched workflow ($found.name) in repository ($repo | default-repo)"
    return $result
}


# Run a workflow (create the workflow_dispatch event)
#
# Find matching workflows and dispatch the first found. Also wait for the worklow to get dispatched.
# Note: this command waits for the dispatch to happen on the sha which is the head prior to run invocation.
#
# Returns workflow run record {run: record, error?: record}
export def --env "run get-dispatched" [
    workflow: string        # lookup workflow by name or filename
    --interval=5sec         # interval
    --timeout = 15sec       # timeout
    --repo: string          # repository, e.g. dennybaa/foobar
    --ref: string = main    # ref/branch, e.g: v1.2.3
    --inputs: record        # workflow input parameters
    --args: list<any>=[]
] {
    log debug $'=> ($command_base) run get-dispatched ($workflow) --repo=($repo) --ref=($ref)'
    let latest_dispatch = {|extra={}|
        # Selectively list appropriate runs
        run list $workflow --repo=$repo --args=$args --filter={
            branch: $ref
            event: 'workflow_dispatch'
            ...$extra
        }
        | if ($in.error? | is-not-empty) { return $in } else {
            $in.workflow_runs.0? | default {}
        }
    }

    # Preserve the branch's current sha
    let head_sha = branch get $ref --repo=$repo --args=$args
      | if ($in.error? | is-not-empty) { return $in } else { $in.commit.sha }

    let interval = 3sec
    let started_id = (do $latest_dispatch).id? | default 0
    let started_at = date now

    # Run (dispatch) the workflow
    run $workflow --repo=$repo --ref=$ref --inputs=$inputs --args=$args
      | if ($in.error? | is-not-empty) { return $in }

    # Wait for a dispatched run to appear
    while ((date now) - $started_at) < $timeout {
        sleep $interval
        (do $latest_dispatch {head_sha: $head_sha})
          | if ($in.id? | default 0) > $started_id {
                log info $"Dispatched workflow ($in.name) run link ($in.html_url)"
                return {run: $in}
            }
    }

    let err = $'Timed out waiting for the dispatched workflow ($workflow)!'
    log error $err
    return {error: {message: $err}}
}


# Get workflow run by id
#
export def --env "run get" [
    run_id: int          # workflow run id
    --repo: string       # repository, e.g. dennybaa/foobar
] {
    api $'repos/($repo | default-repo)/actions/runs/($run_id)'
}

# Wait for a workflow run
#
# Waits until finish the workflow run is finished (concluded) or until the desired status is met.
# status:
#     completed, action_required, cancelled, failure, neutral, skipped, stale,
#     success, timed_out, in_progress, queued, requested, waiting, pending
#
export def --env "run wait" [
    run_id: int               # workflow run id
    --repo : string           # repository, e.g. dennybaa/foobar
    --interval=5sec           # interval
    --timeout=60sec           # wait timeout
    --status=['completed']    # wait for specific status
] {
    log debug $'=> ($command_base) run wait ($run_id) --repo=($repo)...'
    let started_at = date now
    let conclusions = [success, failure]
    while ((date now) - $started_at) < $timeout {
        sleep $interval
        run get $run_id --repo=$repo
          | if ($in.error? | is-not-empty) { return $in } else { $in }
          | if ($in.status in $status) or ($in.conclusion in $conclusions) {
                return {run: $in}
            }
    }
    let err = $'Timed out waiting for workflow run_id ($run_id) to complete!'
    log error $err; return {error: {message: $err}}
}
