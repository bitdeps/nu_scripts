use ../../modules/gh
source ../common/env.nu

def main [] {
    print "Setting up output helpers ..."
    gh core setOutput workspace $env.GITHUB_WORKSPACE?
    gh core setOutput nu-include-dirs (nu-include-dirs)
}
