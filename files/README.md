# files/ — self-hosted downloads

Anything in this folder is published with the site and served by Netlify at
`https://tbslaboratory.com/files/...`. Drop a file in, reference it, push.

## Structure

- `papers/`  — PDFs of papers (drafts and final versions)
- `cvs/`     — CVs
- `misc/`    — anything else (posters, slides, supplementary docs)

## Naming convention (papers)

Use: `year.authors.title.journal-abbrev.pdf`, no spaces.
Example:
  papers/2026.Trikietal.PartyCues.JESP.pdf

Keep the filename STABLE. To swap a draft for the final version, replace the
file with the same name — every link that points to it keeps working, and
you never touch pubs.csv.

## Linking

In pubs.csv, a self-hosted paper's `pdf` column is just the path:
  files/papers/brandt-2026-belief-systems.pdf

On a person page or anywhere in a .qmd:
  [CV](files/cvs/brandt-cv.pdf)

## Size guidance

Keep individual files small (PDFs are usually 1–5 MB). GitHub rejects files
over 100 MB and the repo should stay well under ~1 GB. For a lab site's
papers and CVs you have room for hundreds of files.
