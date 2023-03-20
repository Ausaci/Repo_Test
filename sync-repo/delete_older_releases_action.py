#!/usr/bin/python3

import requests
import csv
import os
from datetime import datetime

# Create the API endpoint to get the releases for the tag
release_api_url = "https://api.github.com/repos/{}/{}/releases"
release_id_api_url = "https://api.github.com/repos/{}/{}/releases/{}"

# input csv file
TEMP_INPUT_CSV_FILE = "github.CSV"

# Set the username, repository name, and authentication token

# abc = os.environ
# print(abc)

dest_owner = os.environ['SYNC_DEST_OWNER']
access_token = os.environ['SYNC_DEST_TOKEN']
release_feature = os.environ['SYNC_RELEASE_FEAT']
keep_latest = 1

# Set the headers to include the authentication token
headers = {
    "Authorization": "Bearer " + access_token,
    "Accept": "application/vnd.github.v3+json",
    "X-GitHub-Api-Version": "2022-11-28"
}

# Print time
print(datetime.now().strftime("%Y-%m-%d %H:%M:%S Update Begin..."))

def delete_old_releases(owner, repo, keep_latest, release_feature):
    # Set the prefix of the tag to find releases for
    print(f"\nRepo: {owner}/{repo}  Tag prefix: {release_feature}  Keep latest: {keep_latest}")
    # Get the releases for the repository
    response = requests.get(release_api_url.format(owner, repo), headers=headers)

    # Check if there was an error getting the releases
    if response.status_code != 200:
        print(f"Error getting releases: {response.status_code} {response.reason}")
        exit()

    # Parse the JSON response
    releases = response.json()

    # Loop through the releases and find the ones that match the release feature
    matching_releases = []
    for release in releases:
        # if release["tag_name"] == release_feature:
        # if release["tag_name"].startswith(release_feature):
        if release["name"] == release_feature:
            matching_releases.append(release)

    # Sort the matching releases by the creation date (newest first)
    matching_releases = sorted(matching_releases, key=lambda r: r["created_at"], reverse=True)
    releases_to_keep = matching_releases[:keep_latest]
    releases_to_delete = matching_releases[keep_latest:]

    if releases_to_delete:
        # Delete all but the newest keep_latest releases
        print(f"There are {len(releases_to_delete)} releases to delete...")
        for release in releases_to_delete:
            print(f"Deleting release {release['name']}...")
            delete_response = requests.delete(release_id_api_url.format(owner, repo, release['id']), headers=headers)
            if delete_response.status_code != 204:
                print(f"Error deleting release {release['name']}: {delete_response.status_code} {delete_response.reason}")
        print("Done!")
    else:
        print("There is no release to delete.")

# Read CSV and process 
with open(TEMP_INPUT_CSV_FILE, newline='') as csvfile:
    reader = csv.reader(csvfile, delimiter=',', quotechar='"')
    for row in reader:
        try:
            source_owner = row[0]
            source_repo = row[1]
            dest_repo = f"{source_owner}_{source_repo}"
            repo1 = f"{dest_owner}/{dest_repo}"
            repo2 = f"{source_owner}/{source_repo}"
            delete_old_releases(dest_owner, dest_repo, keep_latest, release_feature)
        except ValueError:
            print("There is a value error. May be there is no this value.")
            continue
        except (KeyError, TypeError):
            print("There is a key error or type error. May be there is no this key.")
            continue
        except UnboundLocalError:
            print("Local variable referenced before assignment.")
            continue
        except OSError:
            print("CAUGHT ECONNECTION ERROR. May be caused by network connection, please try it again!")
            continue

# Print time
print(datetime.now().strftime("%Y-%m-%d %H:%M:%S Update End."))