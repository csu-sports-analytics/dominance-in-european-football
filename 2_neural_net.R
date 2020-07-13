install.packages("neuralnet")
library(neuralnet)
library(caret)
install.packages("dummies")
library(dummies)
install.packages("FeatureHashing")
library(FeatureHashing)

sched_dummy <- select(sched, Team, Opp, Comp, Home, Season)
dmy <- dummyVars(" ~ .", data = sched_dummy)
sched_dummy <- data.frame(predict(dmy, newdata = sched_dummy))

# split the data into training and testing data sets
set.seed(100)
sched_dummy <- cbind(sched$Result, sched_dummy)
colnames(sched_dummy)[1] <- "Result"
split <- sample(nrow(sched_dummy), floor(0.7*nrow(sched_dummy)))
train <-sched_dummy[split,]
test <- sched_dummy[-split,]


nn <- neuralnet((Result == "W") + (Result == "D") + (Result == "L") ~ .,
                data = train, hidden = 10, act.fct = "logistic",
                linear.output = FALSE, lifesign = "minimal", threshold = 0.01,
                err.fct = "ce", stepmax = 1e+10, rep = 1)
nn.results <- compute(nn, test)
results <- data.frame(actual = test$Result, prediction = nn.results$)



ResultW <- as.factor(ifelse(sched$Result == "W", 1, 0))
sched_dummy <- cbind(ResultW, sched)
sched_dummy <- model.matrix(ResultW ~ Team + Opp + Season + Home + Comp, data = sched)
# split the data into training and testing data sets
set.seed(100)
split <- sample(nrow(sched_dummy), floor(0.5*nrow(sched_dummy)))
train <-sched_dummy[split,]
test <- sched_dummy[-split,]
ResultW_train <- ResultW[split]
ResultW_test <- ResultW[-split]

install.packages("glmnet")
library(glmnet)
cv.fit <- cv.glmnet(x = train, y = ResultW_train,
              family = "binomial", )

library(broom)
lambdamin <- cv.fit$lambda.min
fit <-  glmnet(x = train, y = ResultW_train, family = "binomial", alpha = 0, lambda = lambdamin)
testing <- predict.glmnet(fit, newx = test)
results <- data.frame(actual = ResultW_test, prediction = testing)
table(results$actual,results$prediction)




library(randomForest)
RF_model <- randomForest(x = train[,4:ncol(train)], y = train$ResultW, ntree = 100)
predictRF <- predict(RF_model, newdata=test)
summary(RF_model)


outcomeNames <- c("ResultW", "ResultD", "ResultL")
predictorNames <- setdiff(colnames(sched_dummy), outcomeNames)


library(e1071)
nb_model <- naiveBayes(ResultW + ResultD + ResultL ~ ., data = train)
predict(nb_model, newdata = as.data.frame(test))


nb_model_W <- naiveBayes(ResultW ~ ., data = train)


library(glmnet)
# straight matrix model not recommended - works but very slow, go with a sparse matrix
# glmnetModel <- cv.glmnet(model.matrix(~., data=objTrain[,predictorNames]), objTrain[,outcomeNames], 
#             family = "binomial", type.measure = "auc")

glmnetModel <- cv.glmnet(sparse.model.matrix(~., data=train[,predictorNames]), train[,outcomeNames], 
                         type.measure = "auc")
glmnetPredict <- predict(glmnetModel,sparse.model.matrix(~., data=objTest[,predictorNames]), s="lambda.min")

neuralnet(train[,outcomeNamess] ~ train[,predictorNames], data = train, hidden = 10)


sched_hash <- select(sched, Result, Team, Opp, Comp, Venue, Season)
predictorNames <- setdiff(names(sched_hash),outcomeNames)

set.seed(100)
split <- sample(nrow(sched_hash), floor(0.5*nrow(sched_hash)))
objTrain <-sched_hash[split,]
objTest <- sched_hash[-split,]

library(FeatureHashing)
objTrain_hashed = hashed.model.matrix(~., data=objTrain[,predictorNames], hash.size=2^12, transpose=FALSE)
objTrain_hashed = as(objTrain_hashed, "dgCMatrix")
objTest_hashed = hashed.model.matrix(~., data=objTest[,predictorNames], hash.size=2^12, transpose=FALSE)
objTest_hashed = as(objTest_hashed, "dgCMatrix")

glmnetModel <- cv.glmnet(objTrain_hashed, objTrain[,outcomeNames], 
                         family = "binomial", type.measure = "auc")



# Creating model matrix to feed to network
res_mat <- class.ind(sched$Result)
sched_mat <- model.matrix(~ Team + Opp + Season + Comp + Venue - 1, data = sched)
sched_mat <- cbind(res_mat, sched_mat)

nn <- nnet(W + L + D ~ ., size = 3, weights = rep(1,nrow(sched_mat)), data = sched_mat)
plot(nn)
colnames(dmyTest)
plot(nn)


sched_test <- select(sched, Team, Opp, Venue, Comp, Season)
sched_test <- dummy.data.frame(sched_test, sep = ".")
sched_test <- cbind(res_mat, sched_test)
neuralnet(W + L ~ Comp + Team + Opp + Venue + Season, data = sched_mat, hidden = 3)

library(Matrix)
sched_mat <- sparse.model.matrix(~ ., data = sched[,c(3,5,6,7,8,11)])
sched_mat <- as.data.frame(sched_mat)
