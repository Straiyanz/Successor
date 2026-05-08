"""Update WoW api and ui git repos"""

import subprocess


def pull_git_repo(dir: str):
    subprocess.run("git pull", cwd=dir)


if __name__ == "__main__":
    pull_git_repo("D:/coding/wow-api/")
    pull_git_repo("D:/coding/wow-ui-source/")
