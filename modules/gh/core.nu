use std/log

const command_base = 'gh core'

def is_ci [] {
    $env.CI? == 'true'
}

# Github action core debug command
#
export def --env "debug" [
    message: string     # A message
] {
    if not is_ci { return }
    print $"::debug::($message)"
}

# Github action core notice command
#
export def --env "notice" [
    message: string     # A message
    --params: record    # Record with parameters (file, line, endLine and title)
] {
    if not is_ci { return }
    mut sparams = ""
    if ($params | is-not-empty) {
        $params | transpose key value | each {|e| $"($e.key)=($e.value)"} | str join ','
        | $sparams = $in
    }
    print $"::notice ($sparams)::($message)"
}
