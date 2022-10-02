#PATH=/home/sujan/Documents/read2lead
#!/bin/sh
PATH=/home/sujan/Desktop/tls_test
cd $PATH;
export PATH=/usr/bin:$PATH;
commit_date=$(date +%Y-%m-%d);
function commit_modified_files {
	echo "get_modified_file On progress ";
	if [[ $(git ls-files --modified | wc -c) -ne 0 ]]; then
	  git ls-files --modified | xargs git add
	  git commit -m "modified: $commit_date"
	fi;
}

function commit_new_files {
	echo "get_untracked_file On progress"
	if [[ $(git ls-files --others | wc -c) -ne 0 ]]; then
	  git ls-files --others | xargs git add
	  git commit -m "added: $commit_date"
  	fi;
}
main {
	cd $1;
	if ! git status | grep -q "nothing to commit"; then
	  commit_modified_files
	  commit_new_files
	fi;
}

$GIT_PATH=/home/sujant/Documents/read2lead;
main $GIT_PATH 
