library(e1071)
library(caret)
sched_dummy <- select(sched, Result, Team, Opp, Comp, Home, Season)
sched_dummy <- model.matrix(Result ~ .-1, data = sched_dummy)

resdmy <- dummyVars(" ~ Result", data = sched)
res_dummy <- data.frame(predict(resdmy, newdata = sched))

# split the data into training and testing data sets
set.seed(100)
split <- sample(nrow(sched_dummy), floor(0.7*nrow(sched_dummy)))
train <-sched_dummy[split,]
test <- sched_dummy[-split,]
trainres <- res_dummy[split,]
testres <- res_dummy[-split,]

nb <- naiveBayes(x = train, y = as.factor(trainres))

library(naivebayes)
nb <- naive_bayes(x = train, y = trainres)
nb_results <- predict(nb, newdata = test)
which(nb_results == "W")
