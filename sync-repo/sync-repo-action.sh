#!/bin/bash

## ENV Begin ##

# Github REST API Version #
GH_API_VERSION="2022-11-28"

# Function controller #
CREATE_REPO="false"
CREATE_RELEASE="false"
SYNC_REPO="true"
SYNC_TAG="true"
SYNC_WIKI="false"
UPDATE_DEFAULT_BRANCH="false"

# TOKEN & SSH Key #
SOURCE_TOKEN="$5" 
DEST_OWNER="$1" # Required
DEST_OWNER_EMAIL="$2" # Required
DEST_TOKEN="$3" # Required
DEST_SSH_PRIVATE_KEY_PATH="" # Required
DEST_SSH_PRIVATE_KEY="$4" # Required
DEST_WIKI_REPO="REPOS_WIKI" # Required # WIKI

# Sync selected branch & tag name #
SOURCE_BRANCH="refs/remotes/source/*"
SOURCE_BRANCH_TAG="refs/tags/*"
DEST_BRANCH="refs/heads/*"
DEST_BRANCH_TAG="refs/tags/*"

# Workdir & files #
WORKDIR="${PWD}"
echo -e "WORKDIR is: ${WORKDIR}"
JSONDIR="${WORKDIR}/${DEST_OWNER}"
WIKIDIR="${WORKDIR}/${DEST_WIKI_REPO}"
TEMP_WIKIDIR="${WORKDIR}/TEMP_${DEST_WIKI_REPO}"
ENV_FILE="${WORKDIR}/sync.env"
LOG_FILE="${WORKDIR}/sync-repo.log"
FUN_LOG="${WORKDIR}/fun_curl.log"
INPUT_CSV_FILE="github.CSV"
TEMP_INPUT_CSV_FILE="${WORKDIR}/TEMP_${INPUT_CSV_FILE}"
REPO_MATRIX_FILE="${WORKDIR}/GH_Matrix_List.txt"

## ENV End ##

# remove files if existed

echo "$(date +"%Y-%m-%d %H:%M:%S Update Begin")"

# Load customized env file

mkdir -p ${WORKDIR}/${DEST_OWNER}
sed '/Source/d' ${WORKDIR}/${INPUT_CSV_FILE} > ${TEMP_INPUT_CSV_FILE} 2>&1
dos2unix ${WORKDIR}/${INPUT_CSV_FILE} ${TEMP_INPUT_CSV_FILE} # ${REPO_MATRIX_FILE} 

# get source repo infomation
fun_get_repo_info(){
# -H "Authorization: Bearer ${SOURCE_TOKEN}" 
curl -fsSL \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer ${DEST_TOKEN}"\
  -H "X-GitHub-Api-Version: ${GH_API_VERSION}" \
  https://api.github.com/repos/${REPO2} \
  > ${JSONDIR}/${DEST_REPO}_info.json 2>&1

SOURCE_DEFAULT_BRANCH="$(cat ${JSONDIR}/${DEST_REPO}_info.json | grep "default_branch" | cut -d '"' -f 4)"
SOURCE_DESCRIPTION="$(cat ${JSONDIR}/${DEST_REPO}_info.json | grep "description" | cut -d '"' -f 4)"
SOURCE_HOMEPAGE="$(cat ${JSONDIR}/${DEST_REPO}_info.json | grep "homepage" | cut -d '"' -f 4)"
echo "Source Default Branch: $SOURCE_DEFAULT_BRANCH"
echo "Source Description: $SOURCE_DESCRIPTION"
echo "Source Homepage: $SOURCE_HOMEPAGE"
}

# create dest repo
fun_create_dest_repo(){
if [[ ${CREATE_REPO} == "true" ]]; then
    # generate_repo_matrix
    echo -e "- { souce_owner: \"${SOURCE_OWNER}\", list: \"${SOURCE_REPO}\" }" >> ${REPO_MATRIX_FILE} 2>&1
    
    if [ ! -n "${SOURCE_HOMEPAGE}" ]; then
        echo -e "{\"name\":\"${DEST_REPO}\",\"description\":\"${SOURCE_DESCRIPTION}\",\"homepage\":\"https://github.com/${REPO2}\",\"private\":true,\"is_template\":false}" > ${JSONDIR}/create_repo_data.json 2>&1
    else
        echo -e "{\"name\":\"${DEST_REPO}\",\"description\":\"${SOURCE_DESCRIPTION} ($SOURCE_HOMEPAGE)\",\"homepage\":\"https://github.com/${REPO2}\",\"private\":true,\"is_template\":false}" > ${JSONDIR}/create_repo_data.json 2>&1
    fi
    # create repo
    curl -fsSL \
      -X POST \
      -H "Accept: application/vnd.github+json" \
      -H "Authorization: Bearer ${DEST_TOKEN}"\
      -H "X-GitHub-Api-Version: ${GH_API_VERSION}" \
      https://api.github.com/user/repos \
      -d '@'${JSONDIR}'/create_repo_data.json' >> ${FUN_LOG} 2>&1
    
    # disable repo action
    fun_change_repo_action_permission
else
    echo "Will NOT Create Repo! Continue to sync ${DEST_REPO} ..."
fi
}

# change dest repo action permissions
fun_change_repo_action_permission(){
curl -fsSL \
  -X PUT \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer ${DEST_TOKEN}"\
  -H "X-GitHub-Api-Version: ${GH_API_VERSION}" \
  https://api.github.com/repos/${REPO1}/actions/permissions \
  -d '{"enabled":false}' >> ${FUN_LOG} 2>&1

# -d '{"enabled":true,"allowed_actions":"selected"}'
# -d '{"enabled":true,"allowed_actions":"all"}'
# -d '{"enabled":false}'
}

fun_sync_dest_repo(){
# build docker image
# docker build -t git-sync:latest -q .

# sync repo with all branch
if [[ ${SYNC_REPO} == "true" ]]; then
    sudo docker run --rm -e "DESTINATION_SSH_PRIVATE_KEY=${DEST_SSH_PRIVATE_KEY}" --name sync-repo-branches git-sync:latest \
        ${REPO2} ${SOURCE_BRANCH} ${REPO1} ${DEST_BRANCH}
fi

# sync tags
if [[ ${SYNC_TAG} == "true" ]]; then
    sudo docker run --rm -e "DESTINATION_SSH_PRIVATE_KEY=${DEST_SSH_PRIVATE_KEY}" --name sync-repo-tags git-sync:latest \
        ${REPO2} ${SOURCE_BRANCH_TAG} ${REPO1} ${DEST_BRANCH_TAG}
fi

}

fun_sync_dest_repo_dev_tag(){
# build docker image
# docker build -t git-sync:dev_tag -q .

if [[ ${SYNC_REPO} == "true" && ${SYNC_TAG} == "true" ]]; then
    sudo docker run --rm -e "DESTINATION_SSH_PRIVATE_KEY=${DEST_SSH_PRIVATE_KEY}" -e "SOURCE_BRANCH_TAG=${SOURCE_BRANCH_TAG}" -e "DESTINATION_BRANCH_TAG=${DEST_BRANCH_TAG}" --name sync-repo-branch-tag git-sync:dev_tag \
        ${REPO2} ${SOURCE_BRANCH} ${REPO1} ${DEST_BRANCH}
elif [[ ${SYNC_REPO} == "true" && ${SYNC_TAG} != "true" ]]; then
    sudo docker run --rm -e "DESTINATION_SSH_PRIVATE_KEY=${DEST_SSH_PRIVATE_KEY}" --name sync-repo-branch-tag git-sync:dev_tag \
        ${REPO2} ${SOURCE_BRANCH} ${REPO1} ${DEST_BRANCH}
else
    echo "Will NOT Sync Branches and Tags of ${DEST_REPO} ..."
fi
}

fun_clone_dest_repo(){
if [[ ${SYNC_WIKI} == "true" ]]; then
    if [[ ${WIKIDIR} != "/" && -d "${WIKIDIR}" ]]; then
        rm -rf ${WIKIDIR}
    fi
    if [[ -n "${DEST_TOKEN}" ]]; then
        # USE destination ssh key if provided
        # git config --local core.sshCommand "/usr/bin/ssh -i ${DEST_SSH_PRIVATE_KEY_PATH}"
        # git clone -c core.sshCommand="${DEST_SSH_PRIVATE_KEY_PATH}" git@github.com:${DEST_OWNER}/${DEST_WIKI_REPO}.git ${WIKIDIR}
        git clone https://${DEST_TOKEN}@github.com/${DEST_OWNER}/${DEST_WIKI_REPO}.git ${WIKIDIR}
    fi
    mkdir -p ${TEMP_WIKIDIR}
fi
}

fun_clone_source_repo(){
if [[ ${SYNC_WIKI} == "true" ]]; then
    WIKI_GIT_URL="https://github.com/${REPO2}.wiki.git"
    git clone ${WIKI_GIT_URL} ${TEMP_WIKIDIR}/${REPO2}.wiki
fi
}

fun_push_dest_repo(){
if [[ ${SYNC_WIKI} == "true" ]]; then
    find ${TEMP_WIKIDIR} -type d -iname ".git" | xargs rm -rf $1
    \cp -rf ${TEMP_WIKIDIR}/* ${WIKIDIR}
    rm -rf ${TEMP_WIKIDIR}
    cd ${WIKIDIR}
    git config --local user.email "${DEST_OWNER_EMAIL}"
    git config --local user.name "${DEST_OWNER}"
    git config --local core.sshCommand "/usr/bin/ssh -i ${DEST_SSH_PRIVATE_KEY_PATH}"
    git add .
    git diff --quiet && git diff --staged --quiet || git commit -am "$(date +"%Y-%m-%d %H:%M:%S Update")"
    git push -f
    cd ${WORKDIR}
else
    echo "Will NOT Sync WIKI repo ..."
fi
}

# Update default branch
fun_update_dest_repo_info(){
if [[ ${UPDATE_DEFAULT_BRANCH} == "true" ]]; then
    echo -e "{\"default_branch\":\"${SOURCE_DEFAULT_BRANCH}\"}" > ${JSONDIR}/update_repo_data.json 2>&1
    curl -fsSL \
      -X PATCH \
      -H "Accept: application/vnd.github+json" \
      -H "Authorization: Bearer ${DEST_TOKEN}" \
      -H "X-GitHub-Api-Version: ${GH_API_VERSION}" \
      https://api.github.com/repos/${REPO1} \
      -d '@'${JSONDIR}'/update_repo_data.json' >> ${FUN_LOG} 2>&1
else
    echo "Will NOT Update Default Branch of ${DEST_REPO} ..."
fi
}

fun_create_release(){
if [[ ${CREATE_RELEASE} == "true" ]]; then
    echo -e "{\"tag_name\":\"$(date +"%Y%m%d")\",\"target_commitish\":\"${SOURCE_DEFAULT_BRANCH}\",\"name\":\"Add Tags\",\"body\":\"Add Tags for ${SOURCE_DEFAULT_BRANCH}. $(date +"%Y-%m-%d %H:%M:%S Updated.")\",\"draft\":false,\"prerelease\":false}" > ${JSONDIR}/create_release_data.json 2>&1
    curl -fssL \
      -X POST \
      -H "Accept: application/vnd.github+json" \
      -H "Authorization: Bearer ${DEST_TOKEN}" \
      -H "X-GitHub-Api-Version: ${GH_API_VERSION}" \
      https://api.github.com/repos/${REPO1}/releases \
      -d '@'${JSONDIR}'/create_release_data.json' >> ${FUN_LOG} 2>&1
else
    echo "Will NOT Create release for ${DEST_REPO} ..."
fi
}

fun_clone_dest_repo

while IFS=',' read -r COL1 COL2 COL3 COL4 COL5
do
    SOURCE_OWNER="${COL1}"
    SOURCE_REPO="${COL2}"
    DEST_REPO="${SOURCE_OWNER}_${SOURCE_REPO}"
    REPO1="${DEST_OWNER}/${DEST_REPO}"
    REPO2="${SOURCE_OWNER}/${SOURCE_REPO}"
    echo -e "\nDestination Repo: $REPO1"
    fun_get_repo_info
    fun_create_dest_repo
    fun_sync_dest_repo_dev_tag
    fun_update_dest_repo_info
    fun_create_release
    fun_clone_source_repo
done < ${TEMP_INPUT_CSV_FILE}

fun_push_dest_repo

if [ -f "${REPO_MATRIX_FILE}" ]; then
    cat ${REPO_MATRIX_FILE}
fi

for file in ${FUN_LOG} ${REPO_MATRIX_FILE}
do
    if [ -f "${file}" ]; then
        rm -rf ${file}
    fi
done

for folder in ${JSONDIR} ${WIKIDIR}
do
    if [ -d "${folder}" ]; then
        rm -rf ${folder}
    fi
done

echo "$(date +"%Y-%m-%d %H:%M:%S Update End")"

