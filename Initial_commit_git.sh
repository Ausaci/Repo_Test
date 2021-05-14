#!/bin/bash
#
# Copyright (c) 2019-2021 Samuel <https://github.com/Ausaci>
#
# Description: Delete all commit history in github.
#
# Usage:
# chmod +x Initial_commit_git.sh
# ./Initial_commit_git.sh
#

### Please change the 'GIT_BRANCH' you want to delete commit history! ###
GIT_BRANCH="main"

# 1. Checkout

git checkout --orphan latest_branch

# 2. Add all the files

git add -A

# 3. Commit the changes

git commit -am "Initial commit"

# 4. Delete the branch

git branch -D ${GIT_BRANCH}

# 5. Rename the current branch to GIT_BRANCH

git branch -m ${GIT_BRANCH}

# 6. Finally, force update your repository

git push -f origin ${GIT_BRANCH}

