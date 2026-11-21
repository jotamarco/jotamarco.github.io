# How to update the website

All the content of the site lives in plain-text YAML files in the `_data/` folder.
The pages read those files, so to add a paper, a student or a talk you only edit one list.
You never need to touch HTML.

## Where each thing lives

| To change… | Edit this file | Page |
|---|---|---|
| Bio text on the home page | `_pages/about.md` | Home |
| Sidebar (photo, links), positions, education, research topics | `_data/profile.yml` | All pages / Home |
| Latest news | `_data/news.yml` | Home |
| Awards | `_data/awards.yml` | Home |
| Research teams | `_data/teams.yml` | Home, Projects |
| Papers and technical reports | `_data/publications.yml` (+ PDF in `Papers/`) | Publications |
| Courses, academic roles, training | `_data/teaching.yml` | Teaching |
| PhD / MSc students, grants, researchers | `_data/supervision.yml` | Supervision |
| Research projects | `_data/projects.yml` | Projects |
| Software and prototypes | `_data/software.yml` | Software |
| Management roles and events | `_data/service.yml` | Service |
| Invited talks | `_data/talks.yml` | Service |
| Juries | `_data/juries.yml` | Service |
| Journals reviewed and program committees | `_data/reviewing.yml` | Service |
| Menu at the top | `_data/navigation.yml` | All pages |

The numbers on the home page and at the top of each page (publications, students, talks…)
are counted automatically from these lists.

Each file starts with a comment block (lines beginning with `#`) that shows a template entry
with every field you can use.

## Common tasks

**Add a paper.**
1. Copy the PDF into `Papers/`. Avoid spaces in the file name, e.g. `2027-ACRONYM.pdf`.
2. In `_data/publications.yml`, copy the template from the top of the file and paste it as the
   first entry of the list:
   ```yaml
   - year: 2027
     type: conference
     topics: [ids]
     status: Accepted
     title: "My new paper: with a colon, so it is in quotes"
     authors: A. Author and J.M.C. Silva
     venue: Conference Name (ACRONYM 2027), City
     pdf: 2027-ACRONYM.pdf
   ```
   When the DOI is out, add `doi: 10.xxxx/…` and remove `status`.

**A student defended.** Move the student's block from `msc_ongoing` to the top of
`msc_concluded` in `_data/supervision.yml`. Rename `since:` to `year:`.

**A project ended.** Move its block from `ongoing` to the top of `previous` in `_data/projects.yml`.

**Add a news item.** Add a block at the top of `_data/news.yml`, and remove old ones you no longer
want on the home page. The `text` field accepts Markdown: `*italic*` and `[link](https://…)`.

## Three YAML rules

1. **Indentation matters.** Use spaces, never tabs. Keep each field aligned with the field above it.
2. **Quote text that contains `: `** (a colon followed by a space), or that starts with a
   special character such as `*`, `[`, `{`, `&`, `#` or `@`. For example:
   `title: "P4Log: High-Throughput Log Replication"`.
3. Each entry starts with `- ` (dash and space). Leave a blank line between entries; it is optional,
   but it makes the file easier to read.

## Option A — edit directly on github.com

1. Open the repository on GitHub, go to `_data/`, open the file and click the pencil icon.
2. Make the change and click **Commit changes**.
3. GitHub rebuilds the site in about a minute.
   If the build fails, you get an email and the **Actions** tab shows the failed run in red,
   usually with the line number of the problem. The previous version stays online until you fix it.

To upload a PDF, open the `Papers/` folder, choose **Add file → Upload files**, and commit.

## Option B — edit on your computer

1. Edit the files in this folder.
2. Check them:
   ```sh
   ruby scripts/check_data.rb
   ```
   This finds YAML mistakes, missing required fields, unknown topics, and PDFs that are not in
   `Papers/`. It uses the Ruby that comes with macOS.
3. Commit and push:
   ```sh
   git add -A && git commit -m "Add new paper" && git push
   ```

## Going back to the previous design

The site as it was before the redesign is kept in two places in this repository:

- the branch `legacy-site`;
- the tag `legacy-site-2026-11-21`.

To see the old files: `git switch legacy-site`, then `git switch master` to come back.

To publish the old design again, run:

```sh
git switch master
git reset --hard legacy-site
git push --force
```

This discards the redesign on `master`. It still exists on its own branch (`redesign`) and in the
history, so it can be restored the same way.

## Where the design lives (only if you want to change the look)

- `_layouts/modern.html`: the page frame (menu, sidebar, footer).
- `_includes/modern/*.html`: one file per page, which turns the data into HTML.
- `assets/css/modern.css`: colours and styles.
- `assets/js/modern.js`: the search, filters and BibTeX button on the Publications page.

The original Academic Pages theme files are still in the repository and unchanged.
Pages that were not redesigned (for example `/talks/` and `/sitemap/`) still use them.
