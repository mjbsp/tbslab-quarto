# The Belief Systems Laboratory

Developed from my old Hugo hosted website with the help of Claude Opus 4.8

Source for [tbslaboratory.com](https://tbslaboratory.com), built with [Quarto](https://quarto.org).
Publications render through R from a spreadsheet.

## Repository layout

```
_quarto.yml          Site config: title, navbar, theme, output dir
index.qmd            Homepage
people.qmd           Renders the people grids; people live in people/<group>/
projects.qmd         Renders the project portfolio; projects live in projects/
publications.qmd     Year-grouped publication list, built from the spreadsheet
pubs.xlsx / pubs.csv The editable publication list
join.qmd             "Join the lab" page
philosophy.qmd       Lab philosophy page
styles.css           Site colors and fonts
img/                 Logo, avatars, project images
files/               CVs and other PDFs
docs/                Rendered site (committed; Netlify serves this)
```

## Editing the site

| To do this… | Edit this… |
|---|---|
| Add a publication | `pubs.xlsx` (add a row), then re-render |
| Add a lab member | new file in `people/<group>/`, plus a photo in `img/` |
| Edit a project or bio | the relevant `.qmd` file |
| Add a navbar item | `_quarto.yml` |
| Change colors | `styles.css` |

### Adding a person

Create `people/<group>/lastname.qmd` (groups: `researchers`, `mascots`).
Minimal front-matter:

```yaml
---
title: "First Last"
subtitle: "Role"
image: lastname.jpg
about:
  template: jolla
  links:
    - icon: envelope
      text: email
      href: mailto:someone@msu.edu
---

Biography text goes here.
```

Alumni who don't need a full page go into `people/alumni.csv` as rows.

### Adding a publication

Open the publication spreadsheet and add a row. Columns:
`year`, `content`, `doi`, `pdf`, `code`, `data`. Leave a link column blank
if it doesn't apply. The publications page builds the list automatically.

## Building locally

Requires [Quarto](https://quarto.org/docs/get-started/) and R, plus these R packages:

```r
install.packages(c("tidyverse", "here", "readxl"))
```

Then:

```bash
quarto preview   # live local preview that auto-refreshes as you edit
quarto render    # build the full site into docs/
```

## Publishing

The rendered site in `docs/` is committed to the repo, and Netlify serves it
directly (publish directory = `docs`, no build command). To publish a change:

```bash
quarto render
git add -A
git commit -m "Update site"
git push
```

Netlify redeploys automatically on push.

> If you ever prefer Netlify to build the site itself, set the build command to
> `quarto render` in `netlify.toml` and ensure Quarto + R are available on the
> build image. See the commented block in `netlify.toml`.

## License

Code and templates in this repository are released under the MIT License
(see [`LICENSE`](LICENSE)). Written site content (biographies, project
descriptions, and other prose) is licensed
[CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).
