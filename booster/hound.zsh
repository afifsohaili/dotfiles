function hound_check() {
  files=("$@")
  for file in "${files[@]}"
  do
    if [[ "$file" == *rb ]]; then
      rubocop -c .ruby-style.yml $file
    elif [[ "$file" == *css ]]; then
      scss-lint -c .scss-style.yml $file
    fi
  done
}


