use std/log

export-env {
    use std/log
}

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

# Invoke gh api command
#
# Wraps and passes arbitrary arguments to external gh api command.
export def --env --wrapped api [
    ...args
] {
    let cmd = ^gh api ...$args | complete
    if $cmd.exit_code != 0 {
        log error $'Run failed: gh api ($args | str join " ")'
        $cmd.stdout | from json | if ($in | is-not-empty) {
            return {error: $in}
        } else {
            return {error: {message: $cmd.stderr}}
        }
    }
    # response
    try { $cmd.stdout | from json } catch { $cmd.stdout }
}
