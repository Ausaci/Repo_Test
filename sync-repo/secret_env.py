#!/usr/bin/python3
import os
import base64

# Set variables
# function controller # true false disabled
is_compare_commit = "false"
is_check_wiki = "false"
is_create_repo = "false"
is_sync_repo = "true"
is_sync_tag = "true"
is_sync_wiki = "false"
is_delete_release = os.environ['IS_DELETE_RELEASES']

# for delete release function
release_feature = os.environ['SYNC_RELEASE_FEAT']
keep_latest = 1

# for sync wiki
dest_wiki_repo = "WIKI"
repo_clone_path = "REPO_CLONE_PATH"
repo_wiki_temp_path = "REPO_WIKI_TEMP_PATH"

# Set input csv file
if is_compare_commit == "true" and not is_sync_repo == "true":
    INPUT_CSV_FILE = "github.CSV"  # compare commits
elif not is_compare_commit == "true" and is_sync_repo == "true":
    INPUT_CSV_FILE = "github.CSV"  # sync repo & delete releases
else:
    print(
        "Please check funtion controller: \"is_compare_commit\" and \"is_sync_repo\" cannot both be \"true\" or \"false\".")
    exit(0)

# Set output csv file
need_update_repo_CSV_FILE = "need_updated_github.CSV"
ya_need_update_repo_CSV_FILE = "github-output.CSV"
need_attention_repo_CSV_FILE = "need_attention_repo.CSV"
the_conflict_repo_CSV_FILE = "conflict_repo.CSV"

# Set Telegram bot_token, chat_id
tg_bot_token = os.environ['SYNC_TG_BOT_TOKEN']
tg_chat_id = os.environ['SYNC_TG_CHAT_ID']
# Set the dest owner and the corresponding access token for authentication
dest_owner = os.environ['SYNC_DEST_OWNER']
dest_email = os.environ['SYNC_DEST_OWNER_EMAIL']
dest_access_token = os.environ['SYNC_DEST_TOKEN']
dest_ssh_private_key_base64 = os.environ['SYNC_DEST_SSH_KEY']  # your_ssh_key_content_base64
dest_ssh_private_key = dest_ssh_private_key_base64  # base64.b64decode(dest_ssh_private_key_base64.encode('utf-8')).decode('utf-8')

"""
# Get variables from the os environment
dest_owner = os.environ['SYNC_DEST_OWNER']
dest_access_token = os.environ['SYNC_DEST_TOKEN']
release_feature = os.environ['SYNC_RELEASE_FEAT']
"""

# Set the headers with the access token
headers = {
    "Authorization": "Bearer " + dest_access_token,
    "Accept": "application/vnd.github.v3+json",
    "X-GitHub-Api-Version": "2022-11-28"
}


# Get global variable names
def get_global_variables(list_name):
    function_name = 'get_global_variables'
    # 获取当前模块的全局变量字典
    global_variables = globals()
    # 提取全局变量的名称
    variable_names = [name for name in global_variables if (not name.startswith('__') and not name.startswith(list_name) and not name.startswith(function_name) and not name.startswith('os') and not name.startswith('base64'))]
    variable_nums = len(variable_names)
    # 输出全局变量名称列表
    print(f"Total \"{variable_nums}\" vars in list: {variable_names}")
    return variable_names


variable_lists = get_global_variables('variable_lists')
__all__ = ['is_compare_commit', 'is_check_wiki', 'is_create_repo', 'is_sync_repo', 'is_sync_tag', 'is_sync_wiki', 'is_delete_release', 'release_feature', 'keep_latest', 'dest_wiki_repo', 'repo_clone_path', 'repo_wiki_temp_path', 'INPUT_CSV_FILE', 'need_update_repo_CSV_FILE', 'ya_need_update_repo_CSV_FILE', 'need_attention_repo_CSV_FILE', 'the_conflict_repo_CSV_FILE', 'tg_bot_token', 'tg_chat_id', 'dest_owner', 'dest_email', 'dest_access_token', 'dest_ssh_private_key_base64', 'dest_ssh_private_key', 'headers']
# print(__all__)
