# Shared publication helpers. Sourced by index.qmd, publications.qmd, and project pages.
suppressMessages({library(readr); library(dplyr)})

load_pubs <- function(path = "pubs.csv") {
  readr::read_csv(path, show_col_types = FALSE)
}

# Render one <li> for a publication row (content + doi/pdf/code/data links)
pub_li <- function(row) {
  out <- paste0("<li>", row$content)
  links <- c(doi = row$doi, pdf = row$pdf, code = row$code, data = row$data)
  links <- links[!is.na(links) & links != ""]
  if (length(links))
    out <- paste0(out, " ",
                  paste(sprintf('<a href="%s">%s</a>', links, names(links)),
                        collapse = " | "))
  paste0(out, "</li>")
}

# Print a flat <ul> list of the given rows (used on homepage & project pages)
print_pub_list <- function(df) {
  if (nrow(df) == 0) { cat("*None yet.*\n"); return(invisible()) }
  cat('<ul class="pub-list">')
  for (i in seq_len(nrow(df))) cat(pub_li(df[i, ]))
  cat("</ul>")
}

# Print the full list grouped by year, preserving spreadsheet order
print_pubs_by_year <- function(df) {
  for (yr in unique(df$year)) {
    cat(sprintf('\n## %s {.pub-year}\n', yr))
    print_pub_list(dplyr::filter(df, year == yr))
  }
}

# Does a comma-separated tag cell contain `tag`? (trims whitespace, case-insensitive)
has_tag <- function(cell, tag) {
  if (is.na(cell) || cell == "") return(FALSE)
  tags <- trimws(tolower(strsplit(cell, ",")[[1]]))
  tolower(tag) %in% tags
}

# Filter rows whose `column` tag-cell contains `tag`
pubs_tagged <- function(df, tag, column = "projects") {
  if (!column %in% names(df)) return(df[0, ])
  keep <- vapply(df[[column]], has_tag, logical(1), tag = tag)
  df[keep, ]
}

# Featured rows for the homepage: any non-empty `featured` cell; else newest n
pubs_featured <- function(df, n = 5) {
  if ("featured" %in% names(df) && any(!is.na(df$featured) & df$featured != ""))
    dplyr::filter(df, !is.na(featured) & featured != "")
  else
    dplyr::slice_head(df, n = n)
}

# Print a "Publications" section for one person, tagged in the `people` column.
# If the person has no tagged publications, prints NOTHING (no heading at all).
print_person_pubs <- function(tag, path = "../../pubs.csv",
                              heading = "Lab Publications", level = 2) {
  df <- load_pubs(path)
  matched <- pubs_tagged(df, tag, column = "people")
  if (nrow(matched) == 0) return(invisible())
  cat(sprintf("\n%s %s\n\n", strrep("#", level), heading))
  print_pub_list(matched)
}

# Build the alumni accordion. Reads an alumni CSV (Name, Role, Link, Tag) and,
# for each alum, makes a clickable row that expands their Lab Publications.
# Alumni with no tagged publications render as a plain, non-expanding row.
# A Google Scholar icon (from the Link column) sits beside each name as a
# separate link.
print_alumni_accordion <- function(alumni_path = "people/alumni.csv",
                                    pubs_path = "pubs.csv") {
  alum <- load_pubs(alumni_path)
  pubs <- load_pubs(pubs_path)

  scholar_icon <- function(url) {
    if (is.na(url) || url == "") return("")
    sprintf(' <a class="alum-scholar" href="%s" target="_blank" rel="noopener" title="Google Scholar"><i class="bi bi-mortarboard-fill"></i></a>', url)
  }

  cat('<div class="accordion alumni-accordion" id="alumniAccordion">')
  for (i in seq_len(nrow(alum))) {
    name <- alum$Name[i]
    role <- if ("Role" %in% names(alum) && !is.na(alum$Role[i])) alum$Role[i] else ""
    link <- if ("Link" %in% names(alum)) alum$Link[i] else NA
    tag  <- if ("Tag"  %in% names(alum)) alum$Tag[i]  else NA

    their_pubs <- if (!is.na(tag) && tag != "")
      pubs_tagged(pubs, tag, column = "people") else pubs[0, ]
    has_pubs <- nrow(their_pubs) > 0
    id <- paste0("alum", i)

    cat('<div class="accordion-item">')
    cat('<div class="accordion-header alum-row">')
    if (has_pubs) {
      cat(sprintf(
        '<button class="accordion-button collapsed alum-name" type="button" data-bs-toggle="collapse" data-bs-target="#%s" aria-expanded="false" aria-controls="%s"><span class="alum-name-text">%s</span><span class="alum-role">%s</span></button>',
        id, id, name, role))
    } else {
      # No publications: plain, non-expanding row (no caret, no toggle)
      cat(sprintf(
        '<div class="alum-name alum-static"><span class="alum-name-text">%s</span><span class="alum-role">%s</span></div>',
        name, role))
    }
    cat(scholar_icon(link))
    cat('</div>')  # accordion-header

    if (has_pubs) {
      cat(sprintf('<div id="%s" class="accordion-collapse collapse" data-bs-parent="#alumniAccordion"><div class="accordion-body">', id))
      print_pub_list(their_pubs)
      cat('</div></div>')
    }
    cat('</div>')  # accordion-item
  }
  cat('</div>')  # accordion
}
