url <- "https://en.wikipedia.org/wiki/Opinion_polling_for_the_next_New_Zealand_general_election"

webpage <- url %>%
    read_html(encoding = "UTF-8")

tabs <- webpage %>%
    html_nodes("table")

# number below depends on the webpage...
tab <- html_table(tabs[[1]], fill = TRUE)

# knock out the historical commentaries:
tab <- tab[tab[ , 2] != tab[ , 3], 1:12]

tab <- tab[tab[, 1] != "Date[nb 1]", ]
tab <- tab[tab[, 1] != "Date[a]", ]

names(tab)[1] <- "WikipediaDates"

dates <- tab$WikipediaDates

extract_start_and_end_dates <- function(dates) {

    patterns <- c(
        "{p1_d1=[0-3]?[0-9]}-{p1_d2=[0-3]?[0-9]}, {p1_d3=[0-3]?[0-9]}-{p1_d4=[0-3]?[0-9]} {p1_M=[A-z]{3}} {p1_Y=20[0-9]{2}}",
        "{p2_d1=[0-3]?[0-9]}-{p2_d4=[0-3]?[0-9]} {p2_M=[A-z]{3}} {p2_Y=20[0-9]{2}}",
        "{p3_d1=[0-3]?[0-9]} {p3_M1=[A-z]{3}} - {p3_d4=[0-3]?[0-9]} {p3_M2=[A-z]{3}} {p3_Y=20[0-9]{2}}",
        "{p4_d1=[0-3]?[0-9]} {p4_M=[A-z]{3}} {p4_Y=20[0-9]{2}}"
    )
    start_date_pattern <- c(
        "{d1}/{M}/{Y}",
        "{d1}/{M}/{Y}",
        "{d1}/{M1}/{Y}",
        "{d1}/{M}/{Y}"
    )
    end_date_pattern <- c(
        "{d4}/{M}/{Y}",
        "{d4}/{M}/{Y}",
        "{d4}/{M2}/{Y}",
        "{d1}/{M}/{Y}"
    )

    ascii_date <- str_replace_all(stringi::stri_enc_toascii(dates), "\032", "-")
    date_tab <- unglue::unglue_data(ascii_date, patterns) %>%
        add_column(date = dates, .before=1) %>%
        add_column(ascii = ascii_date, .after=1) %>%
        add_column(matched = unglue_detect(ascii_date, patterns), .after=2) %>%
        gather(key="Variable", value="value", -date, -ascii, -matched) %>%
        filter(!is.na(value)) %>%
        separate(Variable, sep="_", into=c("pattern", "variable")) %>%
        spread(key=variable, value=value) %>%
        as_tibble() %>%
        mutate(pattern = as.integer(str_remove(pattern, "p"))) %>%
        rowwise() %>%
        mutate(start_date = glue(start_date_pattern[pattern], d1=d1, d4=d4, M=M, M2=M2, Y=Y)) %>%
        mutate(start_date = as.Date(start_date, "%d/%B/%y")) %>%
        mutate(end_date = glue(end_date_pattern[pattern], d1=d1, d4=d4, M=M, M2=M2, Y=Y)) %>%
        mutate(end_date = as.Date(end_date, "%d/%B/%y")) %>%
        select(date, start_date, end_date)

}

tab <- left_join(tab, extract_start_and_end_dates(tab$WikipediaDates), by=c("WikipediaDates"="date"))

x <- names(tab)
names(tab) <- case_when(
    x == "NAT" ~ "National",
    x == "LAB" ~ "Labour",
    x == "NZF" ~ "NZ First",
    x == "GRN" ~ "Green",
    x == "MRI" ~ "Maori",
    x == "NCP" ~ "Conservative",
    x == "Polling organisation" ~ "Poll",
    TRUE ~ names(tab)
)

# we *should* collect sample size but for now it is a TODO
polls2023 <- tab[, !names(tab) %in% c("Sample size", "Lead")]
