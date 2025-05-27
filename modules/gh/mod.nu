use std/log

export-env {
    $env.NU_LOG_LEVEL = $env.NU_LOG_LEVEL? | default "error"
    use std/log
}

export module ./core.nu
export module ./branch.nu
export module ./pr.nu
export module ./workflow.nu


# Github default repo
#
# If empty path is provided return the current {owner}/{repo}.
export def --env "default-repo" [] {
    $in | default (
        $in | if ($in | is-empty) {
            log warning 'Missing --repo=..., invocation outside git tree will fail!'
        };
        '{owner}/{repo}'
    )
}

# Wrap api response of kind list into items map
#
def api-wrap [] {
    let $input = $in
    try {
        # we are kindof list/table
        $input.0?; return {items: $input}
    } catch {
        return $input
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
        log error $'Run failed: gh api ($args | str join " ")'
        # error
        try {
            let resp = $cmd.stdout | from json
            if ($resp | is-not-empty) { return {error: $resp}}
        } catch {
            return {error: {message: ($cmd.stderr | default $cmd.stdout)}}
        }
    }
    # success
    try { $cmd.stdout | from json } catch { $cmd.stdout }
}
