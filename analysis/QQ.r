data <- read.csv("analysis/data/trials.csv", stringsAsFactors = FALSE)
data$accuracy <- data$numberCorrect / data$totalClicks

#generate qq plot for response time and positive feedback
png("qq_response_positive.png", width = 1600, height = 1200, res = 200)
par(cex.lab = 1.8, cex.axis = 1.5, mar = c(5.5, 5.5, 2, 2))
qqnorm(
    data$thinkingTime[data$feedbackType == "POSITIVE"],
    xlab = expression("Standard normal quantile, " ~ q[0](f)),
    ylab = "Quantile",
    cex = 1.4
)
qqline(data$thinkingTime[data$feedbackType == "POSITIVE"], lwd = 2)
dev.off()

#generate qq plot for response time and negative feedback
png("qq_response_negative.png", width = 1600, height = 1200, res = 200)
par(cex.lab = 1.8, cex.axis = 1.5, mar = c(5.5, 5.5, 2, 2))
qqnorm(
    data$thinkingTime[data$feedbackType == "NEGATIVE"],
    xlab = expression("Standard normal quantile, " ~ q[0](f)),
    ylab = "Quantile",
    cex = 1.4
)
qqline(data$thinkingTime[data$feedbackType == "NEGATIVE"], lwd = 2)
dev.off()

#generate qq plot for accuracy and positive feedback
png("qq_accuracy_positive.png", width = 1600, height = 1200, res = 200)
par(cex.lab = 1.8, cex.axis = 1.5, mar = c(5.5, 5.5, 2, 2))
qqnorm(
    data$accuracy[data$feedbackType == "POSITIVE"],
    xlab = expression("Standard normal quantile, " ~ q[0](f)),
    ylab = "Quantile",
    cex = 1.4
)
qqline(data$accuracy[data$feedbackType == "POSITIVE"], lwd = 2)
dev.off()

#generate qq plot for accuracy and negative feedback
png("qq_accuracy_negative.png", width = 1600, height = 1200, res = 200)
par(cex.lab = 1.8, cex.axis = 1.5, mar = c(5.5, 5.5, 2, 2))
qqnorm(
    data$accuracy[data$feedbackType == "NEGATIVE"],
    xlab = expression("Standard normal quantile, " ~ q[0](f)),
    ylab = "Quantile",
    cex = 1.4
)
qqline(data$accuracy[data$feedbackType == "NEGATIVE"], lwd = 2)
dev.off()