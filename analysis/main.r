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

    # Append a percent accuracy column with calculations to the df
    full_df <- full_df %>%
        mutate(
            percentAccuracy = if_else(totalClicks > 0, numberCorrect / totalClicks * 100, NA_real_)
        )

    positive_df <- full_df %>% filter(feedbackType == "POSITIVE")
    negative_df <- full_df %>% filter(feedbackType == "NEGATIVE")

    if (feedbackType == "ALL") {
        df <- full_df 
    } else {
        df <- if (feedbackType == "POSITIVE") positive_df else negative_df
    }

    p <- ggplot(df, aes(x = .data[[x]], y = .data[[y]])) +
    geom_point(aes(color = "data"))

    # Ensuring proper units and precision
    unit_x = "" 
    unit_y = ""
    round_precision_x = 0
    round_precision_y = 0
    if (x == "thinkingTime") {
        unit_x = "s"
        round_precision_x = 1
    } else if (x == "percentAccuracy") {
        unit_x = "%"
        round_precision_x = 0
    }

    if (y == "thinkingTime") {
        unit_y = "s"
        round_precision_y = 1
    } else if (y == "percentAccuracy") {
        unit_y = "%"
        round_precision_y = 0
    } 

    if (show_stats) {
        p <- p + scale_color_manual(
            values = c("data" = "steelblue"),
            labels = c(
                paste0(
                    "Mean = ", round(compute_mean(df, y), round_precision_y), unit_y, 
                    "\nStdev = ", round(compute_stdev(df, y), round_precision_y), unit_y, 
                    "\nMedian = ", round(compute_median(df, y), round_precision_y), unit_y,
                    "\nRange = ", round(compute_range(df, y), round_precision_y), unit_y
                )
            )
        )
    }

    p <- p + labs(
        x = paste(x, sprintf("(%s)", trimws(unit_x))),
        y = paste(y, sprintf("(%s)", trimws(unit_y))),
        title = paste(y, "vs.", x, "for", feedbackType, "feedback type"),
        color = "Stats"
    )
    if (graph_type == "linear") {
        # fit the data points to a linear fit
        p <- p + geom_smooth(method = "lm", formula = y ~ x, se = TRUE)

    } else if (graph_type == "quadratic") {
        # fit the data points to a quadratic fit
        p <- p + geom_smooth(method = "lm", formula = y ~ poly(x, 2), se = TRUE)

    } else if (graph_type == "bar") {
        # bar chart visualization for mean values with error bars
        summary_df <- 
            full_df %>%
            group_by(.data[[x]]) %>%
            summarise(
                mean = compute_mean(pick(everything()), y),
                std = compute_stdev(pick(everything()), y),
                label = paste0(
                    round(mean, round_precision_y), " \u00B1 ", round(std, round_precision_y), unit_y
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
                y = paste("Mean", y, sprintf("(%s)", trimws(unit_y)))
            ) +
            theme_minimal()

    } else if (graph_type == "box") {
        # code to produce label annotations for whiskers, quartiles, median, and IQR (per feedback group)
        box_stats <- full_df %>%
            filter(!is.na(.data[[y]])) %>%
            group_by(feedbackType) %>%
            summarise(
                q1            = quantile(.data[[y]], 0.25),
                med           = median(.data[[y]]),
                q3            = quantile(.data[[y]], 0.75),
                iqr_val       = IQR(.data[[y]]),
                lower_whisker = min(.data[[y]][.data[[y]] >= q1 - 1.5 * iqr_val]),
                upper_whisker = max(.data[[y]][.data[[y]] <= q3 + 1.5 * iqr_val]),
                .groups = "drop"
            )

        # Map feedbackType to numeric positions for x-offsetting
        map_levels <- unique(full_df$feedbackType)
        x_positions <- c(1.0, 2.0)
        names(x_positions) <- map_levels

        # add numeric x positions to the df for spacing in the plot
        full_df_plot <- full_df %>%
            mutate(x_num = x_positions[feedbackType])

        label_df <- box_stats %>%
            rowwise() %>% 
            reframe(
                feedbackType = feedbackType,
                x = x_positions[feedbackType],
                y = c(lower_whisker, q1, med, q3, upper_whisker),
                label = c(
                    paste0("Lower whisker = ", round(lower_whisker, 2)),
                    paste0("Q1 = ", round(q1, 2)),
                    paste0("Median = ", round(med, 2)),
                    paste0("Q3 = ", round(q3, 2)),
                    paste0("Upper whisker = ", round(upper_whisker, 2))
                ),
                x_offset = c(0.025, 0.25, 0.25, 0.25, 0.025),
                .groups = "drop"
            )

        p <- ggplot(full_df_plot, aes(x = x_num, y = .data[[y]])) +
            geom_boxplot(
                aes(group = feedbackType),
                width = 0.4
            ) +
            geom_text(
                data = label_df,
                aes(x = x + x_offset, y = y, label = label),
                inherit.aes = FALSE,
                hjust = 0,
                size = 3
            ) +
            scale_x_continuous(
                breaks = x_positions,
                labels = names(x_positions)
            ) + 
            coord_cartesian(clip = "off") +
            theme_minimal() +
            theme(plot.margin = margin(5.5, 150, 5.5, 5.5)) +
            labs(
                title = paste(y, "vs. feedbackTypes"),
                x = "feedbackType",
                y = paste(y, sprintf("(%s)", trimws(unit_y)))
            )

        # p <- p + geom_boxplot()
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
plot_graph("thinkingTime", "percentAccuracy", "POSITIVE", "linear", FALSE)
plot_graph("thinkingTime", "percentAccuracy", "NEGATIVE", "quadratic", FALSE)

# Box-and-whisker, response time & accuracy
plot_graph("feedbackType", "thinkingTime", "ALL", "box", TRUE)
plot_graph("feedbackType", "percentAccuracy", "ALL", "box", TRUE)

# Bar chart for mean performance and variability
plot_graph("feedbackType", "thinkingTime", "ALL", "bar", TRUE)
plot_graph("feedbackType", "percentAccuracy", "ALL", "bar", TRUE)