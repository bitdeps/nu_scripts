use ./branch.nu


scope modules
  | where {|e| $e.name == 'branch'}
  | $in.0.commands
  | each {|cmd|
        help branch $cmd.name
    } | to text | print
