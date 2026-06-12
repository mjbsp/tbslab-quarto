Page made with lots of help from Claude Opus 4.8

# Quick start — running this prototype

You have Quarto installed. You also need R with a few packages:

```r
install.packages(c("tidyverse", "readr", "knitr"))
```

Then, from this folder:

```bash
quarto preview     # live preview at http://localhost:port (auto-refreshes)
# or
quarto render      # builds the finished site into docs/
```

## What's here

- `index.qmd` .............. homepage (logo, intro, project grid, selected pubs)
- `people.qmd` ............. people grids + alumni table
- `people/researchers/` .... Brandt, Cassario, Mulwa
- `people/mascots/` ........ Loempia
- `people/alumni.csv` ...... alumni (edit rows to add/remove)
- `projects.qmd` + `projects/` ... four project pages
- `publications.qmd` ....... full list, built from `pubs.csv`
- `pubs.csv` ............... your publication spreadsheet (141 entries, imported)
- `join.qmd`, `philosophy.qmd` ... lab docs
- `styles.scss` ............ colors/fonts (pink accent carried over)
- `_quarto.yml` ............ site config / navbar

## Common edits

- Add a paper: open `pubs.csv`, add a row (year, content, doi, pdf, code, data).
- Feature a paper on the homepage: add a `featured` column to `pubs.csv` and put
  any value (e.g. `x`) in that column for papers you want highlighted. If the
  column is absent/empty, the 5 newest papers show automatically.
- Add a person: copy a file in `people/researchers/`, edit it, drop a photo in `img/`.
- Add an alum: add a row to `people/alumni.csv`.

## Notes / things you may want to tweak

- **CVs/PDFs**: link out to OSF/personal sites as before. Put any local PDFs in `files/`.

## Tagging publications (projects + homepage)

`pubs.csv` now has two extra columns you can use:

- **`featured`** — put any value (e.g. `x`) to feature a paper in the
  "Selected Publications" list on the homepage. If the column is empty for all
  rows, the 5 newest papers show automatically.
- **`projects`** — tag a paper to one or more projects with these codes
  (comma-separate for multiple): 

  | code | project |
  |------|---------|
  | `bsd` | Belief System Dynamics |
  | `experiences` | Experiences and Change |
  | `wvc` | Worldview Conflict |
  | `improve` | Improving Psychological Science |

  Each project page automatically shows a "Related publications" list of its
  tagged papers. Example: a paper tagged `bsd, wvc` appears on both project pages.

All publication display logic lives in `_pubs.R` (one shared file), so the
homepage, publications page, and project pages stay consistent.
