sched$Win <- ifelse(sched$Result == "W", 1, 0)
sched_dummy <- select(sched, Team, Opp, Comp, Home, Season)
sched_dummy <- model.matrix(~ .-1, data = sched_dummy)

# split the data into training and testing data sets
set.seed(100)
split <- sample(nrow(sched_dummy), floor(0.7*nrow(sched_dummy)))
train <-sched_dummy[split,]
test <- sched_dummy[-split,]
trainWin <- as.matrix(sched[split, 'Win'])
testWin <- as.matrix(sched[-split, 'Win'])
library(glmnet)
cv.fit <- cv.glmnet(x = train, y = as.factor(trainWin), family = "binomial", type.measure = "class", nfolds = 50)
lambdamin <- cv.fit$lambda.min
testing <- round(predict(cv.fit, newx = test, type = "response", s = 0.000000001),3)
predictWin <- ifelse(testing > 0.5, 1, 0)
mean(testWin == predictWin)
table(predictWin, true = testWin)
data.frame(predictWin, testWin)

