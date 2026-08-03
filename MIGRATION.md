Git LFS migration plan — replace LFS pointers with real files in repository history

Overview

This document describes a safe, reversible plan to remove Git LFS usage from the NTNH-Server repository by exporting LFS objects into regular Git history. The goal is to make the repository self-contained (no LFS pointers) so clones do not require Git LFS or LFS bandwidth.

High-level approach

1. Backup the repository (mirror clone).  
2. On a local machine with enough disk space, run `git lfs migrate export` to rewrite history and store binary files in regular Git objects.  
3. Verify the rewritten mirror locally.  
4. Push the rewritten history to GitHub (force push) and coordinate with contributors.  
5. Optionally remove any remaining LFS metadata and reduce repo size with garbage collection.

Prerequisites & warnings

- This procedure rewrites git history (force-push). All existing clones and forks will need to rebase/sync or reclone. Coordinate with maintainers and contributors before pushing.  
- Ensure you have enough disk space for multiple copies of the repository and the exported binaries (at least the sum of repo + LFS objects).  
- Create backups of the repo and of large binaries before proceeding.  
- Test thoroughly on a mirror clone before pushing to origin.

Step-by-step (recommended)

1) Prepare backups (do this BEFORE any history rewrite)

- Create a mirror clone of the repository and push it to a safe backup location (local or another remote):

  git clone --mirror https://github.com/NTNewHorizons/NTNH-Server.git NTNH-Server-mirror.git
  cd NTNH-Server-mirror.git
  # Optionally pack and archive the bare mirror
  tar -czf ../NTNH-Server-mirror-$(date +%Y%m%d).tar.gz .

- Download large assets separately if you prefer an object-level backup:
  - Use the existing start.sh/download script on a fresh clone to fetch binaries into a separate archive directory.

2) Create a working clone for migration (non-bare)

  git clone https://github.com/NTNewHorizons/NTNH-Server.git NTNH-Server-migration
  cd NTNH-Server-migration
  # Fetch all refs (recommended for a full migration)
  git fetch --all --tags

3) Dry-run the migration (test only)

- Run the migrate command with a dry-run to see what would change. `git lfs migrate` supports a `--no-rewrite` / dry-run-like check by running in a mirror and not pushing, but it's safest to operate on your migration clone and inspect.

  # Example patterns to include: jars under mods/, server.jar, minecraft server jar, libraries.zip
  git lfs migrate export --include="mods/HBM-*.jar,server.jar,minecraft_server.*.jar,libraries.zip" --everything --verbose

  Notes:
  - `--everything` rewrites all references (branches, tags).  
  - Adjust `--include` to match the file patterns used in this repo. You can add additional globs if other paths were stored in LFS.

4) Inspect and verify locally

- Check that large files are now stored as regular git objects and that pointer files are gone from history:

  # Show recent commits and that server.jar is in tree
  git log --decorate --oneline -n 5
  git ls-tree -r HEAD | grep server.jar

  # Verify file sizes (should be big, not small 100-byte LFS pointers)
  ls -lh server.jar
  head -n 3 server.jar   # should not contain the "version https://git-lfs.github.com/spec/v1" pointer

  # Check repository size and object db growth
  git count-objects -vH

5) Update .gitattributes

- Remove or trim any `filter=lfs` lines from `.gitattributes` so future commits do not use LFS. (This repo already has a `.gitattributes` update.)

6) Push rewritten history to origin (COORDINATE with maintainers)

- When you're ready to publish the rewritten history, force-push all branches and tags. This is disruptive: communicate and get consensus.

  # From the migration clone (after verification)
  git remote add upstream https://github.com/NTNewHorizons/NTNH-Server.git
  # Force push branches and tags
  git push upstream --force --all
  git push upstream --force --tags

7) Housekeeping on the server and local machines

- On the server (or CI) and on developers' machines, clear old LFS cache and run garbage collection:

  # For local clones after the rewrite, recommend recloning. For CI or server images that need to preserve data, follow these steps:
  git lfs uninstall   # optional, if you want to remove lfs hooks
  git reflog expire --expire=now --all
  git gc --prune=now --aggressive

- If you keep the repo on disk, consider running `git gc` on the GitHub side is not possible — GitHub will run their own maintenance.

8) Optional: use Releases or external storage for binaries instead

- While embedding binaries directly in git is ok for a one-time migration, consider moving large, frequently changing binaries to GitHub Releases or an external storage (S3, CDN) to avoid repository bloat.
- Update start/install scripts to download from release assets (more robust) instead of raw repo URLs.

Rollback strategy

- If anything goes wrong after pushing, you can restore from the mirror backup created in step 1 by pushing that mirror back to origin (coordinate with GitHub repository administrators):

  cd NTNH-Server-mirror.git
  git push --force --mirror https://github.com/NTNewHorizons/NTNH-Server.git

Testing checklist

- Clone the repository fresh (no git lfs installed) and run the `./start.sh` script — server should run and not need git lfs.  
- Verify `server.jar`, `minecraft_server.*.jar`, and large files in `mods/` are full binaries (not LFS pointer text).  
- Confirm history no longer contains LFS pointer entries (check past commits that previously contained pointers).  

Notes & caveats

- Rewriting history increases the apparent repository size because binary files become regular git objects; this can bloat the repository if not combined with an archival strategy.  
- Consider using a release-based approach for large binaries to keep the main repository small while still keeping artifacts accessible.  

Need help?

If you'd like, I can:
- Produce the exact `git lfs migrate export` command(s) tailored to the full list of LFS-tracked file globs used in this repo.  
- Run a simulated migration here (prepare the commands and checks) so you can run them locally.  
- Draft a contributor notice and timeline for the forced-push migration.

