library(tidyverse)
library(checkmate)

# load trial csv data into dataframe from firebase output
system2("npx", args = c("tsx", "analysis/export.ts"))
df <- read_csv("analysis/data/trials.csv")

# split into positive and negative dfs:
positive_df <- df |> filter(feedbackType == "POSITIVE")
negative_df <- df |> filter(feedbackType == "NEGATIVE")

#' Plot two columns (for relationship):
#' 
#' @param x: Character - independent variable column string
#' @param y: Character - dependent variable column string
#' @param feedbackType: Character - "POSITIVE"/"NEGATIVE"
#' @param graph_type: Character - specification of the type of graph to be used
#' @param show_stats: Boolean - to print independent variable stats or not
#'  e.g: "point", "line", "bar", "boxplot"
#' @return: ggplot object
plot_graph <- function(x, y, feedbackType, graph_type, show_stats) {
    assert_string(x)
    assert_string(y)
    assert_string(feedbackType)
    assert_string(graph_type)
    assertLogical(show_stats)

    df <- if (feedbackType == "POSITIVE") positive_df else negative_df

    p <- ggplot(df, aes(x = .data[[x]], y = .data[[y]])) +
    geom_point(aes(color = "data"))


    if (show_stats) {
        p <- p + scale_color_manual(
            values = c("data" = "steelblue"),
            labels = c(
                paste0(
                    "Mean = ",   compute_mean(df, x),
                    "\nStdev = ", compute_stdev(df, x),
                    "\nMedian = ", compute_median(df, x),
                    "\nRange = ", compute_range(df, x)
                )
            )
        )
    }

    p <- p + labs(
        x = x,
        y = y,
        title = paste(y, "vs.", x, "for", feedbackType, "feedback type"),
        color = "Stats"
    )

    if (graph_type == "line") {
        p <- p + geom_line()
    } else if (graph_type == "bar") {
        p <- p + geom_bar(stat = "identity")
    } else if (graph_type == "boxplot") {
        p <- p + geom_boxplot()
    } else {
        p <- p + geom_point()
    }

    print(p)
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

plot_graph("thinkingTime", "numberIncorrect", "POSITIVE", "line", TRUE)
plot_graph("thinkingTime", "numberIncorrect", "NEGATIVE", "line", FALSE)