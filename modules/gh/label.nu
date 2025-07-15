use std/log
use std/assert

const command_base = 'gh label'

# List labels for an issue
#
# Lists all labels for an issue.
export def --env "issue-list" [
    --repo: string                # repository, e.g. dennybaa/foobar
    --args: list<string>=[]
    issue_number: number          # issue/pull_request number
]: nothing -> any {
    log debug $'=> ($command_base) issue-list --repo=($repo)'
    (api ...$args
        $'repos/($repo | default-repo)/issues/($issue_number)/labels'
    ) | api-wrap
}

# Add labels to an issue
#
# Adds labels to an issue.
export def --env "issue-add" [
    --repo: string                # repository, e.g. dennybaa/foobar
    --args: list<string>=[]
    --labels: list<string>        # The names of the labels to add to the issue's existing labels.
    issue_number: number          # issue/pull_request number
] {
    log debug $'=> ($command_base) issue-add --repo=($repo)'
    if ($labels | is-empty) { error make {msg: "Provide non empty list of labels, eg: --labels=[bug enhancement]"} }

    {labels: $labels} | to json | (api ...$args
        --method POST
        $'repos/($repo | default-repo)/issues/($issue_number)/labels'
        --input '-'
    )
}

# Set labels for an issue
#
# Removes any previous labels and sets the new labels for an issue.
# Note: You can pass an empty array to remove all labels.
export def --env "issue-set" [
    --repo: string                # repository, e.g. dennybaa/foobar
    --args: list<string>=[]
    --labels: list<string>        # The names of the labels to add to the issue's existing labels.
    issue_number: number          # issue/pull_request number
] {
    log debug $'=> ($command_base) issue-set --repo=($repo)'
    if $labels == null { error make {msg: "Provide list of labels, eg: --labels=[bug enhancement]"} }

    {labels: $labels} | to json | (api ...$args
        --method PUT
        $'repos/($repo | default-repo)/issues/($issue_number)/labels'
        --input '-'
    )
}

# Remove a label or all lavels from an issue
#
# Removes the specified label from the issue, and returns the remaining labels on the issue.
# If all labels are removed successfully returns 204.
export def --env "issue-remove" [
    --repo: string                # repository, e.g. dennybaa/foobar
    --args: list<string>=[]
    --name: string                # Name of the label to remove (required)
    --all                         # Remove all labels
    issue_number: number          # issue/pull_request number
] {
    log debug $'=> ($command_base) issue-remove --repo=($repo)'
    if ($name | is-empty) and (not $all) { error make {msg: "Provide --name or --all, eg: --name=bug"} }

    $'repos/($repo | default-repo)/issues/($issue_number)/labels' |
      if ($all) {
        api ...$args --method DELETE $in
      } else {
        api ...$args --method DELETE $'($in)/($name)'
      }
}

# List labels for a repository
#
# Lists all labels for a repository.
export def --env list [
    --repo: string                  # repository, e.g. dennybaa/foobar
    --args: list<string>=[]
] {
    log debug $'=> ($command_base) list --repo=($repo)'
    api ...$args $'repos/($repo | default-repo)/labels'
      | api-wrap
}

# Get a label
#
# Gets a label using the given name.
export def --env get [
    name: string                    # Name of the label to get (required)
    --repo: string                  # repository, e.g. dennybaa/foobar
    --args: list<string>=[]
] {

    log debug $'=> ($command_base) get --repo=($repo)'
    api ...$args $'repos/($repo | default-repo)/labels/($name)'
}

# Create a label
#
# Creates a label for the specified repository with the given name and color. The name and color parameters are required. The color must be a valid hexadecimal color code.
export def --env create [
    name: string                    # Name of the label to create (required)
    --repo: string                  # repository, e.g. dennybaa/foobar
    --args: list<string>=[]
    --color: string                 # The hexadecimal color code for the label, without the leading #.
    --description(-d): string       # A short description of the label. Must be 100 characters or fewer.
] {
    log debug $'=> ($command_base) create --repo=($repo)'
    {
        name: $name
        color: $color
        description: $description
    }
      | compact record
      | to json
      | (api ...$args
            --method POST
            $'repos/($repo | default-repo)/labels'
            --input '-'
        )
}

# Update a label
#
# Updates a label using the given label name.
export def --env update [
    name: string                    # Name of the label to create (required)
    --new-name: string              # The new name of the label. Emoji can be added to label names, using either native emoji or colon-style markup. For example, typing :strawberry: will render the emoji :strawberry:
    --repo: string                  # repository, e.g. dennybaa/foobar
    --args: list<string>=[]
    --color: string                 # The hexadecimal color code for the label, without the leading #.
    --description(-d): string       # A short description of the label. Must be 100 characters or fewer.
] {
    log debug $'=> ($command_base) update --repo=($repo)'

    {
        new_name: (
            if ($new_name | is-empty) {
                { error make {msg: "Provide --new-name, eg: --new-name='bug :bug:'"} }
            } else { $new_name }
        )
        color: $color
        description: $description
    }
      | compact record
      | to json
      | (api ...$args
            --method POST
            $'repos/($repo | default-repo)/labels/($name)'
            --input '-'
        )
}

# Delete a label
#
# Deletes a label using the given label name.
export def --env delete [
    name: string                    # Name of the label to create (required)
    --repo: string                  # repository, e.g. dennybaa/foobar
    --args: list<string>=[]
] {
    log debug $'=> ($command_base) delete --repo=($repo)'
    
    (api ...$args
        --method DELETE
        $'repos/($repo | default-repo)/labels/($name)'
    )
}
