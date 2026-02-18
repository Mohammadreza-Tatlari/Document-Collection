SSH:
git@github.com:Mohammadreza-Tatlari/restorephotos-test.git

HTTP:
https://github.com/Mohammadreza-Tatlari/restorephotos-test.git

…or create a new repository on the command line:
echo "# restorephotos-test" >> README.md
git init
git add README.md
git commit -m "first commit"
git branch -M main
git remote add origin https://github.com/Mohammadreza-Tatlari/restorephotos-test.git
git push -u origin main


…or push an existing repository from the command line:
git remote add origin https://github.com/Mohammadreza-Tatlari/restorephotos-test.git
git branch -M main
git push -u origin main


git init : to initiate the git file into the local repository 

git status: to see the status of our repository

git add . : to track all the files that exist in our folder

git rm --cached <filename> -r (recursive): to untrack the file

.gitignore file: to ignore what we dont want to be represented

working file : when we are working on code and we did not add it to being trackemain p
staging: when we add file and make it be tracked
git restore --staged filename : to make the file to be untracked

commit: when we have taken a snapshop and make it ready to be pushed

git commit -a -m "": to bypass the staging and directly track and commit the modified files

(use git status to check its name)
git rm <filename> " file name ": to remove the file from directory

git restore <filename> "file name": to resotre the deleted file

git mv <oldname> <newname>: to change the name of the file

git log: to see the log
git log --oneline: to see the abbreviation of logs

git commit -m "" --amend: to replace the new commit on the older commit 

git log -p : to see the detail of all modified and chaned files

git help log: give full information about how to use log (you know the other stuff too:P)

git reset <log number>: to reset the commit

git i -rebase: let use make specific changes to the code 
:x to exit the environment 



•BRANCHING•

git branch: to see the branches 

git branch <name of the branch>: to create a new branch

git switch or checkout <name of the branch>: to switch to other branch

git merge -m "comment" <name of the branch>: to merge the branch to its main branch

git branch -d <name of the branch>: to delete the branch

merge confliction:
when a piece of code is modified in two different branches the merge conflic occurs. in order to resolve this issue we shall receive a peice of script on our code that comes like <<<<HEAD and <<<<Updated that duplicated the both formats and display it on screen in order to choose we can delete one of them and keep the other one and then commit it. such confliction happens when we have two commits ready to be pushed

PUSHING AN EXISTING REPOSITORY TO CLOUD:

after git init and all the tracking can commiting (which should be done after connecting to the cloud)

we can use the commands below

git remote add origin <ssh or http of repo>: this will add(track) all the files and specifies it to the remote repo

git branch -M <branch name (main)>: it sets the target branch to <branch name>

git push -u origin main: to push all tracked files to remote repo

git push --all: will push the local branches as well

• Fetch and Pull •

git fetch: to get all the history from remote tracking branches

git merge: to merge with what we have on our local machine

git pull: to commit both fetch and merge in one command



git push --force origin main
Replace "origin" with the name of your remote repository, and "main" with the name of the new main branch.

…or create a new repository on the command line
echo "# wehouse" >> README.md
git init
git add README.md
git commit -m "first commit"
git branch -M main
git remote add origin git@github.com:Mohammadreza-Tatlari/wehouse.git
git push -u origin main

…or push an existing repository from the command line
git remote add origin git@github.com:Mohammadreza-Tatlari/wehouse.git
git branch -M main
git push -u origin main

git add -u -u: that it will stage the modified and deleted files.
git commit -a:  to commit only the modified and deleted files. 

how to uncommit from remote repository
use git reset --hard HEAD

for reverting commits
 git revert --abort

for removing a specific file history from repository

git filter-branch --index-filter 'git rm -rf --cached --ignore-unmatch path_to_file' HEAD

git stash => return everything to first commited changes




## How to Add multiple Remote Repository:
1. be sure that your local directory is git initiated and/or have an existing remote:
```sh
git status
git init
git remote -v

git remote add github https://github.com/YOUR_USER/YOUR_REPO.git
git remote add gitlab https://gitlab.xx.com/devsecops/devops-documents.git
git remote -v #verify it

git push -u github main
git push -u gitlab main
```



## How to Push a sub directory into a different repository `git subtree`

#### Mental model (important)
* `/project` = main repo (authoritative)
* `/project/subdir` = *exported view* of part of that repo
* Subdir repo:

  * has its own commits
  * can be updated independently
  * but stays in sync via subtree commands

This is **one-way or two-way**, your choice.

---

#### Step 0 — Verify repo state

From `/project`:

```bash
cd /project
git status
```

Make sure:

* working tree is clean (or at least committed)
* `subdir/` already exists

If not committed yet:

```bash
git add subdir
git commit -m "Add subdir"
```

Subtree **requires committed content**.

---

#### Step 1 — Add the second repository as a remote

This is the repo that will receive **only `subdir`**.

```bash
git remote add subdir-remote https://github.com/YOUR_USER/SUBDIR_REPO.git
```

Check:

```bash
git remote -v
```

You should now see:

* `origin` (main repo)
* `subdir-remote` (subdir-only repo)

---

#### Step 2 — Push `subdir` as its own repository

This is the key command:

```bash
git subtree push --prefix=subdir subdir-remote main
```

##### What this does

* Takes `/project/subdir`
* Treats it as repo root
* Pushes it to `subdir-remote`
* Preserves commit history **only for that directory**

After this:

* The other repo will look like it was developed standalone
* No extra nesting (`subdir/subdir`) — clean root

---

#### Step 3 — Verify on the remote

On GitHub/GitLab:

* You should see the **contents of `subdir` at repo root**
* Commit messages preserved
* No other project files

If you see `subdir/subdir`, stop — prefix path was wrong.

---

#### Step 4 — Ongoing workflow (this matters)

##### Normal development (in `/project`)

```bash
# work normally
git add subdir
git commit -m "Update subdir logic"
```

##### Push subdir updates

```bash
git subtree push --prefix=subdir subdir-remote main
```

That’s it. No magic. No sync daemons.

---

#### Step 5 — (Optional) Pull changes *back* from subdir repo

If someone edits the subdir repo directly:

```bash
git subtree pull --prefix=subdir subdir-remote main
```

Git will:

* merge changes
* place them back into `/project/subdir`
* keep history consistent

This only works cleanly if **both sides respect subtree workflow**.


## Ignore some files in the main repo, but track them in the subdir repo (via git subtree)
This IS POSSIBLE, IF you structure the ignore rules correctly.
```
/project
  ├── .gitignore          ← main repo rules
  ├── subdir/
  │     ├── .gitignore    ← subdir-specific rules
  │     └── important.file
```



