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
    local plan_name="$1"
    local existing_count=0
    if [ -d plans ]; then
        existing_count=$(find plans -maxdepth 1 -mindepth 1 -type d | wc -l | tr -d ' ')
    fi
    local next_num=$((existing_count + 1))
    local prefix=$(printf "%03d" "$next_num")
    local plan_id="${prefix}-${plan_name}"

    # if there's no plans directory, create it
    if [ ! -d plans ]; then
        mkdir -p plans
    fi
    mkdir -p plans/${plan_id}
    mkdir -p plans/${plan_id}/screens
    touch plans/${plan_id}/plan-${plan_id}.md

    # include in .gitignore
    echo "!plans/${plan_id}" >> .gitignore
}
