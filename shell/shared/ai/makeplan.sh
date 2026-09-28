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
    local plans_dir="${PLANS_DIR:-plans}"
    local existing_count=0
    if [ -d "$plans_dir" ]; then
        existing_count=$(find -L "$plans_dir" -maxdepth 1 -mindepth 1 -type d | wc -l | tr -d ' ')
    fi
    local next_num=$((existing_count + 2))
    local prefix=$(printf "%03d" "$next_num")
    local plan_id="${prefix}-${plan_name}"

    # if there's no plans directory, create it
    if [ ! -d "$plans_dir" ]; then
        mkdir -p "$plans_dir"
    fi
    mkdir -p "$plans_dir/${plan_id}"
    mkdir -p "$plans_dir/${plan_id}/screens"
    touch "$plans_dir/${plan_id}/plan-${plan_id}.md"

    # include in .gitignore
    echo "!${plans_dir}/${plan_id}" >> .gitignore
}
