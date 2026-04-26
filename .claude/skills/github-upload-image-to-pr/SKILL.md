---
name: github-upload-image-to-pr
description: >-
  Embed a local image file into an existing GitHub PR — either in the PR body or as a comment.
  Trigger when a request pairs a local image (screenshot, .png/.jpg, CleanShot capture, before/after)
  with an existing PR (by #number, URL, branch name, or "the open PR"), regardless of verb —
  attach, embed, add, put, post, drop, show, document. Also covers visually documenting test runs,
  bug repros, UI states, or CI failures on an existing PR. The `gh` CLI cannot upload images;
  this skill drives a real browser to GitHub's user-attachments uploader.
allowed-tools: Bash(gh:*), Bash(cp:*), ToolSearch, Read
---

# Upload Image to PR

Browser-driven workflow for embedding local images in a GitHub PR — the GitHub API does not support image uploads, so this drives Playwright MCP to GitHub's user-attachments uploader instead.

## How It Works

Since the GitHub API does not support direct image uploads, this skill uses the **PR comment textarea as a staging area for GitHub's image hosting** — uploading files there to obtain persistent `user-attachments/assets/` URLs, then updating the PR description or posting a comment via the `gh` CLI.

## Step 1: Resolve PR context

If the user didn't specify a PR number or URL, auto-detect it:

```bash
# Get PR number from the current branch
gh pr view --json number,url -q '"\(.number) \(.url)"'
```

If multiple repos or branches are involved, confirm with the user which PR to target.

Also, normalize the image paths to absolute paths. **Prefer `/tmp/` for any screenshots you generate yourself** (e.g., via Playwright `browser_take_screenshot`) — saving them in the repo working directory pollutes `git status` and risks accidentally committing them. For user-supplied paths with special characters (e.g., Unicode narrow spaces from CleanShot X), also copy to `/tmp/` first:

```bash
# Default destination for screenshots you generate
browser_take_screenshot({ filename: "/tmp/foo_desktop.png", ... })

# To handle glob-matched user paths with special chars
cp /path/to/CleanShot*keyword*.png /tmp/screenshot.png
```

## Step 2: Verify Playwright MCP is available

Use `ToolSearch` with a query like `"browser navigate upload"` to confirm `mcp__playwright__*` tools are registered.

Playwright MCP attaches to or spawns a browser with a fresh profile, so **the user will need to sign into github.com the first time** in the spawned window. The session then persists across reuse.

### If Playwright MCP is not installed

Recommend the user install it:

```bash
claude mcp add playwright -- npx -y @playwright/mcp@latest
```

After install, the Claude Code session must be restarted for `mcp__playwright__*` tools to register.

## Step 3: Navigate to PR page and check login state

Navigate and immediately take a snapshot to verify login state:

```js
browser_navigate({ url: "https://github.com/{owner}/{repo}/pull/{number}" })
browser_snapshot()
```

**If an SSO authentication screen appears:** locate the "Continue" button in the snapshot and click it.

## Step 4: Locate the file upload input

Take a snapshot and scroll to the bottom to find the comment area. GitHub renders a file upload input in the comment form. Either find the `ref` directly from the snapshot, or run JS to detect it (GitHub's UI can change — try selectors in order):

```javascript
() => {
  const selectors = [
    'input[type="file"][id*="comment"]',
    'input[type="file"][id="fc-new_comment_field"]',
    '#new_comment_field',
    'input[type="file"]'
  ];
  for (const sel of selectors) {
    const el = document.querySelector(sel);
    if (el) return { found: true, id: el.id, selector: sel };
  }
  return { found: false };
}
```

## Step 5: Upload images one by one

The `<input type="file">` from step 4 is **CSS-hidden** — calling `browser_file_upload` against its ref directly fails with "can only be used when there is related modal state present." First click the visible **"Paste, drop, or click to add files"** button (or "Attach files" toolbar icon) on the comment form to open the native file chooser, then `browser_file_upload` will satisfy that chooser.

Upload each image with `browser_file_upload` (takes the element ref and a file paths array). Wait **2–3 seconds between uploads** so GitHub can process each file, then **3–5 seconds after the last upload** before reading URLs in step 6 — GitHub injects the image markup asynchronously after each file finishes processing.

For multiple images, upload them all to the same comment textarea before extracting URLs — this is more efficient than navigating between uploads.

**Important:** Always use absolute file paths.

## Step 6: Retrieve uploaded image URLs

Read the textarea value via `browser_evaluate` — GitHub injects either markdown or HTML referencing the upload after each file finishes processing.

The **standard textarea selector** (referenced again in step 7) prefers the known ID and falls back to a substring match in case GitHub renames it:

```javascript
() => {
  const ta = document.getElementById('new_comment_field')
          || document.querySelector('textarea[id*="comment"]');
  return ta ? ta.value : 'textarea not found';
}
```

GitHub may inject **either form** depending on image dimensions / file type:
```
![image](https://github.com/user-attachments/assets/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)
<img width="..." height="..." alt="..." src="https://github.com/user-attachments/assets/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" />
```

Both render the image in the PR — preserve whichever form GitHub used. If you need to extract just the URL (e.g., to rewrap), match the asset path with a regex that ignores wrapper syntax: `https://github\.com/user-attachments/assets/[0-9a-f-]+`.

## Step 7: Clear the textarea (do not submit the comment)

Submitting via the UI's "Comment" button would post a public comment as a side effect of the upload. The only thing that should determine where the image lands (PR body vs. a new comment) is step 8 — so the textarea here is purely an upload-staging surface, never a submission surface. Clear it, then let `gh pr edit` / `gh pr comment` decide the destination.

Use the **standard textarea selector** from step 6, then assign `ta.value = ""`:

```javascript
() => {
  const ta = document.getElementById('new_comment_field')
           || document.querySelector('textarea[id*="comment"]');
  if (ta) { ta.value = ""; return "cleared"; }
  return "textarea not found";
}
```

## Step 8: Embed images in the PR

In both options below, substitute whichever form (markdown `![](...)` or HTML `<img ...>`) GitHub returned in step 6 — preserve it verbatim instead of rewrapping. Strip any `width="..." height="..."` attributes if you're putting images in a table (step 8a) so they can flex to the column width.

### Step 8a: Choose a layout

- **Single image** — use the markup as-is.
- **Multiple unrelated images** — stack them vertically with bold captions or `### Subheading`s above each.
- **Paired desktop + mobile (or before/after) screenshots — use a side-by-side table** so reviewers can compare without scrolling. This is the default when you have exactly two related images:

  ```markdown
  ## Screenshots

  | Desktop | Mobile |
  | --- | --- |
  | <img alt="..." src="https://github.com/user-attachments/assets/AAA" /> | <img alt="..." src="https://github.com/user-attachments/assets/BBB" /> |
  ```

### Step 8b: Write the body

The previous `printf '%s\n\n## Screenshots\n\n%s' "$EXISTING_BODY" "$IMAGES"` round-trip is **fragile** — embedded `%`, backticks, or shell-special chars in the existing body can mangle the result (one observed failure silently dropped `## Summary` and `## Test plan` headings). Prefer `--body-file` instead.

**Option A — Update PR description** (append a Screenshots section to the existing body):

```bash
# Capture existing body, append screenshots block, write via --body-file
gh pr view {PR_NUMBER} --json body -q .body > /tmp/pr_body.md
cat >> /tmp/pr_body.md <<'EOF'

## Screenshots

| Desktop | Mobile |
| --- | --- |
| <img alt="desktop" src="https://github.com/user-attachments/assets/AAA" /> | <img alt="mobile" src="https://github.com/user-attachments/assets/BBB" /> |
EOF
gh pr edit {PR_NUMBER} --body-file /tmp/pr_body.md
rm /tmp/pr_body.md
```

If the existing body already contains a `## Screenshots` heading (e.g., on re-runs), appending creates a duplicate section. Check with `grep -q '^## Screenshots' /tmp/pr_body.md` and either edit the file in place to replace the existing section, or use Option B.

**Option B — Post as a new comment**:
```bash
gh pr comment {PR_NUMBER} --body-file /tmp/comment.md
```

Use Option A by default unless the user explicitly asks for a comment, or the PR description is already long and a comment would be cleaner.

## Step 9: Verify the result

Reload the page in the Playwright browser and take a screenshot to confirm the images render correctly. **Do not** verify with `curl` — `user-attachments/assets/` URLs return HTTP 302 to a session-signed S3 URL that 403s for unauthenticated clients. The 302 alone confirms the asset exists; the browser-rendered check is the only authoritative "did it display" signal.

## Tips

- **Image sizing**: Control display size via HTML `<img>` tags: `<img width="800" alt="description" src="..." />`. Drop the `width`/`height` attributes when placing images in a table — let them flex to the column width.
- **Paired screenshots side-by-side**: For desktop+mobile or before/after pairs, always use the 2-column markdown table from step 8a — vertical stacking forces reviewers to scroll back and forth to compare.
- **Multiple images**: Upload all images in one session to the same textarea; extract all URLs before clearing.
- **Local screenshot files**: Save Playwright screenshots to `/tmp/` (not the repo working dir). Also gitignore `/.playwright-mcp/` in any repo where the browser tool runs — it dumps console/snapshot files there.

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Not logged in | SSO screen may appear — take snapshot, find "Continue" button, click it |
| File path with special characters (e.g., Unicode narrow spaces from CleanShot) | Copy file to `/tmp/` with a simple name: `cp /path/CleanShot*keyword*.png /tmp/screenshot.png` |
| File upload fails | Ensure the file path is absolute |
| Textarea doesn't contain URLs yet | Wait 3–5 seconds after upload before running JS eval; retry once if needed |
| Textarea selector not found | GitHub UI changes occasionally — use the multi-selector JS in Step 4 to find the current element |
| Playwright MCP not registered | `claude mcp add playwright -- npx -y @playwright/mcp@latest`, then restart the Claude Code session |
| PR not found / 404 | Private repos return 404 for unauthenticated users — check login state |

## Notes

- GitHub `user-attachments/assets/` URLs are **persistent** — images remain accessible even without submitting the comment
- Editing the description directly in the browser UI is fragile due to GitHub UI structure changes — updating via `gh pr edit` is strongly preferred
- Multiple images can be uploaded in a single session before extracting URLs
- Playwright MCP attaches to a browser instance and preserves cookies/login state across calls
