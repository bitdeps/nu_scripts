use std/log
use gh
source common/git.nu
source common/env.nu

let placeholder_regex = '{{\s*(?<key>[^\s]+)\s*}}'


def api-error [error: any, --repo: string, --fail] {
    gh core error $"($error.message) \(repo: ($repo), status: ($error.status?))"
    if ($fail) { exit 1 }
}


# Dispatch workflow matching a rule
#
# rule example:
#   workflow: test-pr.yaml
#   inputs:
#     client-id: hello
#     featue: pr
#   match:
#     type: pull_request
#     pull_request:
#       title_regex: '^ci\({{featue}} {{client-id}}\):'
#
def dispatch [
    rule: record    # workflow dispatch rule
] {
    log debug $"=> dispatch repository: ($rule.repository), workflow: ($rule.workflow)"
    let fallback = ($rule.match?.fallback_ref? != null)
    let branches = (match-branches $rule).branches
      | if ($in | is-not-empty) {
            $in
        } else if ($fallback) {
            log warning $"Falling back to ref: ($rule.match.fallback_ref), repo: ($rule.repository)"
            [{ref: $rule.match.fallback_ref}]
        } else { return }

    if ($branches | length) > 1 {
        log warning $"Dispatch multiple branches ($branches | get ref)"
    }

    for branch in $branches {
        let dispatched = (gh workflow run get-dispatched $rule.workflow
            --repo=$rule.repository --inputs=$rule.inputs --ref=$branch.ref
        )
        if ($dispatched.error? != null) { api-error $dispatched.error --repo=$rule.repository --fail }

        # We can check if dispatch happend on the correct sha
        $branch.sha?
          | if ($in != null) { $in }
          | if (not $fallback) and ($in != $dispatched.run.head_sha) {
            gh core warning $"Dispatched workflow ($rule.workflow) commit sha missmatch!"
          }
    }
}


# Invoke branch matcher depending on match.type
#
def match-branches [rule: record] {
    match ($rule.match?.type?) {
        pull_request => { match-pull-requests $rule }
        _ => { gh core error $"Unknown match.type: '($rule.match?.type?)'"; exit 1; }
    }
}

# Match refs of pull requests
#
def match-pull-requests [rule: record] {
    log debug $"=> match-pull-requests"
    let match = $rule.match.pull_request
    let pulls = gh pr list --repo=$rule.repository
    let inputs = $rule.inputs | default {}
    if ($pulls.error? != null) { api-error $pulls.error --repo=$rule.repository --fail }

    # Match pull requests using title_regex
    $match.title_regex?
    | if ($in != null) {
        # First pick the {{key}} strings inside regex (e.g. {{ foo }}, {{bar}})
        let pattern = $in
        let input_keys = $in | parse -r $placeholder_regex | get key
        log debug $'input_keys=($input_keys)'

        # Replace all the matched keys with the value from $inputs to for the actuall regex
        $input_keys | reduce --fold $pattern {|it, acc|
            $acc | str replace -r $placeholder_regex ($inputs | get $it)
        }
    }
    | do {
        let regex = $in; let found = $pulls.items | where title =~ $regex
        if ($found | is-empty) {
            log warning $"No pull requests matched title regex /($regex)/, repo: ($rule.repository)"
        }
        $found
    }
    | if ($in | is-not-empty) { return {branches: $in.head} }

    return {branches: []}
}

# Dispatch workflows from .dispatch.yaml
def main [
    --config (-c): string = '.github/.dispatch.yaml' # path to the dispatch config
    --inputs (-i): string = '{}'                     # inputs record or json
] {
    let config = open ($config | path expand)
    let inputs = $inputs | from nuon

    for rule in $config.dispatch {
        let rule = $config.default?.dispatch? | default {}
          | merge deep $rule             # merge rule from config
          | merge deep {inputs: $inputs} # merge inputs (overrides values from config file)

        dispatch $rule
    }
}
