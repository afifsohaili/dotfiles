function makeplan() {
    if [ -z "$1" ]; then
        echo "Usage: makeplan <plan>"
        return 1
    fi
    # if there's no .git, raise an error
    if [ ! -d .git ]; then
        echo "Error: Not a git repository"
        return 1
    fi
    # if there's no plans directory, create it
    if [ ! -d plans ]; then
        mkdir -p plans
    fi
    mkdir -p plans/$1
    mkdir -p plans/$1/screens
    touch plans/$1/plan-$1.md

    # include in .gitignore
    echo "!plans/$1" >> .gitignore
}
