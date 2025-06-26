# Parse envfile (var=value list of lines)
export def read-file [
    --path (-p): string # Path to read file from
] {
    let envfile = $path
    if (not ($envfile | path exists)) {return {}}
    open $envfile
      | lines | parse -r '^ *(?<key>\w+)=(?<value>.*)'
      | reduce -f {} {|i, ac|
            $ac | merge {$i.key: ($i.value | str trim -c "'" | str trim -c '"')}
        }
}

# Write envfile
export def write-file [
    map?: record        # Key/value map to write into file as `key="value"`
    --path (-p): string # Path to write file to
    --force (-f)        # Force file overwrite if exists
] {
    let source = if ($map != null) {$map} else {$in}
    if ($source == null) { error make {msg: "map or input must be provided"} }
    $source
      | transpose key value
      | each {|i| $'($i.key)=($i.value | to json)'}
      | to text | save --force=($force) $path
}
