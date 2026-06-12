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
                              heading = "Publications", level = 2) {
  df <- load_pubs(path)
  matched <- pubs_tagged(df, tag, column = "people")
  if (nrow(matched) == 0) return(invisible())
  cat(sprintf("\n%s %s\n\n", strrep("#", level), heading))
  print_pub_list(matched)
}
