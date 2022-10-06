###########remainnings################
#cron tab implementation
#generalization
#git push
# logs to file
# seldct branch other than master
#!/bin/sh
PATH=/home/sujan/Desktop/tls_test
cd $PATH;
export PATH=/usr/bin:$PATH;
commit_date=$(date +%Y-%m-%d);
function commit_modified_files {
	if [[ $(git ls-files --modified --exclude-from=.gitignore | wc -c) -ne 0 ]]; then
	  echo "get_modified_file On progress ";
	  git ls-files --modified --exclude-from=.gitignore | xargs git add
	  git commit -m "modified: $commit_date"
	fi;
}

function commit_new_files {
	if [[ $(git ls-files --others --exclude-from=.gitignore | wc -c) -ne 0 ]]; then
	  echo "get_untracked_file On progress"
	  git ls-files --others --exclude-from=.gitignore | xargs git add
	  git commit -m "added: $commit_date"
  	fi;
}

function git_push {
	REPO=git-bck
	BRANCH=master
	git push $REPO $BRANCH
}


function main {
	cd $1;
	echo $(pwd)
	if ! git status | grep -q "nothing to commit"; then
	  commit_modified_files
	  commit_new_files
	else
	  echo "Nothing to commit"
	fi;
}

GIT_PATH=/home/sujan/Documents/read2lead;
#GIT_PATH=/home/sujan/Desktop/tls_test/;
main $GIT_PATH 
