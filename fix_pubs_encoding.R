# fix_pubs_encoding.R ---------------------------------------------------
# Repairs "mojibake" in pubs.csv -- text mangled by an earlier bad encoding
# conversion (UTF-8 bytes misread as MacRoman).
#
# HOW TO USE:
#   1. Put this file in your project folder (next to pubs.csv)
#   2. In R:  source("fix_pubs_encoding.R")
#   3. It writes a backup (pubs_backup.csv), then fixes pubs.csv in place
#   4. Check the file, then re-render the site
#
# All escape codes below were verified against the actual file contents.
# -----------------------------------------------------------------------

infile <- "pubs.csv"
backup <- "pubs_backup.csv"

# --- read as UTF-8 ---
txt <- readLines(infile, encoding = "UTF-8", warn = FALSE)

# --- back up first ---
writeLines(txt, backup, useBytes = TRUE)
message("Backup written to ", backup)

# --- repair map: mangled sequence -> correct character ---
# NOTE: order matters. Multi-character sequences are listed first so they
# are replaced before any single-character rule could touch their pieces.
fixes <- list(
  # --- punctuation (3-char mojibake sequences) ---
  c("\u201a\u00c4\u00b6", "\u2026"),  # ellipsis  ...
  c("\u201a\u00c4\u00ec", "\u2013"),  # en dash
  c("\u201a\u00c4\u00ee", "\u2014"),  # em dash
  c("\u201a\u00c4\u00f4", "'"),       # right single quote / apostrophe
  c("\u201a\u00c4\u00fa", "\""),      # left double quote
  c("\u201a\u00c4\u00f9", "\""),      # right double quote

  # --- non-breaking space (2-char) ---
  c("\u00ac\u2020", " "),

  # --- accented letters (2-char) ---
  c("\u221a\u2260", "\u00ed"),  # i-acute
  c("\u221a\u00b0", "\u00e1"),  # a-acute
  c("\u221a\u00a9", "\u00e9"),  # e-acute
  c("\u221a\u00b3", "\u00f3"),  # o-acute
  c("\u221a\u222b", "\u00fa"),  # u-acute
  c("\u221a\u00a7", "\u00e4"),  # a-umlaut
  c("\u221a\u2202", "\u00f6"),  # o-umlaut
  c("\u221a\u00ba", "\u00fc"),  # u-umlaut
  c("\u221a\u00b1", "\u00f1"),  # n-tilde
  c("\u221a\u00df", "\u00e7"),  # c-cedilla
  c("\u2248\u2020", "\u0160"),  # S-caron (capital)
  c("\u2248\u00b0", "\u0161")   # s-caron (lower)
)

# --- count and apply ---
n_total <- 0L
for (f in fixes) {
  bad <- f[1]; good <- f[2]
  n <- sum(vapply(gregexpr(bad, txt, fixed = TRUE),
                  function(m) if (m[1] == -1L) 0L else length(m), integer(1)))
  if (n > 0L) {
    txt <- gsub(bad, good, txt, fixed = TRUE)
    n_total <- n_total + n
  }
}

# --- write back as UTF-8 ---
con <- file(infile, open = "wb")
writeLines(txt, con, useBytes = TRUE)
close(con)

message("Repaired ", n_total, " mangled sequence(s).")
message("pubs.csv rewritten as UTF-8.")
message("If anything looks wrong, restore from ", backup, ".")
