install.packages("neuralnet")
library(nnet)
library(caret)
install.packages("dummies")
library(dummies)
install.packages("FeatureHashing")
library(FeatureHashing)

sched_dummy <- select(sched, Result, Team, Opp, Comp, Venue, Season)
dmy <- dummyVars(" ~ .", data = sched_dummy)
sched_dummy <- data.frame(predict(dmy, newdata = sched_dummy))

# split the data into training and testing data sets
set.seed(100)
split <- sample(nrow(sched_dummy), floor(0.5*nrow(sched_dummy)))
train <-sched_dummy[split,]
test <- sched_dummy[-split,]

outcomeNamess <- c("ResultW", "ResultD", "ResultL")
predictorNames <- setdiff(colnames(sched_dummy), outcomeNames)

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
