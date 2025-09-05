#!/usr/bin/awk -f
# by 9vlc

function print_array(array) {
  for (i = 1; i <= length(array); i++) {
    print i"> "array[i]
  }
}

BEGIN {
  if (!ARGV[1]) {
    print "usage: gen-tuple.awk <repo dir>"
    exit(1)
  }
  repo_dir = ARGV[1]
  if (system("[ -r \""repo_dir"\"/.gitmodules ]")) {
    print "error: git repository '"repo_dir"' does not exist"
    exit(1)
  }

  module_count = 1
  while (("cd "repo_dir" && git submodule status" | getline status) > 0) {
    gsub(/^[[:space:]]|-/, "", status)
    gsub(/[[:space:]]\(.*.\)$/, "", status)
    modules_gs_commit[module_count] = status
    modules_gs_path[module_count] = status
    gsub(/[[:space:]].*$/, "", modules_gs_commit[module_count])
    gsub(/^[0-9a-fA-F]+[[:space:]]/, "", modules_gs_path[module_count])
    module_count++
  }; close("git submodule")

  #
  # need to first create a var, then pass it to getline, else
  # it fails to open the file (awk bug, need to report later)
  #
  file = repo_dir"/.gitmodules"
  module_count = 0 # 0 since we start with nothing found yet
  while ((getline line < file) > 0) {
    if (line ~ /^\[submodule ".*."]$/) {
      module_count++
    # let's not rely on the submodule name that comes before
    } else if (line ~ /^[[:space:]]+path/) {
      gsub(/^.*h = /, "", line)
      modules_gm_path[module_count] = line
    } else if (line ~ /^[[:space:]]+url/) {
      gsub(/^.*github.com\//, "", line)
      gsub(/.git$/, "", line)
      modules_gm_url[module_count] = line
    }
  }
  close(file)

  #
  # match and print now
  #
  for (i = 1; i <= length(modules_gs_path); i++) {
    for (j = 1; j <= length(modules_gm_path); j++) {
      if (modules_gs_path[i] ~ modules_gm_path[j]) {
        split(modules_gm_url[j], repo, "/")
	
	repo_owner = repo[1]
	repo_name = repo[2]
	commit = modules_gs_commit[i]
	module_path = modules_gs_path[i]
	
	master_name = repo_name
	# needs to fall under a range of characters else make fails
	gsub(/[^a-zA-Z0-9_]/, "_", master_name)
        printf("%s:%s:%s:%s/%s\n", repo_owner, repo_name, commit, master_name, module_path)
      }
    }
  }
}
