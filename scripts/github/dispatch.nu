use std/log
use gh
source ../common/git.nu
source ../common/env.nu

let placeholder_regex = '{\s*(?<key>[^\s]+)\s*}'


def api-error [error: any, --repo: string, --fail] {
    gh core error $"($error.message) \(repo: ($repo), status: ($error.status?))"
    if ($fail) { exit 1 }
}

def dig [record: record, path: string] {
    $path | split row '.' | reduce -f $record {|field, acc| $acc | get $field}
}

# Parses inputs record if it contains parameters (values from data)
#   eg: {prNumber: 'aa-{pull_request.number}-xx'} will replace to actual value
#
def get-inputs [
    inputs: record  # inputs record with possible parametrized values
    data: record    # data to get value from, eg: {ref: 'asddasda', pull_request: {...}}
] {
    # Builds up parameters (path to value) map
    let params = $inputs
      | items {|_, value| $value | parse -r $placeholder_regex | get key}
      | flatten | reduce -f {} {|path, acc| $acc | merge {$path: (dig $data $path)} }

    $inputs | columns | reduce -f {} {|col, result|
        # If value contains parameters regex replace each paramter one by one
        let value = $inputs | get $col
        let keys = ($value | parse -r $placeholder_regex) | get key
        let replaced = $keys | reduce -f $value {|key, acc|
            $acc | str replace -r $placeholder_regex ($params | get $key | into string)
        }
        $result | insert $col $replaced
    }
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
#       title_regex: '^ci\({featue} {client-id}\):'
#
def dispatch [
    rule: record    # workflow dispatch rule
] {
    log debug $"=> dispatch repository: ($rule.repository), workflow: ($rule.workflow)"
    let fallback = ($rule.match?.fallback_ref? != null)

    # items is a list of {ref: xxxx, pull_request: {...}} (actually the data depends on type)
    let items = (match-refs $rule).items
      | if ($in | is-not-empty) {
            $in
        } else if ($fallback) {
            log warning $"Falling back to ref: ($rule.match.fallback_ref), repo: ($rule.repository)"
            [{ref: $rule.match.fallback_ref}]
        } else { return }

    if ($items | length) > 1 {
        log warning $"Dispatch multiple refs ($items | get ref)"
    }

    for data in $items {
        let inputs = get-inputs $rule.inputs $data
        let dispatched = (gh workflow run get-dispatched $rule.workflow
            --repo=$rule.repository --inputs=$inputs --ref=$data.ref
        )
        if ($dispatched.error? != null) { api-error $dispatched.error --repo=$rule.repository --fail }

        # We can check if dispatch happend on the correct sha
        $data.sha?
          | if ($in != null) {
                if (not $fallback) and ($in != $dispatched.run.head_sha) {
                gh core error $"Dispatched workflow ($rule.workflow) commit sha missmatch (expected: $in)!"
                }
            }
    }
}


# Invoke branch matcher depending on match.type
#
def match-refs [rule: record] {
    match ($rule.match?.type?) {
        pull_request => { match-pull-requests $rule }
        _ => { gh core error $"Unknown match.type: '($rule.match?.type?)'"; exit 1; }
    }
}

# Match refs of pull requests
#
def match-pull-requests [rule: record] {
    log debug $"=> match-pull-requests"
    const empty = {items: []}
    let match = $rule.match.pull_request
    let pulls = gh pr list --repo=$rule.repository
    let inputs = $rule.inputs | default {}
    if ($pulls.error? != null) { api-error $pulls.error --repo=$rule.repository --fail }

    ## Match Pull Requests using title_regex
    if ($match.title_regex? != null) {
        # Detect parameters (a {key}) inside regex (e.g. { foo }, {bar})
        let input_keys = $match.title_regex | parse -r $placeholder_regex | get key
        for i in $input_keys {
            if not ($i in $inputs) {
                log error $"Value for '($i)' not found in inputs"
                log error $'=> ($inputs | items {|k| $k})'; exit 1;
            }
        }

        # Substitute found paramters with valus from $inputs to build up the actual regex
        let regex = $input_keys
          | reduce --fold $match.title_regex {|it, acc|
                $acc | str replace -r $placeholder_regex ($inputs | get $it)
            }

        # Find PRs list matching the regex
        if ($regex != null) {
            $pulls.items | where title =~ $regex
              | if ($in | is-not-empty) {
                    return {
                        # return items list records
                        items: ($in | each {|e|
                            {
                                sha: $e.head.sha,
                                ref: $e.head.ref,
                                pull_request: $e
                            }
                        })
                    }
                }
            log warning $"No pull requests matched title regex /($regex)/, repo: ($rule.repository)"
        }
    }

    return $empty
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
