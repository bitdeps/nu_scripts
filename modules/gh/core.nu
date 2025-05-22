use std/log

const command_base = 'gh core'
let running_in_ci = ($env.CI? == 'true')

# Github action core debug command
#
export def --env "core debug" [
    message: string     # A message
] {
    if not $running_in_ci { return }
    print $"::debug::($message)"
}

# Github action core notice command
#
export def --env "core notice" [
    message: string     # A message
    --params: record    # Record with parameters (file, line, endLine and title)
] {
    if not $running_in_ci { return }
    mut sparams = ""
    if ($params | is-not-empty) {
        $params | transpose key value | each {|e| $"($e.key)=($e.value)"} | str join ','
        | $sparams = $in
    }
    print $"::notice ($sparams)::($message)"
}
