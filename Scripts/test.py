"""Move folder to addons folder for wow for testing"""


from shutil import ignore_patterns


if __name__ == "__main__":
    import os
    import shutil

    retail_addons = r"C:\Program Files (x86)\World of Warcraft\_retail_\Interface\AddOns"
    retail_successor = os.path.join(retail_addons, "Successor")

    if os.path.exists(retail_successor):
        shutil.rmtree(retail_successor)
    shutil.copytree(
        "./", retail_successor,
        ignore=ignore_patterns(".git"),
        ignore_dangling_symlinks=True,
    )
