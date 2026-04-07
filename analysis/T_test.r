data <- read.csv("analysis/data/trials.csv", stringsAsFactors = FALSE)
data$accuracy <- data$numberCorrect / data$totalClicks

#do t_test for response and accuracy data
response_t_test <- t.test(thinkingTime ~ feedbackType, data = data, var.equal = FALSE)
accuracy_t_test <- t.test(accuracy ~ feedbackType, data = data, var.equal = FALSE)

#for response time, store mean values for positive and negative feedback groups as well as t_statistic, p_value, and confidence bound from t-test
response_results <- c(
    mean_positive = mean(data$thinkingTime[data$feedbackType == "POSITIVE"]),
    mean_negative = mean(data$thinkingTime[data$feedbackType == "NEGATIVE"]),
    t_statistic = unname(response_t_test$statistic),
    data = unname(response_t_test$parameter),
    p_value = response_t_test$p.value,
    conf_low = response_t_test$conf.int[1],
    conf_high = response_t_test$conf.int[2]
)


#for accuracy, store mean values for positive and negative feedback groups as well as t_statistic, p_value, and confidence bound from t-test
accuracy_results <- c(
    mean_positive = mean(data$accuracy[data$feedbackType == "POSITIVE"]),
    mean_negative = mean(data$accuracy[data$feedbackType == "NEGATIVE"]),
    t_statistic = unname(accuracy_t_test$statistic),
    data = unname(accuracy_t_test$parameter),
    p_value = accuracy_t_test$p.value,
    conf_low = accuracy_t_test$conf.int[1],
    conf_high = accuracy_t_test$conf.int[2]
)

#print out t-test results 
print(response_results)
print(accuracy_results)