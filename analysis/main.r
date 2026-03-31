library(tidyverse)
library(checkmate)

# load trial csv data into dataframe from firebase output
system2("npx", args = c("tsx", "analysis/export.ts"))
full_df <- read_csv("analysis/data/trials.csv")

# split into positive and negative dfs:
positive_df <- full_df |> filter(feedbackType == "POSITIVE")
negative_df <- full_df |> filter(feedbackType == "NEGATIVE")

#' Plot two columns (for relationship):
#' 
#' @param x: Character - independent variable column string
#' @param y: Character - dependent variable column string
#' @param feedbackType: Character - "POSITIVE"/"NEGATIVE"
#' @param graph_type: Character - specification of the type of graph to be used
#' @param show_stats: Boolean - to print independent variable stats or not
#'  e.g: "point", "line", "bar", "box"
#' @return: ggplot object
plot_graph <- function(x, y, feedbackType, graph_type, show_stats) {
    assert_string(x)
    assert_string(y)
    assert_string(feedbackType)
    assert_string(graph_type)
    assertLogical(show_stats)

    if (feedbackType == "ALL") {
        df <- full_df 
    } else {
        df <- if (feedbackType == "POSITIVE") positive_df else negative_df
    }

    p <- ggplot(df, aes(x = .data[[x]], y = .data[[y]])) +
    geom_point(aes(color = "data"))

    unit = ""
    round_precision = 0
    if (y == "thinkingTime") {
        unit = "s"
        round_precision = 1
    } else if (y == "numberCorrect") {
        unit = " clicks"
        round_precision = 0
    }

    if (show_stats) {
        p <- p + scale_color_manual(
            values = c("data" = "steelblue"),
            labels = c(
                paste0(
                    "Mean = ", round(compute_mean(df, y), round_precision), unit, 
                    "\nStdev = ", round(compute_stdev(df, y), round_precision), unit, 
                    "\nMedian = ", round(compute_median(df, y), round_precision), unit,
                    "\nRange = ", round(compute_range(df, y), round_precision), unit
                )
            )
        )
    }

    p <- p + labs(
        x = paste(x, sprintf("(%s)", trimws(unit))),
        y = paste(y, sprintf("(%s)", trimws(unit))),
        title = paste(y, "vs.", x, "for", feedbackType, "feedback type"),
        color = "Stats"
    )

    if (graph_type == "line") {
        p <- p + geom_line()
    } else if (graph_type == "bar") {
        # bar chart visualization for mean values with error bars
        summary_df <- 
            full_df %>%
            group_by(.data[[x]]) %>%
            summarise(
                mean = compute_mean(full_df, y),
                std = compute_stdev(full_df, y),
                label = paste0(
                    round(mean, round_precision), " \u00B1 ", round(std, round_precision), unit
                )
            )

        p <- ggplot(summary_df, aes(x = .data[[x]], y = mean)) +
            geom_col(width = 0.6) +
            geom_errorbar(
                aes(ymin = mean - std, ymax = mean + std),
                width = 0.2
            ) +
            geom_text(
                aes(y = mean + std + 0.05 * max(mean + std), label = label), #setting unc = std
                size = 4
            ) +
            labs(
                title = paste("Mean", y, "by", x),
                x = x,
                y = paste("Mean", y, sprintf("(%s)", trimws(unit)))
            ) +
            theme_minimal()

    } else if (graph_type == "box") {
        # code to produce label annotations for whiskers, quartiles, median, and IQR
        values <- df[[y]]
        values <- values[!is.na(values)]

        q1 <- unname(quantile(values, 0.25))
        med <- median(values)
        q3 <- unname(quantile(values, 0.75))
        iqr_val <- IQR(values)

        lower_whisker <- min(values[values >= q1 - 1.5 * iqr_val])
        upper_whisker <- max(values[values <= q3 + 1.5 * iqr_val])

        label_df <- data.frame(
            x = 1,
            y = c(lower_whisker, q1, med, q3, upper_whisker),
            label = c(
                paste0("Lower whisker = ", round(lower_whisker, 2)),
                paste0("Q1 = ", round(q1, 2)),
                paste0("Median = ", round(med, 2)),
                paste0("Q3 = ", round(q3, 2)),
                paste0("Upper whisker = ", round(upper_whisker, 2))
            )
        )

        p <- p +
            geom_text(
                data = label_df,
                aes(x = x + 0.40, y = y, label = label),
                inherit.aes = FALSE,
                hjust = 0,
                size = 3
            ) +
            coord_cartesian(clip = "off") +
            theme(plot.margin = margin(5.5, 120, 5.5, 5.5))

        p <- p + geom_boxplot()
    } else {
        p <- p + geom_point()
    }

    ggsave(sprintf("./analysis/figures/%s_vs_%s__%s.png", y, x, feedbackType), plot = p, width = 8, height = 6)
    return(p)
}

#' Compute the mean of a column:
#' 
#' @param df: Dataframe (either positive/negative)
#' @param x: Character - Column variable string
#' @return: ggplot object
compute_mean <- function(df, x) {
    return(
        mean(df[[x]], na.rm = TRUE)
    )
}

#' Compute the standard deviation of a column:
#' 
#' @param df: Dataframe (either positive/negative)
#' @param x: Character - Column variable string
#' @return: ggplot object
compute_stdev <- function(df, x) {
    return(
        sd(df[[x]])
    )
}

#' Find the median of a column:
#'
#' @param df: Dataframe (either positive/negative)
#' @param x: Character - Column variable string
#' @return: ggplot object
compute_median <- function(df, x) {
    return(
        median(df[[x]])
    )
}

#' Find the range of a column:
#' 
#' @param df: Dataframe (either positive/negative)
#' @param x: Character - Column variable string
#' @return: ggplot object
compute_range <- function(df, x) {
    return(
        max(df[[x]], na.rm = TRUE) - min(df[[x]], na.rm = TRUE)
    )
}

# Time accuracy tradeoff
plot_graph("thinkingTime", "numberCorrect", "POSITIVE", "line", FALSE)
plot_graph("thinkingTime", "numberCorrect", "NEGATIVE", "line", FALSE)

# Box-and-whisker, response time & accuracy
plot_graph("feedbackType", "thinkingTime", "POSITIVE", "box", TRUE)
plot_graph("feedbackType", "thinkingTime", "NEGATIVE", "box", TRUE)
plot_graph("feedbackType", "numberCorrect", "POSITIVE", "box", TRUE)
plot_graph("feedbackType", "numberCorrect", "NEGATIVE", "box", TRUE)

# Bar chart for mean performance and variability
plot_graph("feedbackType", "thinkingTime", "ALL", "bar", TRUE)
plot_graph("feedbackType", "numberCorrect", "ALL", "bar", TRUE)