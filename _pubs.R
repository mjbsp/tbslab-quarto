# Shared publication helpers. Sourced by index.qmd, publications.qmd, and project pages.
suppressMessages({library(readr); library(dplyr)})

load_pubs <- function(path = "pubs.csv") {
  # Read robustly whether the CSV was saved as UTF-8 or Windows/Latin-1.
  # Try UTF-8 first; if that errors on an invalid byte, fall back to Latin-1.
  read_with <- function(enc)
    readr::read_csv(path, show_col_types = FALSE,
                    locale = readr::locale(encoding = enc))
  df <- tryCatch(read_with("UTF-8"),
                 error   = function(e) read_with("windows-1252"),
                 warning = function(w) read_with("windows-1252"))
  # Declare character columns as UTF-8 so cat()/gsub() don't choke on a
  # non-UTF-8 session locale (common on Windows).
  char_cols <- vapply(df, is.character, logical(1))
  df[char_cols] <- lapply(df[char_cols], function(x) {
    x <- enc2utf8(x); Encoding(x) <- "UTF-8"; x
  })
  df
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

# Sort a people data frame by recency: most recent END year first, ties broken
# alphabetically by Name. Handles Years like "2020", "2018-2020", "2018-2020",
# or blank (blanks sort last).
sort_by_recency <- function(df) {
  df <- as.data.frame(df, stringsAsFactors = FALSE)
  yrs <- if ("Years" %in% names(df)) as.character(df$Years) else rep(NA_character_, nrow(df))
  end_year <- sapply(yrs, function(y) {
    if (is.na(y) || y == "") return(-1)
    nums <- as.integer(unlist(regmatches(y, gregexpr("[0-9]{4}", y))))
    if (length(nums) == 0) return(-1)
    max(nums)            # end year = latest 4-digit number present
  }, USE.NAMES = FALSE)
  df[order(-end_year, df$Name), , drop = FALSE]
}

# Build a simple roster (Research Master's students, Bachelor RAs, etc.).
# Reads a CSV with columns: Name, Years (optional), Link (optional), Tag (optional).
# Each person is a plain row: name, optional year-range, then small badge icons:
#   - mortarboard icon (links to Link) if they have a profile
#   - paper icon (non-clickable badge) if they have lab publications (Tag matches
#     a non-empty `people` cell in pubs.csv)
# Most rows are just a name; icons appear only when real.
print_roster <- function(csv_path, pubs_path = "pubs.csv") {
  people <- sort_by_recency(load_pubs(csv_path))
  pubs   <- load_pubs(pubs_path)

  cat('<ul class="roster">')
  for (i in seq_len(nrow(people))) {
    name  <- people$Name[i]
    years <- if ("Years" %in% names(people) && !is.na(people$Years[i])) people$Years[i] else ""
    link  <- if ("Link"  %in% names(people)) people$Link[i] else NA
    tag   <- if ("Tag"   %in% names(people)) people$Tag[i]  else NA

    has_pubs <- !is.na(tag) && tag != "" &&
                nrow(pubs_tagged(pubs, tag, column = "people")) > 0
    has_link <- !is.na(link) && link != ""

    cat('<li class="roster-item">')
    cat(sprintf('<span class="roster-name">%s</span>', name))
    if (years != "") cat(sprintf('<span class="roster-years">%s</span>', years))
    if (has_link)
      cat(sprintf('<a class="roster-badge roster-scholar" href="%s" target="_blank" rel="noopener" title="Profile"><i class="bi bi-mortarboard-fill"></i></a>', link))
    if (has_pubs)
      cat('<span class="roster-badge roster-paper" title="Co-author on lab publications"><i class="bi bi-file-earmark-text-fill"></i></span>')
    cat('</li>')
  }
  cat('</ul>')
}

# Combined inline roster: merge one or more people CSVs into a single flowing,
# comma-separated list (acknowledgments style). Each entry is the name, then
# years + GS/paper badges in parentheses when present. Sorted by recency
# (latest end year first, ties alphabetical by name).
print_inline_roster <- function(csv_paths, pubs_path = "pubs.csv") {
  frames <- lapply(csv_paths, function(p) {
    d <- as.data.frame(load_pubs(p), stringsAsFactors = FALSE)
    for (col in c("Name", "Years", "Link", "Tag"))
      if (!col %in% names(d)) d[[col]] <- NA_character_
    d[, c("Name", "Years", "Link", "Tag")]   # align columns before merging
  })
  people <- do.call(rbind, frames)
  people <- sort_by_recency(people)
  pubs   <- load_pubs(pubs_path)

  entries <- character(0)
  for (i in seq_len(nrow(people))) {
    name  <- people$Name[i]
    years <- if ("Years" %in% names(people) && !is.na(people$Years[i])) people$Years[i] else ""
    link  <- if ("Link"  %in% names(people)) people$Link[i] else NA
    tag   <- if ("Tag"   %in% names(people)) people$Tag[i]  else NA

    has_pubs <- !is.na(tag) && tag != "" &&
                nrow(pubs_tagged(pubs, tag, column = "people")) > 0
    has_link <- !is.na(link) && link != ""

    # build the parenthetical bits: years, then badges
    bits <- character(0)
    if (years != "") bits <- c(bits, sprintf('<span class="roster-years">%s</span>', years))
    if (has_link)
      bits <- c(bits, sprintf('<a class="roster-badge roster-scholar" href="%s" target="_blank" rel="noopener" title="Profile"><i class="bi bi-mortarboard-fill"></i></a>', link))
    if (has_pubs)
      bits <- c(bits, '<span class="roster-badge roster-paper" title="Co-author on lab publications"><i class="bi bi-file-earmark-text-fill"></i></span>')

    entry <- sprintf('<span class="roster-name">%s</span>', name)
    if (length(bits) > 0)
      entry <- paste0(entry, ' <span class="roster-meta">(', paste(bits, collapse = " "), ')</span>')
    entries <- c(entries, sprintf('<span class="inline-roster-item">%s</span>', entry))
  }
  cat('<p class="inline-roster">', paste(entries, collapse = ", "), '</p>')
}

# Build the alumni accordion. Reads an alumni CSV (Name, Role, Link, Tag) and,
# for each alum, makes a clickable row that expands their Lab Publications.
# Alumni with no tagged publications render as a plain, non-expanding row.
# A Google Scholar icon (from the Link column) sits beside each name as a
# separate link.
print_alumni_accordion <- function(alumni_path = "people/alumni.csv",
                                    pubs_path = "pubs.csv") {
  alum <- sort_by_recency(load_pubs(alumni_path))
  pubs <- load_pubs(pubs_path)

  scholar_icon <- function(url) {
    if (is.na(url) || url == "") return("")
    sprintf('<a class="alum-scholar" href="%s" target="_blank" rel="noopener" title="Google Scholar"><i class="bi bi-mortarboard-fill"></i></a>', url)
  }

  cat('<div class="accordion alumni-accordion" id="alumniAccordion">')
  for (i in seq_len(nrow(alum))) {
    name <- alum$Name[i]
    role <- if ("Role" %in% names(alum) && !is.na(alum$Role[i])) alum$Role[i] else ""
    years <- if ("Years" %in% names(alum) && !is.na(alum$Years[i])) alum$Years[i] else ""
    if (years != "") role <- if (role != "") paste0(role, ", ", years) else years
    link <- if ("Link" %in% names(alum)) alum$Link[i] else NA
    tag  <- if ("Tag"  %in% names(alum)) alum$Tag[i]  else NA

    their_pubs <- if (!is.na(tag) && tag != "")
      pubs_tagged(pubs, tag, column = "people") else pubs[0, ]
    has_pubs <- nrow(their_pubs) > 0
    id <- paste0("alum", i)

    cat('<div class="accordion-item">')
    cat('<div class="accordion-header alum-row">')
    cat(scholar_icon(link))
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
