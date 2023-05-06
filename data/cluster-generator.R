# setup
rm(list = ls())
if (!is.null(dev.list()["RStudioGD"])) {
  dev.off(dev.list()["RStudioGD"])
}
set.seed(1668527508) # make this reproducible
library(rjson)
library(plotrix)

# 4 clusters
if (F) {
  pointCount <- 500
  noiseRatio <- 0.136 # corresponds to 68 noise points
  clusterCount <- 4 # corresponds to 108 points/cluster
  minClusterVariance <- 0.05
  maxClusterVariance <- 0.10
  maxLayoutRetry <- 50
  maxPointRetry <- 100
}

# 5 clusters
if (T) {
  studyConfig <- list(
    pointCount = 600,
    noiseRatio = 200/600,
    clusterCount = 5,
    minClusterVariance = 0.05,
    maxClusterVariance = 0.10,
    maxLayoutRetry = 50,
    maxPointRetry = 100
  )
  studyConfig$clusterSize <- trunc(studyConfig$pointCount * (1 - studyConfig$noiseRatio) / studyConfig$clusterCount)
  studyConfig$noiseCount <- studyConfig$pointCount - studyConfig$clusterSize * studyConfig$clusterCount
  
  config <- studyConfig
  
  botConfig <- studyConfig
  botConfig$noiseRatio <- 50/botConfig$pointCount
  botConfig$clusterSize <- trunc(botConfig$pointCount * (1 - botConfig$noiseRatio) / botConfig$clusterCount)
  botConfig$noiseCount <- botConfig$pointCount - botConfig$clusterSize * botConfig$clusterCount
}



endOfDebugging <- function () {
  # get calling function
  callStack <- sys.calls()
  frameCount <- sys.nframe()
  funcName <- callStack[[frameCount-1]][[1]]
  
  # end execution
  msg <- paste("Reached end of ", funcName, ". Pausing.", sep = "")
  stop(msg)
}



collisionTest <- function(testCluster, otherClusters) {
  collision <- FALSE
  for (i in seq_along(otherClusters)) {
    existing <- otherClusters[[i]]
    # get actual distance
    actualDistance <- sqrt(
      (existing$x - testCluster$x)^2 +
      (existing$y - testCluster$y)^2
    )
    # get cluster radii
    # the radius of normal distributions is approx. 3 sigma (3 * variance)
    minDistance <- existing$variance * 3 + testCluster$variance * 3
    # check if they overlap
    if (actualDistance < minDistance) {
      collision <- TRUE
      break
    }
  }
  return(collision)
}

collisionList <- function(testCluster, otherClusters) {
  collisions <- list()
  for (i in seq_along(otherClusters)) {
    existing <- otherClusters[[i]]
    # get actual distance
    actualDistance <- sqrt(
      (existing$x - testCluster$x)^2 +
        (existing$y - testCluster$y)^2
    )
    # get cluster radii
    # the radius of normal distributions is approx. 3 sigma (3 * variance)
    minDistance <- existing$variance * 3 + testCluster$variance * 3
    # check if they overlap
    if (actualDistance < minDistance) {
      collisions[[length(collisions) + 1]] <- existing
    }
  }
  return(collisions)
}



newClusterAnywhere <- function(preserveX = NULL, preserveY = NULL, preserveVariance = NULL, xlim = c(0,1), ylim = c(0,1)) {
  # don't allow preserving too much
  if (!is.null(preserveX) && !is.null(preserveY)) {
    stop("Can't get new cluster position by preserving both X and Y.")
  }
  # force preserveVariance when x or y are preserved
  if (
    ( (!is.null(preserveX)) || (!is.null(preserveY)) )
    && is.null(preserveVariance)
  ){
    stop("Should also preserve Variance when preserving X or Y.")
  }
  
  # get new position in normalized coordinates
  if (missing(preserveX)) {
    x <- runif(1, min = xlim[1], max = xlim[2])
  } else {
    x <- preserveX
  }
  if (missing(preserveY)) {
    y <- runif(1, min = ylim[1], max = ylim[2])
  } else {
    y <- preserveY
  }
  # get new variance
  if (is.null(preserveVariance)) {
    variance <- runif(1, min = config$minClusterVariance, max = config$maxClusterVariance)
  } else {
    variance <- preserveVariance
  }
  return(list(x = x, y = y, variance = variance))
}
  
newClusterOnCircle <- function() {
  # get new position on circle
  pos <- runif(1, min = 0, max = 2 * pi)
  # transform to relative coordinates
  x <- 0.5 + sin(pos) * (0.5 - config$maxClusterVariance)
  y <- 0.5 + cos(pos) * (0.5 - config$maxClusterVariance)
  # get new variance
  variance <- runif(1, min = config$minClusterVariance, max = config$maxClusterVariance)
  return(list(x = x, y = y, variance = variance))
}

newMetaClusters <- function(
    preserveX = NULL,
    preserveY = NULL,
    xlim = c(0,1),
    ylim = c(0,1),
    howMany = config$clusterCount
) {
  # can't preserve both
  if (!is.null(preserveX) && !is.null(preserveY)) {
    stop("Can't preserve both meta coordinates, because there'd be no change at all.")
  }
  
  positions <- list()
  
  newCluster <- function (idx) {
    if (is.null(preserveX)) {
      if (is.null(preserveY)) {
        return(newClusterAnywhere(xlim = xlim, ylim = ylim))
      } else {
        return(newClusterAnywhere(
          preserveY = preserveY[[idx]]$y,
          preserveVariance = preserveY[[idx]]$variance,
          xlim = xlim,
          ylim = ylim
        ))
      }
    } else {
      # preserveX is set and they can't both be set => no need to check Y
      return(newClusterAnywhere(
        preserveX = preserveX[[idx]]$x,
        preserveVariance = preserveX[[idx]]$variance,
        xlim = xlim,
        ylim = ylim
      ))
    }
  }
  
  layoutRetryCount <- 0
  tryLayoutAgain <- TRUE
  while (tryLayoutAgain) {
    layoutRetryCount <- layoutRetryCount + 1
    if (layoutRetryCount > config$maxLayoutRetry) {
      stop("Too many layout retries.")
    }
    
    # first cluster won't hit anything
    positions <- list()
    positions[[1]] <- newCluster(1)
    
    # other clusters: generate a new one and use it,
    # if it doesn't collide with the existing ones
    pointRetryCount <- 0
    for (pointRetryCount in 1:config$maxPointRetry) {
      if (length(positions) >= howMany) {
        break
      }
      candidate <- newCluster(length(positions) + 1)
      if (!collisionTest(candidate, positions)) {
        positions[[length(positions) + 1]] <- candidate
      }
    }
    
    tryLayoutAgain <- length(positions) < howMany
    #if (tryLayoutAgain) {
    #  cat("Only got", length(positions), "clusters into layout.\n")
    #}
  }
  
  return(positions)
}

drawMetaClusters <- function(metaclusters, main = "", sub = "", ...) {
  plot(
    x = NULL,
    y = NULL,
    xlim = c(0,1),
    ylim = c(0,1),
    main = main,
    sub = sub,
    xlab = "",
    ylab = "",
    ...
  )
  
  for (cluster in metaclusters) {
    draw.circle(cluster$x, cluster$y, cluster$variance * 3)
  }
}



# get pairs of clusters with the smallest distances in a specific direction
closestPairs <- function(metaClusters, horizontal = TRUE) {
  # get relevant positions
  clusterPositions <- unlist(lapply(metaClusters, "[[", if (horizontal) "x" else "y"))
  
  # sort positions
  clusterOrder <- order(clusterPositions)
  sortedClusterPos <- clusterPositions[clusterOrder]
  
  # get smallest distances
  clusterDistances <- sortedClusterPos[-1] - sortedClusterPos[-length(sortedClusterPos)]
  distanceOrder <- order(clusterDistances)
  
  # get pairs of clusters with smallest distances
  from <- clusterOrder[distanceOrder]
  to <- clusterOrder[distanceOrder+1]
  
  pairs <- cbind(from, to)
  return(pairs)
}

debugClosestPairsH <- function() {
  mc <- newMetaClusters()
  mc <- newMetaClusters()
  positions <- unlist(lapply(mc, "[[", "x"))
  plot(x = positions, y = rep(0.5, length(mc)), type="p", xlim=c(0,1), ylim=c(0,1))
  
  actualDist <- abs(sort(positions)[-1] - sort(positions)[-length(positions)])
  testPairs <- closestPairs(mc, horizontal = T)
  
  endOfDebugging()
}
debugClosestPairsV <- function() {
  mc <- newMetaClusters()
  mc <- newMetaClusters()
  mc <- newMetaClusters()
  mc <- newMetaClusters()
  positions <- unlist(lapply(mc, "[[", "y"))
  plot(x = rep(0.5, length(mc)), y = positions, type="p", xlim=c(0,1), ylim=c(0,1))
  
  actualDist <- abs(sort(positions)[-1] - sort(positions)[-length(positions)])
  testPairs <- closestPairs(mc, horizontal = F)
  
  endOfDebugging()
}


# get pairs close enough for merge
mergeablePairs <- function(metaClusters, horizontal = TRUE) {
  closePairs <- matrix(nrow = 0, ncol = 2)
  
  # get relevant positions
  # need y-proximity to merge through horizontal movement and vice versa!
  positions <- unlist(lapply(metaClusters, "[[", if (horizontal) "y" else "x"))
  variances <- unlist(lapply(metaClusters, "[[", "variance"))
  
  # find all viable pairs
  for (i in seq_along(positions)) {
    one <- positions[i]
    # require distance of 1 sigma (distro goes up to 3 sigma, but we want the merge to be very visible)
    oneRadius <- variances[i]
    
    for (j in seq_along(positions)) {
      # don't merge with itself
      if (i == j) {
        next
      }
      
      other <- positions[j]
      # require distance of 1 sigma (distro goes up to 3 sigma, but we want the merge to be very visible)
      otherRadius <- variances[j]
      # check if close enough
      actualDistance <- abs(one - other)
      minDistance <- oneRadius + otherRadius
      if (actualDistance < minDistance) {
        # add to matching pairs
        # re-enable remainder of line to use distance to guide probabilities when selecting one
        closePairs <- rbind(closePairs, c(i,j)) #, actualDistance))
      }
    }
  }
  
  # convert distances to probabilities
  if (F) {
    # ensure > 0
    thirdCol <- pmax(closePairs[,3], 0.01)
    # normalize
    maxDist <- max(thirdCol)
    thirdCol <- thirdCol / maxDist
    # invert (closer => more probable)
    thirdCol <- 1- thirdCol + 0.5 # add something to lessen the probability of the closest
    # normalize to sum of 1
    sumDist <- sum(thirdCol)
    thirdCol <- thirdCol/sumDist
    # update values in matrix
    closePairs[,3] <- thirdCol
  }
  
  return(closePairs)
}

debugmergeablePairsH <- function() {
  mc <- newMetaClusters()
  mps <- mergeablePairs(mc, horizontal = T)
  endOfDebugging()
}
debugmergeablePairsV <- function() {
  mc <- newMetaClusters()
  mc <- newMetaClusters()
  mps <- mergeablePairs(mc, horizontal = F)
  endOfDebugging()
}





mirrorClamp <- function(x) {
  if (is.list(x)) {
    x$x <- mirrorClamp(x$x)
    x$y <- mirrorClamp(x$y)
  } else {
    x[x<0] <- -x[x<0]
    x[x>1] <- 1 - (x[x>1] - 1)
  }
  return(x)
}

fillClusters <- function(metaClusters, preserveX = NULL, preserveY = NULL) {
  # can't preserve both
  if (!is.null(preserveX) && !is.null(preserveY)) {
    stop("Can't preserve both fill coordinates, because there'd be no change at all.")
  }
  
  points <- list()

  # fill clusters
  for (i in seq_along(metaClusters)) {
    cluster <- metaClusters[[i]]

    # get random/preserved positions
    if (is.null(preserveX)) {
      x <- rnorm(config$clusterSize, cluster$x, cluster$variance)
    } else {
      x <- preserveX[[i]]$x
    }
    if (is.null(preserveY)) {
      y <- rnorm(config$clusterSize, cluster$y, cluster$variance)
    } else {
      y <- preserveY[[i]]$y
    }

    # mirror back, when points go outside
    x <- mirrorClamp(x)
    y <- mirrorClamp(y)

    points[[i]] <- list(x = x, y = y)
  }

  # add noise
  if (is.null(preserveX) || length(preserveX) <= length(metaClusters)) {
    x <- runif(config$noiseCount, min = 0, max = 1)
  } else {
    x <- preserveX[[length(points) + 1]]$x
  }
  if (is.null(preserveY) || length(preserveY) <= length(metaClusters)) {
    y <- runif(config$noiseCount, min = 0, max = 1)
  } else {
    y <- preserveY[[length(points) + 1]]$y
  }
  points[[length(points) + 1]] <- list(x = x, y = y)

  return(points)
}

getAllCoordinates <- function(filledClusters) {
  joinedX <- unlist(lapply(filledClusters, "[[", "x"))
  joinedY <- unlist(lapply(filledClusters, "[[", "y"))
  return(list(
    x = joinedX,
    y = joinedY
  ))
}

drawClusters <- function(filledClusters, name = NULL, highlightIdx = NA) {
  # initialize plot
  initPlot <- function(main, xlab, ylab) {
    plot(
      x = NULL,
      y = NULL,
      xlim = c(0, 1),
      ylim = c(0, 1),
      asp = 1,
      type = "p",
      pch = 19,
      main = main,
      xlab = xlab,
      ylab = ylab
    )
  }
  if (is.null(name)) {
    initPlot("", "filledClusters$x", "filledClusters$y")
  } else {
    initPlot(name, "", "")
  }
  for(i in 1:length(filledClusters)) {
    if (!is.na(highlightIdx) && i == highlightIdx) {
      dotCol <- "red"
    } else {
      dotCol <- "black"
    }
    points(filledClusters[[i]]$x, filledClusters[[i]]$y, pch = 19, col = dotCol)
  }
}



moveCluster <- function(filledCluster, xOffset = 0, yOffset = 0, subRange = NULL) {
  if (is.null(subRange)) {
    subRange <- seq_along(filledCluster$x)
  }

  # move points by offset
  filledCluster$x[subRange] <- filledCluster$x[subRange] + xOffset
  filledCluster$y[subRange] <- filledCluster$y[subRange] + yOffset

  # mirror points back into regular range
  filledCluster <- mirrorClamp(filledCluster)

  return(filledCluster)
}

mergeClusters <- function(metaClusters, filledClusters, fromIdx, toIdx) {
  fromCluster <- metaClusters[[fromIdx]]
  toCluster <- metaClusters[[toIdx]]
  fromPoints <- filledClusters[[fromIdx]]

  # get meta offset
  xOffset <- toCluster$x - fromCluster$x
  yOffset <- toCluster$y - fromCluster$y

  # move points by offset
  fromPoints <- moveCluster(fromPoints, xOffset, yOffset)

  filledClusters[[fromIdx]] <- fromPoints
  return(filledClusters)
}

splitCluster <- function(metaClusters, filledClusters, fromIdx, toIdx1, toIdx2) {
  fromCluster <- metaClusters[[fromIdx]]
  toCluster1 <- metaClusters[[toIdx1]]
  toCluster2 <- metaClusters[[toIdx2]]
  fromPoints <- filledClusters[[fromIdx]]

  # split in half
  half <- trunc(length(fromPoints$x) / 2)
  firstHalf <- 1:half
  secondHalf <- (half + 1):length(fromPoints$x)

  # move the first half to the first target
  xOffset <- toCluster1$x - fromCluster$x
  yOffset <- toCluster1$y - fromCluster$y
  fromPoints <- moveCluster(fromPoints, xOffset, yOffset, firstHalf)

  # move second half to second target
  xOffset <- toCluster2$x - fromCluster$x
  yOffset <- toCluster2$y - fromCluster$y
  fromPoints <- moveCluster(fromPoints, xOffset, yOffset, secondHalf)

  filledClusters[[fromIdx]] <- fromPoints
  return(filledClusters)
}



simple1DSplit <- function(metaClusters, splitIdx, horizontal = T, maxRetry = 20) {
  if (maxRetry < 1) {
    stop("Need at least one chance to find a simple split.")
  }
  
  for (firstPosRetry in 1:maxRetry) {
    simulation <- metaClusters
    
    # move first half to new position
    firstHalf <- simulation[[splitIdx]]
    firstPos <- runif(1, min = 0, max = 1)
    if (horizontal) {
      firstHalf$x <- firstPos
    } else {
      firstHalf$y <- firstPos
    }
    #firstHalf$variance <- config$minClusterVariance
    
    # check for collisions with new first half
    if (collisionTest(firstHalf, simulation[-splitIdx])) {
      next
    }
    # no collision => replace splitter with first half
    simulation[[splitIdx]] <- firstHalf
    
    # block area around first half to avoid overlap between both halves
    gapStart <- firstPos - firstHalf$variance * 3
    gapEnd <- firstPos + firstHalf$variance * 3
    # limit to normalized space
    gapStart <- max(0, gapStart)
    gapEnd <- min(gapEnd, 1)
    gapSize <- gapEnd - gapStart
    
    # move second half
    for (secondPosRetry in 1:maxRetry) {
      secondHalf <- firstHalf
      
      # find new position that is not inside gap from first half
      secondPos <- runif(1, min = 0, max = (1 - gapSize))
      if (secondPos > gapStart) {
        secondPos <- secondPos + gapSize
        # ensure rounding doesn't push it outside normalized space
        secondPos <- min(secondPos, 1)
      }
      if (horizontal) {
        secondHalf$x <- secondPos
      } else {
        secondHalf$y <- secondPos
      }
      
      # check if second half collides with existing clusters
      if (collisionTest(secondHalf, simulation)) {
        next
      }
      # no collision => found positions for splitting report results
      return(list(first=firstHalf, second=secondHalf))
    }
  }
  
  return(NULL)
}

applySimple1DSplit <- function(metaClusters, startFilledClusters, splitIdx, halves) {
  # check input
  if (is.null(halves)) {
    stop("Halves is null. Can't aplly simple 1D split without it.")
  }
  
  # find out whether this is a H/V split
  horizontal <- halves$first$y == halves$second$y
  
  # move split cluster to position of its first half
  if (horizontal) {
    metaClusters[[splitIdx]]$x <- halves$first$x
  } else {
    metaClusters[[splitIdx]]$y <- halves$first$y
  }
  
  # generate data
  if (horizontal) {
    newData <- fillClusters(metaClusters, preserveY = startFilledClusters)
  } else {
    newData <- fillClusters(metaClusters, preserveX = startFilledClusters)
  }
  #drawClusters(startFilledClusters, "start data")
  #drawClusters(newData, "new data")
  
  # move second half of split cluster to new position
  if (horizontal) {
    offset <- halves$second$x - halves$first$x
  } else {
    offset <- halves$second$y - halves$first$y
  }
  splitter <- newData[[splitIdx]]
  splitterSize <- length(splitter$x)
  if (horizontal) {
    splitter <- moveCluster(
      filledCluster = splitter,
      xOffset = offset,
      subRange = (ceiling(splitterSize/2):splitterSize)
    )
  } else {
    splitter <- moveCluster(
      filledCluster = splitter,
      yOffset = offset,
      subRange = (ceiling(splitterSize/2):splitterSize)
    )
  }
  newData[[splitIdx]] <- splitter
  #drawClusters(newData, "new data (after split)")
  
  return(list(meta = metaClusters, filled = newData))
}

debugSimple1DSplit <- function() {
  mc <- newMetaClusters()
  fc <- fillClusters(mc)
  drawClusters(fc)
  
  #### Horizontal ####
  horizontal <- TRUE
  
  halves1 <- simple1DSplit(metaClusters = mc, splitIdx = 1, horizontal = horizontal)
  stopifnot(is.null(halves1))
  #clstrs1 <- applySimple1DSplit(metaClusters = mc, startFilledClusters = fc, splitIdx = 1, halves = halves1)
  
  halves2 <- simple1DSplit(metaClusters = mc, splitIdx = 2, horizontal = horizontal)
  clstrs2 <- applySimple1DSplit(metaClusters = mc, startFilledClusters = fc, splitIdx = 2, halves = halves2)
  
  halves3 <- simple1DSplit(metaClusters = mc, splitIdx = 3, horizontal = horizontal)
  clstrs3 <- applySimple1DSplit(metaClusters = mc, startFilledClusters = fc, splitIdx = 3, halves = halves3)
  
  halves4 <- simple1DSplit(metaClusters = mc, splitIdx = 4, horizontal = horizontal)
  clstrs4 <- applySimple1DSplit(metaClusters = mc, startFilledClusters = fc, splitIdx = 4, halves = halves4)
  
  #### Vertical ####
  horizontal <- FALSE
  
  halves1 <- simple1DSplit(metaClusters = mc, splitIdx = 1, horizontal = horizontal)
  clstrs1 <- applySimple1DSplit(metaClusters = mc, startFilledClusters = fc, splitIdx = 1, halves = halves1)
  
  halves2 <- simple1DSplit(metaClusters = mc, splitIdx = 2, horizontal = horizontal)
  stopifnot(is.null(halves2))
  #clstrs2 <- applySimple1DSplit(metaClusters = mc, startFilledClusters = fc, splitIdx = 2, halves = halves2)
  
  halves3 <- simple1DSplit(metaClusters = mc, splitIdx = 3, horizontal = horizontal)
  clstrs3 <- applySimple1DSplit(metaClusters = mc, startFilledClusters = fc, splitIdx = 3, halves = halves3)
  
  halves4 <- simple1DSplit(metaClusters = mc, splitIdx = 4, horizontal = horizontal)
  clstrs4 <- applySimple1DSplit(metaClusters = mc, startFilledClusters = fc, splitIdx = 4, halves = halves4)
  
  endOfDebugging()
}


simple1DMerge <- function(metaClusters, mergeIdx, partnerIdxs, horizontal = T, maxSplitRetry = 20) {
  for (partnerIdx in partnerIdxs) {
    simulation <- metaClusters
    
    # perform merge
    if (horizontal) {
      simulation[[mergeIdx]]$x <- simulation[[partnerIdx]]$x
    } else {
      simulation[[mergeIdx]]$y <- simulation[[partnerIdx]]$y
    }
    
    # split other cluster to preserve number of clusters
    splitIdxs = setdiff(seq_along(simulation), c(mergeIdx, partnerIdx))
    for (splitIdx in splitIdxs) {
      # try splitting other cluster
      halves <- simple1DSplit(simulation, splitIdx, horizontal = horizontal, maxRetry = maxSplitRetry)
      
      # check if it can be split
      if (is.null(halves)) {
        # try next possible split partner
        next
      }
      
      # split worked => we are done with the merge!
      return(list(
        partnerIdx = partnerIdx,
        splitIdx = splitIdx,
        halves = halves
      ))
    }
  }
  
  return(NULL)
}

get1DMergedSplitClusters <- function(maxRetry = 20) {
  if (maxRetry < 1) {
    stop("Need at least one chance to find a merge.")
  }
  
  horizontalMeta <- NULL
  verticalMeta <- NULL
  horizontal <- NULL
  vertical <- NULL
  mergeIdx <- NA
  for (retryStart in 1:maxRetry) {
    # start view
    startMeta <- newMetaClusters()
    for (retryEnd in 1:maxRetry) {
      # end views
      horizontalMeta <- newMetaClusters(preserveY = startMeta)
      verticalMeta <- newMetaClusters(preserveX = startMeta)
      
      # get mergeable clusters
      mergeableH <- mergeablePairs(horizontalMeta, horizontal = TRUE)
      # check if we have at least one mergeable pair
      if (nrow(mergeableH) < 1) {
        #message("Not mergeable in H.")
        next
      }
      mergeableV <- mergeablePairs(verticalMeta, horizontal = FALSE)
      # check if we have at least one mergeable pair
      if (nrow(mergeableV) < 1) {
        #message("Not mergeable in V.")
        next
      }
      
      # check if we have clusters that are mergeable in both directions
      mainCandidateIdxs <- intersect(mergeableH[,1], mergeableV[,1])
      if (length(mainCandidateIdxs) < 1) {
        #message("Not mergeable in H AND V.")
        next
      }
      
      # try with every candidate cluster
      for (candidateIdx in mainCandidateIdxs) {
        horizontal <- NULL
        vertical <- NULL
        # try horizontal merge (includes split to keep number of visible clusters)
        partners <- mergeableH[candidateIdx == mergeableH[,1],2]
        partners <- setdiff(partners, candidateIdx)
        horizontal <- simple1DMerge(
          metaClusters = horizontalMeta,
          mergeIdx = candidateIdx,
          partnerIdxs = partners,
          horizontal = TRUE,
          maxSplitRetry = maxRetry
        )
        if (is.null(horizontal)) {
          # couldn't find a horizontal merge => try next candidate
          #message("Not splittable after merge in H.")
          next
        }
        
        # try vertical merge (includes split to keep number of visible clusters)
        partners <- mergeableV[candidateIdx == mergeableV[,1],2]
        partners <- setdiff(partners, candidateIdx)
        vertical <- simple1DMerge(
          metaClusters = verticalMeta,
          mergeIdx = candidateIdx,
          partnerIdxs = partners,
          horizontal = FALSE,
          maxSplitRetry = maxRetry
        )
        if (is.null(vertical)) {
          # couldn't find a vertical merge => try next candidate
          #message("Not splittable after merge in V.")
          next
        }
        
        mergeIdx <- candidateIdx
        break
      }
      
      # check if we found a candidate that can merge horizontally and vertically
      if (!is.na(mergeIdx)) {
        break
      }
    }
    
    # check whether we got the necessary results
    if (!is.na(mergeIdx)) {
      break
    }
  }
  
  # check whether we got the necessary results
  if (is.na(mergeIdx)) {
    stop("Couldn't generate 1D mergeable clusters. Too many retrys.")
  }
  
  #cat("start:", retryStart, "retrys", "\nend:", retryEnd, "retrys\n")
  
  # generate points for start clusters
  startData <- fillClusters(startMeta)
  
  # apply changes to H/V
  
  # move merged clusters to their final positions
  horizontalMeta[[mergeIdx]]$x <- horizontalMeta[[horizontal$partnerIdx]]$x
  verticalMeta[[mergeIdx]]$y <- verticalMeta[[vertical$partnerIdx]]$y
  
  # generate data and apply split
  horizontalClusters <- applySimple1DSplit(
    metaClusters = horizontalMeta,
    startFilledClusters = startData,
    splitIdx = horizontal$splitIdx,
    halves = horizontal$halves
  )
  horizontalMeta <- horizontalClusters$meta
  horizontalData <- horizontalClusters$filled
  
  verticalClusters <- applySimple1DSplit(
    metaClusters = verticalMeta,
    startFilledClusters = startData,
    splitIdx = vertical$splitIdx,
    halves = vertical$halves
  )
  verticalMeta <- verticalClusters$meta
  verticalData <- verticalClusters$filled
  
  # find clusters that are not involved in merge/split
  horizontalStayIdxs <- setdiff(
    seq_along(startMeta),
    c(mergeIdx, horizontal$partnerIdx, horizontal$splitIdx)
  )
  verticalStayIdxs <- setdiff(
    seq_along(startMeta),
    c(mergeIdx, vertical$partnerIdx, vertical$splitIdx)
  )
  
  # return resulting data and info
  return(list(
    startMeta = startMeta,
    startData = startData,
    mergeFromIdx = mergeIdx,
    stayIdxs = intersect(horizontalStayIdxs, verticalStayIdxs),
    horizontal = list(
      data = horizontalData,
      mergeToIdx = horizontal$partnerIdx,
      splitIdx = horizontal$splitIdx,
      stayIdxs = horizontalStayIdxs
    ),
    vertical = list(
      data = verticalData,
      mergeToIdx = vertical$partnerIdx,
      splitIdx = vertical$splitIdx,
      stayIdxs = verticalStayIdxs
    )
  ))
}

debugGet1DMergedSplitClusters <- function() {
  res <- get1DMergedSplitClusters()
  drawClusters(res$startData, name = "start data", highlightIdx = res$mergeFromIdx)
  drawClusters(res$horizontal$data, name = "horizontal data", highlightIdx = res$mergeFromIdx)
  drawClusters(res$vertical$data, name = "vertical data", highlightIdx = res$mergeFromIdx)

  endOfDebugging()
}
#debugGet1DMergedSplitClusters()


actions <- list(stay = "stay", merge = "merge", split = "split")

dims <- list(hor = "hor", ver = "ver", both = "both")


simple2DSplit <- function(metaClusters, splitIdx, maxRetry = 20) {
  if (maxRetry < 1) {
    stop("Need at least one chance to find a simple 2D split.")
  }
  
  splitter <- metaClusters[[splitIdx]]
  for (firstPosRetry in 1:maxRetry) {
    # find new position for second half
    secondHalf <- splitter
    secondHalf$x <- runif(1, min = 0, max = 1)
    secondHalf$y <- runif(1, min = 0, max = 1)
    
    # check if second half collides with existing clusters
    if (collisionTest(secondHalf, metaClusters)) {
      next
    }
    # no collision => found positions for splitting report results
    return(secondHalf)
  }
  
  return(NULL)
}

get2DActionClusters <- function(maxRetry = 20) {
  if (maxRetry < 1) {
    stop("Need at least one chance to find action clusters.")
  }
  
  for (retry in 1:maxRetry) {
    # get a start and and end view
    startMeta <- newMetaClusters()
    endMeta <- newMetaClusters()
    
    # ensure we have at least 4 clusters
    if (length(startMeta) < 4) {
      stop("Need at least 4 clusters for 2D actions.")
    }
    
    # let the 1st cluster stay
    stayIdx <- 1
    
    # make the 2nd cluster merge with the 3rd
    mergeFromIdx <- 2
    mergeToIdx <- 3
    endMeta[[mergeFromIdx]]$x <- endMeta[[mergeToIdx]]$x
    endMeta[[mergeFromIdx]]$y <- endMeta[[mergeToIdx]]$y
    
    # make the 4th cluster split into two halves
    splitIdx <- 4
    secondHalf <- simple2DSplit(
      metaClusters = endMeta,
      splitIdx = splitIdx,
      maxRetry = maxRetry)
    if (is.null(secondHalf)) {
      next
    }
    
    # now we know this combination of clusters is a winner!
    
    # generate data for the clusters
    startData <- fillClusters(startMeta)
    endData <- fillClusters(endMeta)
    
    # move second half of the data to its new position
    splitter <- endMeta[[splitIdx]]
    xOffset <- secondHalf$x - splitter$x
    yOffset <- secondHalf$y - splitter$y
    
    splitData <- endData[[splitIdx]]
    splitterSize <- length(splitData$x)
    secondHalfStart <- trunc(splitterSize / 2) + 1
    
    endData[[splitIdx]] <- moveCluster(
      splitData,
      xOffset = xOffset,
      yOffset = yOffset,
      subRange = (secondHalfStart:splitterSize)
    )
    
    # return results
    return(list(
      startData = startData,
      endData = endData,
      stayIdx = stayIdx,
      mergeFromIdx = mergeFromIdx,
      mergeToIdx = mergeToIdx,
      splitIdx = splitIdx
    ))
  }
  
  return(NULL)
}

randomAction <- function() {
  randomIdx <- sample(length(actions), 1)
  action <- actions[[randomIdx]]
  return(action)
}

apply2DAction <- function(metaClusters, filledClusters, action) {
  if (action == actions$merge) {
    filledClusters <- mergeClusters(metaClusters, filledClusters, 1, 3)
  } else if (action == actions$split) {
    filledClusters <- splitCluster(metaClusters, filledClusters, 1, 3, 4)
  }
  
  return(filledClusters)
}
apply2DAction <- function(metaClusters, filledClusters, action) {
  if (action == actions$merge) {
    filledClusters <- mergeClusters(metaClusters, filledClusters, 2, 3)
  } else if (action == actions$split) {
    filledClusters <- splitCluster(metaClusters, filledClusters, 2, 3, 4)
  }
  
  return(filledClusters)
}

applyRandom2DAction <- function(metaClusters, filledClusters) {
  action <- randomAction()
  return(list(
    action = action,
    filledClusters = apply2DAction(metaClusters, filledClusters, action)
  ))
}
applyRandom2DDistraction <- function(metaClusters, filledClusters) {
  distraction <- randomAction()
  return(list(
      action = distraction,
      filledClusters = apply2DAction(metaClusters, filledClusters, distraction)
  ))
}

generateClassicStays <- function(howMany) {
  # initialize data frame
  allData <- data.frame(matrix(ncol = 0, nrow = config$pointCount))
  
  myColName <- function(...) {
    return(paste(..., sep="_"))
  }
  addCoords <- function(filledClusters, iterCounter, ...) {
    coords <- getAllCoordinates(filledClusters)
    xName <- myColName(actions$stay, iterCounter, ..., "x")
    yName <- myColName(actions$stay, iterCounter, ..., "y")
    allData[xName] <<- coords$x
    allData[yName] <<- coords$y
  }
  
  # generate data for each staying cluster
  for (a in 1:howMany) {
    # first view
    m1 <- newMetaClusters()
    f1 <- fillClusters(m1)
    addCoords(f1, a)
    
    # intermediate view
    m2 <- newMetaClusters()
    f2 <- fillClusters(m2)
    intermediateAction <- applyRandom2DAction(m2, f2)
    f2 <- intermediateAction$filledClusters
    distraction1 <- applyRandom2DDistraction(m2, f2)
    f2 <- distraction1$filledClusters
    addCoords(f2, a, intermediateAction$action, "i", distraction1$action, 1)
    
    # last view
    m3 <- newMetaClusters()
    f3 <- fillClusters(m3)
    distraction2 <- applyRandom2DDistraction(m3, f3)
    f3 <- distraction2$filledClusters
    addCoords(f3, a, distraction2$action, 2)
  }
  
  return(allData)
}


myColName <- function(...) {
  return(paste(..., sep="_"))
}

addCoords <- function(jointDF, filledClusters, ..., x = T, y = T) {
  coords <- getAllCoordinates(filledClusters)
  if (x) {
    xName <- myColName(..., "x")
    jointDF[xName] <- coords$x
  }
  if (y) {
    yName <- myColName(..., "y")
    jointDF[yName] <- coords$y
  }
  return(jointDF)
}

swapClusters <- function(filledClusters, fromIdx, toIdx) {
  tmp <- filledClusters[[toIdx]]
  filledClusters[[toIdx]] <- filledClusters[[fromIdx]]
  filledClusters[[fromIdx]] <- tmp
  return(filledClusters)
}

generateStudyData <- function(repetitions) {
  # initialize data frame
  allData <- data.frame(matrix(ncol = 0, nrow = config$pointCount))
  
  # some common functions for use in the loop
  cluster1DToIdx1 <- function(oneDResult, clusterIdx) {
    if (clusterIdx == 1) {
      return(oneDResult)
    }
    # start data
    oneDResult$startData <- swapClusters(oneDResult$startData, clusterIdx, 1)
    # horizontal data
    oneDResult$horizontal$data <- swapClusters(oneDResult$horizontal$data, clusterIdx, 1)
    # vertical data
    oneDResult$vertical$data <- swapClusters(oneDResult$vertical$data, clusterIdx, 1)
    return(oneDResult)
  }
  addOneDData <- function(oneDResult, idx, name, dataSetCount) {
    oneDResult <- cluster1DToIdx1(oneDResult, idx)
    allData <<- addCoords(jointDF = allData, filledClusters = oneDResult$startData, dataSetCount, name, "start")
    allData <<- addCoords(jointDF = allData, filledClusters = oneDResult$horizontal$data, dataSetCount, name, dims$hor, y = F)
    allData <<- addCoords(jointDF = allData, filledClusters = oneDResult$vertical$data, dataSetCount, name, dims$ver, x = F)
    # debug info
    #drawClusters(oneDResult$startData, name=paste(name, dataSetCount, "Start"), highlightIdx = 1)
    #drawClusters(oneDResult$horizontal$data, name=paste(name, dataSetCount, "Horizontal"), highlightIdx = 1)
    #drawClusters(oneDResult$vertical$data, name=paste(name, dataSetCount, "Vertical"), highlightIdx = 1)
  }
  cluster2DToIdx1 <- function(twoDResult, clusterIdx) {
    if (clusterIdx == 1) {
      return(twoDResult)
    }
    # start data
    twoDResult$startData <- swapClusters(twoDResult$startData, clusterIdx, 1)
    # end data
    twoDResult$endData <- swapClusters(twoDResult$endData, clusterIdx, 1)
    return(twoDResult)
  }
  addTwoDData <- function(twoDResult, idx, name, dataSetCount) {
    twoDResult <- cluster2DToIdx1(twoDResult, idx)
    allData <<- addCoords(jointDF = allData, filledClusters = twoDResult$startData, dataSetCount, name, "start")
    allData <<- addCoords(jointDF = allData, filledClusters = twoDResult$endData, dataSetCount, name, dims$both)
    # debug info
    #drawClusters(twoDResult$startData, name=paste(name, dataSetCount, "Start"), highlightIdx = 1)
    #drawClusters(twoDResult$endData, name=paste(name, dataSetCount, "End"), highlightIdx = 1)
  }
  
  # how many data sets (each used for stay&merge&split) we already produced
  dataSetCount <- 0
  
  # generate 1D data
  for (ignore in 1:repetitions) {
    dataSetCount <- dataSetCount + 1
    
    #### get 1D action data ####
    oneD <- NULL
    oneDIterations <- 0
    while(is.null(oneD)) {
      oneDIterations <- oneDIterations + 1
      if (oneDIterations %% 10 == 0) {
        cat(
          "Still searching for fitting 1D change data (",
          oneDIterations, " iterations).\n", sep = ""
        )
      }
      tryCatch(
        {
          oneD <- get1DMergedSplitClusters()
          
          # check results
          if (is.null(oneD)) {
            message("oneD ", oneDIterations, " was NULL.")
          } else {
            #drawClusters(oneD$startData, name=paste("oneD", oneDIterations, "Start"))
            #drawClusters(oneD$horizontal$data, name=paste("oneD", oneDIterations, "Horizontal"))
            #drawClusters(oneD$vertical$data, name=paste("oneD", oneDIterations, "Vertical"))
            
            if (length(oneD$stayIdxs) < 1) {
              # use only cases where there is a common cluster that stays unchanged
              message("oneD ", oneDIterations, " has different stay indices.")
              oneD <- NULL
            } else if (oneD$horizontal$splitIdx != oneD$vertical$splitIdx) {
              # use only cases where there is a common cluster that splits
              message("oneD ", oneDIterations, " has different split indices.")
              oneD <- NULL
            }
          } 
        },
        error = function(e) {
          oneD <- NULL
        }
      )
    }
    cat("Found fitting 1D change data after", oneDIterations, "iterations.\n")
    
    #### apply 1D actions ####
    # add stay data
    addOneDData(
      oneDResult = oneD,
      idx = oneD$stayIdxs[1], # ensured earlier: at least 1 & same idx in both h/v
      name = actions$stay,
      dataSetCount = dataSetCount
    )
    # add merge data
    addOneDData(
      oneDResult = oneD,
      idx = oneD$mergeFromIdx,
      name = actions$merge,
      dataSetCount = dataSetCount
    )
    # add split data
    addOneDData(
      oneDResult = oneD,
      idx = oneD$horizontal$splitIdx, # ensured earlier: idx equal in both h/v
      name = actions$split,
      dataSetCount = dataSetCount
    )
  }
  
  # generate 2D data
  # double the amount because some transitions won't differentiate H/V
  for (ignore in 1:(repetitions*2)) {
    dataSetCount <- dataSetCount + 1
    
    #### get 2D action data ####
    twoD <- NULL
    twoDIterations <- 0
    while(is.null(twoD)) {
      twoDIterations <- twoDIterations + 1
      if (twoDIterations %% 10 == 0) {
        cat(
          "Still searching for fitting 2D change data (",
          twoDIterations, " iterations).\n", sep = ""
        )
      }
      tryCatch(
        {
          twoD <- get2DActionClusters()
          
          # check results
          if (is.null(twoD)) {
            message("twoD ", twoDIterations, " was NULL.")
          } else {
            #drawClusters(twoD$startData, name=paste("twoD", twoDIterations, "Start"))
            #drawClusters(twoD$endData, name=paste("twoD", twoDIterations, "End"))
          }
        },
        error = function() {
          twoD <- NULL
        }
      )
    }
    cat("Found fitting 2D change data after", twoDIterations, "iterations.\n")
    
    #### apply 2D actions ####
    # add stay data
    addTwoDData(
      twoDResult = twoD,
      idx = twoD$stayIdx,
      name = actions$stay,
      dataSetCount = dataSetCount
    )
    # add merge data
    addTwoDData(
      twoDResult = twoD,
      idx = twoD$mergeFromIdx,
      name = actions$merge,
      dataSetCount = dataSetCount
    )
    # add split data
    addTwoDData(
      twoDResult = twoD,
      idx = twoD$splitIdx,
      name = actions$split,
      dataSetCount = dataSetCount
    )
  }
  
  return(allData)
}

strContains <- function(text, pattern) {
  return(grepl(x = text, pattern = pattern, fixed = TRUE))
}

drawStudyData <- function(allData) {
  # check column count
  colCount <- ncol(allData)
  pairSize <- 4
  if ((colCount %% pairSize) != 0) {
    stop("The columns in drawable data need to come in pairs of 4 (2 views with x/y each)!")
  }
  
  # check task count
  taskCount <- colCount %/% pairSize
  if (taskCount < 1) {
    return()
  }
  
  myDraw <- function(x, y, main, sub) {
    plot(
      x = x[(config$clusterSize+1):length(x)],
      y = y[(config$clusterSize+1):length(y)],
      xlim = c(0, 1),
      ylim = c(0, 1),
      asp = 1,
      type = "p",
      pch = 19,
      main = main,
      sub = sub,
      xlab = "",
      ylab = ""
    )
    points(x[1:config$clusterSize], y[1:config$clusterSize], pch=19, col="red")
  }
  
  # create the drawings
  for (t in 0:(taskCount-1)) {
    mainTitle <- paste("Task", t+1)
    
    # initial view
    myDraw(
      x = allData[,t*pairSize+1],
      y = allData[,t*pairSize+2],
      main = mainTitle,
      sub = "Initial view"
    )
    
    xName <- colnames(allData)[t*pairSize + 3]
    isTwoDim <- strContains(xName, dims$both)
    
    if (isTwoDim) {
      # plots when two dimensions change
      myDraw(
        x = allData[,t*pairSize+3],
        y = allData[,t*pairSize+2],
        main = mainTitle,
        sub = "TwoDim - Horizontal view"
      )
      myDraw(
        x = allData[,t*pairSize+1],
        y = allData[,t*pairSize+4],
        main = mainTitle,
        sub = "TwoDim - Vertical view"
      )
      myDraw(
        x = allData[,t*pairSize+3],
        y = allData[,t*pairSize+4],
        main = mainTitle,
        sub = "TwoDim - Final view"
      )
    } else {
      # plots when only one dimension changes
      myDraw(
        x = allData[,t*pairSize+3],
        y = allData[,t*pairSize+2],
        main = mainTitle,
        sub = "OneDim - Horizontal view"
      )
      myDraw(
        x = allData[,t*pairSize+1],
        y = allData[,t*pairSize+4],
        main = mainTitle,
        sub = "OneDim - Vertical view"
      )
    }
  }
}

createProtocol <- function(taskName, targetDir, experiments1D, experiments2D, isTraining) {
  # compose output file name (without extension)
  filePath <- paste(targetDir, taskName, sep="/")
  
  # create private JSON
  {
    # convert experiments to JSON
    rawJson1D <- toJSON(experiments1D, indent = 2)
    rawJson2D <- toJSON(experiments2D, indent = 2)
    
    # compose simpler JSON file
    simpleJson <- paste(
      "{\n",
      "  \"TaskName\":\"", taskName, "\",\n",
      "  \"Experiments1D\": ", rawJson1D, ",\n",
      "  \"Experiments2D\": ", rawJson2D, "\n",
      "}\n",
      sep=""
    )
    
    # write JSON to file
    cat(simpleJson, file = paste(filePath, ".json", sep = ""))
  }
  
  # create public JS
  {
    # remove info about correct result from public protocol (except for training)
    if (!isTraining) {
      removeActual <- function(experiment) {
        experiment$actual <- NULL
        return(experiment)
      }
      experiments1D <- lapply(experiments1D, removeActual)
      experiments1D <- lapply(experiments1D, removeActual)
    }
    
    # convert experiments to JSON
    rawJson1D <- toJSON(experiments1D, indent = 2)
    rawJson2D <- toJSON(experiments2D, indent = 2)
    
    # replace references to named variables in JSON
    replaceReference <- function(json, variableName) {
      return(gsub(
        x = json,
        pattern = paste("\"", variableName, "\"", sep = ""),
        replacement = variableName,
        fixed = TRUE
      ))
    }
    json1D <- replaceReference(rawJson1D, pointIndices)
    json2D <- replaceReference(rawJson2D, pointIndices)
    
    # add JSON indentation to match remainder of JS file
    addIndentation <- function(json, indentation) {
      return(gsub(
        x = json,
        pattern = "\n",
        replacement = paste("\n", indentation, sep = ""),
        fixed = TRUE
      ))
    }
    json1D <- addIndentation(json1D, "      ")
    json2D <- addIndentation(json2D, "      ")
    
    # compose JS file
    js <- paste(
      "const ", pointIndices," = [...Array(", config$clusterSize, ").keys()]\n",
      "const ", taskName, " = {\n",
      "  Experiments1D: ", json1D, ",\n",
      "  Experiments2D: ", json2D, ",\n",
      "};\n",
      "\n",
      "export default ", taskName, ";\n",
      sep=""
    )
    
    # write JS to file
    cat(js, file = paste(filePath, ".js", sep = ""))
  }
}

pointIndices <- "pointIndices"
createStudyProtocol <- function(allData, taskName, datasetName, targetDir, isTraining) {
  # check column count
  colCount <- ncol(allData)
  pairSize <- 4
  if ((colCount %% pairSize) != 0) {
    stop("The columns in drawable data need to come in pairs of 4 (2 views with x/y each)!")
  }
  
  experiments1D <- list()
  experiments2D <- list()
  
  # export all 1D experiments first
  # check dataset count
  dataSetCount <- colCount %/% pairSize
  if (dataSetCount > 1) {
    # export all 1D experiments first
    for (t in 0:(dataSetCount-1)) {
      endNameX <- colnames(allData)[t*pairSize + 3]
      isTwoDim <- strContains(endNameX, dims$both)
      
      # get cluster action
      if (strContains(endNameX, actions$stay)) {
        action <- actions$stay
      } else if (strContains(endNameX, actions$merge)) {
        action <- actions$merge
      } else if (strContains(endNameX, actions$split)) {
        action <- actions$split
      } else {
        stop("Cluster column represents unknown action.")
      }
      
      if (!isTwoDim) {
        # experiments on 1D data sets
        
        # horizontal only
        experiments1D[[length(experiments1D) + 1]] <- list(
          datasetName = datasetName,
          datapointIds = pointIndices,
          horizontal = TRUE,
          dims = list(
            list(x = (t*pairSize + 0), y = (t*pairSize + 1)), # use 0-based index for JS
            list(x = (t*pairSize + 2), y = (t*pairSize + 1)) # use 0-based index for JS
          ),
          actual = action
        )
        # vertical only
        experiments1D[[length(experiments1D) + 1]] <- list(
          datasetName = datasetName,
          datapointIds = pointIndices,
          horizontal = FALSE,
          dims = list(
            list(x = (t*pairSize + 0), y = (t*pairSize + 1)), # use 0-based index for JS
            list(x = (t*pairSize + 0), y = (t*pairSize + 3)) # use 0-based index for JS
          ),
          actual = action
        )
      } else {
        # experiments on 2D data sets
        
        # for rotation, there might be an influence on what rotation comes first.
        # we need to do each data set twice with different order of rations.
        # once for (H then V) and once for (V then H).
        
        # but spline transitions are always the same. limesurvey-generator must
        # filter to only create questions for odd/even experiments when
        # using splines for 2D data sets.
        
        # horizontal first, vertical second
        experiments2D[[length(experiments2D) + 1]] <- list(
          datasetName = datasetName,
          datapointIds = pointIndices,
          horizontal = TRUE,
          directDims = list(
            list(x = (t*pairSize + 0), y = (t*pairSize + 1)), # use 0-based index for JS
            list(x = (t*pairSize + 2), y = (t*pairSize + 3)) # use 0-based index for JS
          ),
          commonDims = list(
            list(x = (t*pairSize + 0), y = (t*pairSize + 1)), # use 0-based index for JS
            list(x = (t*pairSize + 2), y = (t*pairSize + 1)), # use 0-based index for JS
            list(x = (t*pairSize + 2), y = (t*pairSize + 3)) # use 0-based index for JS
          ),
          actual = action
        )
        # vertical first, horizontal second
        experiments2D[[length(experiments2D) + 1]] <- list(
          datasetName = datasetName,
          datapointIds = pointIndices,
          horizontal = FALSE,
          directDims = list(
            list(x = (t*pairSize + 0), y = (t*pairSize + 1)), # use 0-based index for JS
            list(x = (t*pairSize + 2), y = (t*pairSize + 3)) # use 0-based index for JS
          ),
          commonDims = list(
            list(x = (t*pairSize + 0), y = (t*pairSize + 1)), # use 0-based index for JS
            list(x = (t*pairSize + 0), y = (t*pairSize + 3)), # use 0-based index for JS
            list(x = (t*pairSize + 2), y = (t*pairSize + 3)) # use 0-based index for JS
          ),
          actual = action
        )
      }
    }
  }
  
  # write experiment to files
  createProtocol(
    taskName = taskName,
    targetDir = targetDir,
    experiments1D = experiments1D,
    experiments2D = experiments2D,
    isTraining = isTraining)
}


newBotCluster <- function(margin, variance = config$minClusterVariance, cornersOnly = F) {
  # choose a position for the bot test cluster
  if (cornersOnly) {
    position <- sample(c(margin/2, 1-margin/2), 2, replace = TRUE) 
  } else {
    position <- runif(2, min = 0, max = (margin * 2))
    if (position[1] > margin) {
      position[1] <- position[1] + (1 - (margin * 2))
    }
    if (position[2] > margin) {
      position[2] <- position[2] + (1 - (margin * 2))
    }  
  }
  
  return(list(
    x = position[1],
    y = position[2],
    variance = variance))
}

remainingRange <- function(position, margin) {
  if (position > 0.5) {
    return(c(0, 1 - margin))
  } else {
    return(c(margin, 1))
  }
}

partnerRange <- function(mainCluster) {
  partnerRange <- c(7, 10) * mainCluster$variance
  if (mainCluster$x > 0.5) {
    horPartnerRange <- rev(mainCluster$x - partnerRange)
  } else {
    horPartnerRange <- mainCluster$x + partnerRange
  }
  if (mainCluster$y > 0.5) {
    verPartnerRange <- rev(mainCluster$y - partnerRange)
  } else {
    verPartnerRange <- mainCluster$y + partnerRange
  }
  
  return(list(
    x = horPartnerRange,
    y = verPartnerRange
  ))
}

get1DBotStay <- function() {
  # create H/V stay
  
  # keep main cluster to the outer edge (preserve center for distractors)
  margin <- 3 * config$maxClusterVariance
  
  # choose a position for the main cluster
  mainCluster <- newBotCluster(margin = margin, variance = config$minClusterVariance)
  
  # calculate remaining space for the other clusters
  # (we only need to keep one margin, not on both edges fo the plot)
  remainingX <- remainingRange(mainCluster$x, margin)
  remainingY <- remainingRange(mainCluster$y, margin)
  
  # get remaining clusters (keep used margin free)
  getRemainingMetaClusters <- function(mainCluster, preserveX = NULL, preserveY = NULL) {
    # remove main cluster from preservation lists
    if (!is.null(preserveX)) {
      preserveX <- preserveX[-1]
    }
    if (!is.null(preserveY)) {
      preserveY <- preserveY[-1]
    }
    
    # find positions for remaining clusters
    remainingMeta <- NULL
    while(is.null(remainingMeta)) {
      remainingMeta <- newMetaClusters(
        howMany = (config$clusterCount - 1),
        xlim = remainingX,
        ylim = remainingY,
        preserveX = preserveX,
        preserveY = preserveY
      )
      if (collisionTest(mainCluster, remainingMeta)) {
        remainingMeta <- NULL
      }
    }
    # join with existing main cluster
    metaClusters <- c(list(mainCluster), remainingMeta)
    #drawMetaClusters(metaClusters)
    return(metaClusters)
  }
  startMeta <- getRemainingMetaClusters(mainCluster)
  horMeta <- getRemainingMetaClusters(mainCluster, preserveY = startMeta)
  verMeta <- getRemainingMetaClusters(mainCluster, preserveX = startMeta)
  
  # generate data points
  startData <- fillClusters(startMeta)
  horData <- fillClusters(horMeta, preserveY = startData)
  horData[[1]] <- startData[[1]]
  verData <- fillClusters(verMeta, preserveX = startData)
  verData[[1]] <- startData[[1]]
  
  if (F) {
    drawClusters(startData, highlightIdx = 1)
    drawClusters(horData, highlightIdx = 1)
    drawClusters(verData, highlightIdx = 1)
  }
  
  return(list(
    startData = startData,
    horizontalData = horData,
    verticalData = verData
  ))
}

get1DBotMerge <- function() {
  # create H/V merge
  
  # keep main cluster to the outer edge (preserve center for distractors)
  margin <- 3 * config$maxClusterVariance
  
  # choose a position for the main cluster that will merge
  # (keep it on a corner to be able to merge in both directions)
  mergeCluster <- newBotCluster(
    margin = margin,
    variance = config$minClusterVariance,
    cornersOnly = TRUE)
  
  # get merge partner positions within a range of distances
  partnerRange <- partnerRange(mergeCluster)
  
  horPartner <- list(
    x = runif(1, min = partnerRange$x[1], max = partnerRange$x[2]),
    y = mergeCluster$y,
    variance = mergeCluster$variance
  )
  verPartner <- list(
    x = mergeCluster$x,
    y = runif(1, min = partnerRange$y[1], max = partnerRange$y[2]),
    variance = mergeCluster$variance
  )
  clustersForMerge = list(mergeCluster, horPartner, verPartner)
  
  # place the remaining clusters diagonally
  #remainingClusterCount <- config$clusterCount - length(mergeClusters)
  #diagonalOffset <- sample(c(1,-1), 1) / remainingClusterCount
  #diagonalStart <- if (diagonalOffset > 0)  else
  #remainingClusters <- list()
  #if (remainingClusterCount >= 1) {
  #  for (i in 1:remainingClusterCount) {
  #    if (dia)
  #  }
  #}
  
  # calculate remaining space for the other clusters
  remainingX <- remainingRange(mergeCluster$x, margin)
  remainingY <- remainingRange(mergeCluster$y, margin)
  
  # get remaining clusters (keep used margins free)
  getRemainingMetaClusters <- function(existingClusters, preserveX = NULL, preserveY = NULL) {
    # find positions for remaining clusters
    remainingMeta <- NULL
    while(is.null(remainingMeta)) {
      remainingMeta <- newMetaClusters(
        howMany = (config$clusterCount - length(existingClusters)),
        xlim = remainingX,
        ylim = remainingY,
        preserveX = preserveX,
        preserveY = preserveY
      )
      for (existingCluster in existingClusters) {
        if (collisionTest(existingCluster, remainingMeta)) {
          remainingMeta <- NULL
          break
        }
      }
    }
    # join with existing main cluster
    metaClusters <- c(existingClusters, remainingMeta)
    return(metaClusters)
  }
  startMeta <- getRemainingMetaClusters(clustersForMerge)
  horMeta <- startMeta # getRemainingMetaClusters(clustersForMerge, preserveY = startMeta)
  verMeta <- startMeta # getRemainingMetaClusters(clustersForMerge, preserveX = startMeta)
  
  # merge clusters in meta
  horMeta[[1]] <- horPartner
  verMeta[[1]] <- verPartner
  
  # generate data points
  startData <- fillClusters(startMeta)
  horData <- fillClusters(horMeta, preserveY = startData)
  verData <- fillClusters(verMeta, preserveX = startData)
  
  if (F) {
    drawClusters(startData, highlightIdx = 1)
    drawClusters(horData, highlightIdx = 1)
    drawClusters(verData, highlightIdx = 1)
  }
  
  return(list(
    startData = startData,
    horizontalData = horData,
    verticalData = verData
  ))
}

get1DBotSplit <- function() {
  # create H/V split
  
  # keep main cluster to the outer edge (preserve center for distractors)
  margin <- 3 * config$maxClusterVariance
  
  # choose a position for the main cluster that will split
  # (keep it on a corner to be able to split in both directions)
  splitSource <- newBotCluster(
    margin = margin,
    variance = config$minClusterVariance,
    cornersOnly = TRUE)
  
  # get split target positions within a range of distances
  targetRange <- partnerRange(splitSource)
  
  horTarget <- list(
    x = runif(1, min = targetRange$x[1], max = targetRange$x[2]),
    y = splitSource$y,
    variance = splitSource$variance
  )
  verTarget <- list(
    x = splitSource$x,
    y = runif(1, min = targetRange$y[1], max = targetRange$y[2]),
    variance = splitSource$variance
  )
  
  # calculate remaining space for the other clusters
  remainingX <- remainingRange(splitSource$x, margin)
  remainingY <- remainingRange(splitSource$y, margin)
  
  # get remaining clusters (keep used margins free)
  # H/V clusters don't actually have points.
  # only generate 1 cluster less (for the splitting cluster)
  getRemainingMetaClusters <- function(existingClusters, preserveX = NULL, preserveY = NULL) {
    # find positions for remaining clusters
    remainingMeta <- NULL
    while(is.null(remainingMeta)) {
      remainingMeta <- newMetaClusters(
        howMany = (config$clusterCount - 1),
        xlim = remainingX,
        ylim = remainingY,
        preserveX = preserveX,
        preserveY = preserveY
      )
      for (existingCluster in existingClusters) {
        if (collisionTest(existingCluster, remainingMeta)) {
          remainingMeta <- NULL
          break
        }
      }
    }
    return(remainingMeta)
  }
  clustersForsplit = list(splitSource, horTarget, verTarget)
  startMeta <- getRemainingMetaClusters(clustersForsplit)
  startMeta <- c(list(splitSource), startMeta)
  
  # generate data points for start view
  startData <- fillClusters(startMeta)
  
  # generate data points for H view
  clusterSize <- length(startData[[1]]$x)
  halfSize <- trunc(clusterSize / 2) + 1
  horData <- fillClusters(startMeta, preserveY = startData)
  horData[[1]] <- moveCluster(
    horData[[1]],
    xOffset = (horTarget$x - splitSource$x),
    subRange = (halfSize:clusterSize))
  
  # generate data points for V view
  verData <- fillClusters(startMeta, preserveX = startData)
  verData[[1]] <- moveCluster(
    verData[[1]],
    yOffset = (verTarget$y - splitSource$y),
    subRange = (halfSize:clusterSize))
  
  if (F) {
    drawClusters(startData, highlightIdx = 1)
    drawClusters(horData, highlightIdx = 1)
    drawClusters(verData, highlightIdx = 1)
  }
  
  return(list(
    startData = startData,
    horizontalData = horData,
    verticalData = verData
  ))
}

get2DBotStay <- function() {
  # create 2D stay
  
  # keep main cluster to the outer edge (preserve center for distractors)
  margin <- 3 * config$maxClusterVariance
  
  # choose a position for the main cluster
  mainCluster <- newBotCluster(margin = margin, variance = config$minClusterVariance)
  
  # calculate remaining space for the other clusters
  # (we only need to keep one margin, not on both edges fo the plot)
  remainingX <- remainingRange(mainCluster$x, margin)
  remainingY <- remainingRange(mainCluster$y, margin)
  
  # get remaining clusters (keep used margin free)
  getRemainingMetaClusters <- function(mainCluster) {
    # find positions for remaining clusters
    remainingMeta <- NULL
    while(is.null(remainingMeta)) {
      remainingMeta <- newMetaClusters(
        howMany = (config$clusterCount - 1),
        xlim = remainingX,
        ylim = remainingY
      )
      #drawMetaClusters(c(list(mainCluster), remainingMeta))
      if (collisionTest(mainCluster, remainingMeta)) {
        remainingMeta <- NULL
      }
    }
    # join with existing main cluster
    metaClusters <- c(list(mainCluster), remainingMeta)
    #drawMetaClusters(metaClusters)
    return(metaClusters)
  }
  startMeta <- getRemainingMetaClusters(mainCluster)
  endMeta <- getRemainingMetaClusters(mainCluster)
  
  # generate data points
  startData <- fillClusters(startMeta)
  endData <- fillClusters(endMeta)
  endData[[1]] <- startData[[1]]
  
  if (F) {
    drawClusters(startData, highlightIdx = 1)
    drawClusters(endData, highlightIdx = 1)
  }
  
  return(list(
    startData = startData,
    endData = endData
  ))
}

get2DBotMerge <- function() {
  # keep main cluster to the outer edge (preserve center for distractors)
  margin <- 3 * config$maxClusterVariance
  
  # choose a position for the main cluster that will merge
  # (keep it on a corner to be able to merge in both directions)
  mergeCluster <- newBotCluster(
    margin = margin,
    variance = config$minClusterVariance,
    cornersOnly = TRUE)
  
  # get merge partner positions within a range of distances
  partnerRange <- partnerRange(mergeCluster)
  horizontal <- sample(c(TRUE, FALSE), 1)
  partnerCluster <- list(
    x = if (horizontal) runif(1, min = partnerRange$x[1], max = partnerRange$x[2]) else mergeCluster$x,
    y = if (!horizontal) runif(1, min = partnerRange$y[1], max = partnerRange$y[2]) else mergeCluster$y,
    variance = mergeCluster$variance
  )
  clustersForMerge = list(mergeCluster, partnerCluster)
  
  # calculate remaining space for the other clusters
  remainingX <- remainingRange(mergeCluster$x, margin)
  remainingY <- remainingRange(mergeCluster$y, margin)
  
  # get remaining clusters (keep used margins free)
  getRemainingMetaClusters <- function(existingClusters, preserveX = NULL, preserveY = NULL) {
    # find positions for remaining clusters
    remainingMeta <- NULL
    while(is.null(remainingMeta)) {
      remainingMeta <- newMetaClusters(
        howMany = (config$clusterCount - length(existingClusters)),
        xlim = remainingX,
        ylim = remainingY,
        preserveX = preserveX,
        preserveY = preserveY
      )
      for (existingCluster in existingClusters) {
        if (collisionTest(existingCluster, remainingMeta)) {
          remainingMeta <- NULL
          break
        }
      }
    }
    # join with existing main cluster
    metaClusters <- c(existingClusters, remainingMeta)
    return(metaClusters)
  }
  startMeta <- getRemainingMetaClusters(clustersForMerge)
  endMeta <- startMeta
  
  # merge clusters in meta
  endMeta[[1]] <- partnerCluster
  
  # generate data points
  startData <- fillClusters(startMeta)
  endData <- fillClusters(endMeta)
  
  if (F) {
    drawClusters(startData, highlightIdx = 1)
    drawClusters(endData, highlightIdx = 1)
  }
  
  return(list(
    startData = startData,
    endData = endData
  ))
}

get2DBotSplit <- function() {
  # create 2D split
  
  # keep main cluster to the outer edge (preserve center for distractors)
  margin <- 3 * config$maxClusterVariance
  
  # choose a position for the main cluster that will split
  # (keep it on a corner to be able to split in both directions)
  splitSource <- newBotCluster(
    margin = margin,
    variance = config$minClusterVariance,
    cornersOnly = TRUE)
  
  # get split target positions within a range of distances
  targetRange <- partnerRange(splitSource)
  horizontal <- sample(c(TRUE, FALSE), 1)
  targetCluster <- list(
    x = if (horizontal) runif(1, min = targetRange$x[1], max = targetRange$x[2]) else splitSource$x,
    y = if (!horizontal) runif(1, min = targetRange$y[1], max = targetRange$y[2]) else splitSource$y,
    variance = splitSource$variance
  )
  clustersForMerge = list(splitSource, targetCluster)
  
  # calculate remaining space for the other clusters
  remainingX <- remainingRange(splitSource$x, margin)
  remainingY <- remainingRange(splitSource$y, margin)
  
  # get remaining clusters (keep used margins free)
  # H/V clusters don't actually have points.
  # only generate 1 cluster less (for the splitting cluster)
  getRemainingMetaClusters <- function(existingClusters) {
    # find positions for remaining clusters
    remainingMeta <- NULL
    while(is.null(remainingMeta)) {
      remainingMeta <- newMetaClusters(
        howMany = (config$clusterCount - 1),
        xlim = remainingX,
        ylim = remainingY
      )
      for (existingCluster in existingClusters) {
        if (collisionTest(existingCluster, remainingMeta)) {
          remainingMeta <- NULL
          break
        }
      }
    }
    return(remainingMeta)
  }
  startMeta <- getRemainingMetaClusters(list(splitSource, targetCluster))
  startMeta <- c(list(splitSource), startMeta)
  
  # generate data points for start view
  startData <- fillClusters(startMeta)
  
  # generate data points for end view
  endData <- fillClusters(startMeta)
  
  # move second half of split cluster to target position
  clusterSize <- length(endData[[1]]$x)
  halfSize <- trunc(clusterSize / 2) + 1
  endData[[1]] <- moveCluster(
    endData[[1]],
    xOffset = (targetCluster$x - splitSource$x),
    yOffset = (targetCluster$y - splitSource$y),
    subRange = (halfSize:clusterSize))
  
  if (F) {
    drawClusters(startData, highlightIdx = 1)
    drawClusters(endData, highlightIdx = 1)
  }
  
  return(list(
    startData = startData,
    endData = endData
  ))
}

generateBotData <- function(repetitions) {
  # initialize data frame
  allData <- data.frame(matrix(ncol = 0, nrow = config$pointCount))
  
  # how many tasks we already produced
  dataSetCount <- 0
  addOneDData <- function(oneDResult, action) {
    dataSetCount <<- dataSetCount + 1
    allData <<- addCoords(
      jointDF = allData,
      filledClusters = oneDResult$startData,
      dataSetCount,
      action,
      "start")
    allData <<- addCoords(
      jointDF = allData,
      filledClusters = oneDResult$horizontalData,
      dataSetCount,
      action,
      dims$hor,
      y = F)
    allData <<- addCoords(
      jointDF = allData,
      filledClusters = oneDResult$verticalData,
      dataSetCount,
      action,
      dims$ver,
      x = F)
    # debug info
    #drawClusters(oneDResult$startData, name=paste(action, dataSetCount, "Start"), highlightIdx = 1)
    #drawClusters(oneDResult$horizontalData, name=paste(action, dataSetCount, "Horizontal"), highlightIdx = 1)
    #drawClusters(oneDResult$verticalData, name=paste(action, dataSetCount, "Vertical"), highlightIdx = 1)
  }
  addTwoDData <- function(twoDResult, action) {
    dataSetCount <<- dataSetCount + 1
    allData <<- addCoords(jointDF = allData, filledClusters = twoDResult$startData, dataSetCount, action, "start")
    allData <<- addCoords(jointDF = allData, filledClusters = twoDResult$endData, dataSetCount, action, dims$both)
    # debug info
    #drawClusters(twoDResult$startData, name=paste(action, dataSetCount, "Start"), highlightIdx = 1)
    #drawClusters(twoDResult$endData, name=paste(action, dataSetCount, "End"), highlightIdx = 1)
  }
  
  for (ignore in 1:repetitions) {
    # generate 1D stay data
    botResult <- get1DBotStay()
    addOneDData(botResult, actions$stay)
    
    # generate 1D merge data
    botResult <- get1DBotMerge()
    addOneDData(botResult, actions$merge)
    
    # generate 1D split data
    botResult <- get1DBotSplit()
    addOneDData(botResult, actions$split)
  }
  
  # double for 2D because some transitions won't differentiate H/V
  for (ignore in 1:(repetitions*2)) {
    # generate 2D stay data
    botResult <- get2DBotStay()
    addTwoDData(botResult, actions$stay)
    
    # generate 2D merge data
    botResult <- get2DBotMerge()
    addTwoDData(botResult, actions$merge)
    
    # generate 2D split data
    botResult <- get2DBotSplit()
    addTwoDData(botResult, actions$split)
  }
  
  return(allData)
}



studyData <- generateStudyData(repetitions = 1)
#drawStudyData(studyData)
write.csv(studyData, file = "clusterStudy.csv", row.names = FALSE, quote = FALSE)
createStudyProtocol(
  allData = studyData,
  taskName = "clusterStudy",
  datasetName = "clusterStudy",
  targetDir = "../scripts",
  isTraining = FALSE)

trainingData <- generateStudyData(repetitions = 1)
#drawStudyData(trainingData)
write.csv(trainingData, file = "clusterTrain.csv", row.names = FALSE, quote = FALSE)
createStudyProtocol(
  allData = trainingData,
  taskName = "clusterTrain",
  datasetName = "clusterTrain",
  targetDir = "../scripts",
  isTraining = TRUE)

config <- botConfig
botData <- generateBotData(repetitions = 1)
#drawStudyData(botData)
write.csv(botData, file = "clusterBot.csv", row.names = FALSE, quote = FALSE)
createStudyProtocol(
  allData = botData,
  taskName = "clusterBot",
  datasetName = "clusterBot",
  targetDir = "../scripts",
  isTraining = FALSE)
