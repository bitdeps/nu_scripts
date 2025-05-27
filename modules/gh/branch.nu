use std/log

const command_base = 'gh branch'


# List github branches
#
# Returns the list of branches.
export def --env list [
    --repo: string
    --args: list<string>=[]
]: nothing -> any {
    log debug $'=> ($command_base) list --repo=($repo)'
    (api ...$args
        $'repos/($repo | default-repo)/branches'
        | api-wrap
    )
}

# Get a github branch
#
# Returns branch get.
export def --env get [
    branch: string
    --repo: string
    --args: list<string>=[]
] {
    log debug $'=> ($command_base) get --repo=($repo)'
    (api ...$args
        $'repos/($repo | default-repo)/branches/($branch)'
    )
}
