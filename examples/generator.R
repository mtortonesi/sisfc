#!/usr/bin/env Rscript

suppressMessages(library(VGAM))
library(truncnorm) # for truncated normal distribution

# request generation is modeled with a Pareto distribution
# these values were chosen to generate roughly 6666.667 requests per second
location            <- 1.2E-4
shape               <- 5
requests.per.second <- (shape - 1) / (shape * location)

# generate 10 minutes of requests
simulation.time <- 10 * 60

# number of requests
num.requests <- 1.2 * simulation.time * requests.per.second

# latency is modeled as a gaussian distribution
# these values were chosen to model roughly 100ms of communication latency
mu          <-   1E-1 # mean latency is 100ms
sigma       <- 2.5E-2 # standard deviation is 25ms
min.latency <-   2E-2 # minimum latency is 20ms

# number of data centers
num.data.centers <- 2

# request generation times
first.request.time         <- as.POSIXct(as.Date("18/1/2013", "%d/%m/%Y"))
request.interarrival.times <- rpareto(num.requests, location, shape)
generation.times           <- diffinv(request.interarrival.times, xi=first.request.time)

# data center ids
data.center.ids <- sample.int(num.data.centers, length(generation.times), replace=T)

# request arrival time
latencies         <- rtruncnorm(length(generation.times), a=min.latency, b=Inf, mean=mu, sd=sigma)
arrival.times     <- generation.times + latencies
workflow.type.ids <- rep(1, length(generation.times))
customer.ids      <- rep(1, length(generation.times))

# prepare data frame and output it on the console
df <- data.frame(Generation.Time  = generation.times,
                 # Data.Center.ID   = data.center.ids,
                 # Arrival.Time     = arrival.times,
                 Workflow.Type.ID = workflow.type.ids,
                 Customer.ID      = customer.ids)
write.csv(df[order(df$Generation.Time),], row.names=F)
