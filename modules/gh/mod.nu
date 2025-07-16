use std/log

export-env {
    $env.NU_LOG_LEVEL = $env.NU_LOG_LEVEL? | default "error"
    use std/log
}

export module ./core.nu
export module ./branch.nu
export module ./label.nu
export module ./pr.nu
export module ./workflow.nu


# Github default repo
#
# If empty path is provided return the current {owner}/{repo}.
export def --env "default-repo" [] {
    $in | default (
        if ($in | is-empty) and ('.git' | path exists) == false {
            log error 'Use --repo=my-org/repo, outside of a git tree!'; exit 1
        }; '{owner}/{repo}'
    )
}

# Wrap api response into a record with items list
#
def api-wrap [] {
    let $input = $in
    let $tinfo = $input | describe
    if ([table< list<] | any {|type| $tinfo | str starts-with $type}) { return {items: $input} }
    # return response as-is
    return $input
}

# Compact record
def "compact record" [record?: record] {
    $in
      | default $record
      | transpose k v
      | reduce -f {} {|e, acc|
            if ($e.v | is-not-empty) {
                $acc | insert $e.k $e.v
            } else { $acc }
        }
}

# Invoke gh api command
#
# Wraps and passes arbitrary arguments to external gh api command.
export def --env --wrapped api [
    ...args
] {
    let cmd = ^gh api ...$args | complete
    if $cmd.exit_code != 0 {
        let msg = $cmd.stderr | default $cmd.stdout
        log error $'Run failed: gh api ($args | str join " ")'
        log error $msg
        # error
        try {
            let resp = $msg | from json
            if ($resp | is-not-empty) { return {error: $resp} }
        } catch {
            return {error: {message: $msg}}
        }
    }
    # success
    try { $cmd.stdout | from json } catch { $cmd.stdout }
}


# Export github context helper
export def context [] {
    if ($env.GITHUB_ACTION? == null) {
        log debug "gh context: not running in Github Actions!"
        return {}
    }
    {
        payload: (if ($env.GITHUB_EVENT_PATH? != null) { open $env.GITHUB_EVENT_PATH } else { {} })
        eventName: $env.GITHUB_EVENT_NAME
        sha: $env.GITHUB_SHA
        ref: $env.GITHUB_REF
        workflow: $env.GITHUB_WORKFLOW
        action: $env.GITHUB_ACTION
        actor: $env.GITHUB_ACTOR
        repository: $env.GITHUB_REPOSITORY
        job: $env.GITHUB_JOB
        runAttempt: ($env.GITHUB_RUN_ATTEMPT | into int)
        runNumber: ($env.GITHUB_RUN_NUMBER | into int)
        runId: ($env.GITHUB_RUN_ID | into int)
        apiUrl: ($env.GITHUB_API_URL? | default 'https://api.github.com')
        serverUrl: ($env.GITHUB_SERVER_URL? | default 'https://github.com')
        graphqlUrl: ($env.GITHUB_GRAPHQL_URL? | default 'https://api.github.com/graphql')
    }
}
