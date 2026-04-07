#loading data
data <- read.csv("analysis/data/trials.csv")

#process data into percentage accuracy
data$accuracy <- data$numberCorrect / (data$numberCorrect + data$numberIncorrect)

#keeping relevant data columns from the csv file
data2 <- data[, c("feedbackType", "thinkingTime", "accuracy",
                  "totalSleepTimeHours", "memoryScore")]

#renaming data columns
names(data2) <- c("feedbackType", "responseTime", "accuracy",
                  "totalSleepTimeHours", "memoryScore")

#converting data types
data2$feedbackType <- as.factor(data2$feedbackType)
data2$responseTime <- as.numeric(data2$responseTime)
data2$accuracy <- as.numeric(data2$accuracy)
data2$totalSleepTimeHours <- as.numeric(data2$totalSleepTimeHours)
data2$memoryScore <- as.numeric(data2$memoryScore)

#remove NA data points as its unreadable
data2 <- na.omit(data2)

#set positive as reference group for multiple linear regression
data2$feedbackType <- relevel(data2$feedbackType, ref = "POSITIVE")

#generates models
model_acc <- lm(accuracy ~ feedbackType + totalSleepTimeHours + memoryScore, data = data2)
summary(model_acc) #acc for accuracy

model_rt <- lm(responseTime ~ feedbackType + totalSleepTimeHours + memoryScore, data = data2)
summary(model_rt) #rt for response time

#generates residuals png for response time data and saves it in folder
png("qq_residuals_rt.png", width = 500, height = 400)
qqnorm(residuals(model_rt),
       xlab = expression("Standard normal quantile, " * q[0](f)),
       ylab = "Quantile",
       main = "")
qqline(residuals(model_rt))
dev.off()

#generates residuals png for response time data and saves it in folder
png("qq_residuals_acc.png", width = 500, height = 400)
qqnorm(residuals(model_acc),
       xlab = expression("Standard normal quantile, " * q[0](f)),
       ylab = "Quantile",
       main = "")
qqline(residuals(model_acc))
dev.off()

#estimation and p-value generation for Multiple Linear Regression console input
#summary(model_acc)
#summary(model_rt)