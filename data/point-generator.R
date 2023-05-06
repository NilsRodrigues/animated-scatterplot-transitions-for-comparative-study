# setup
rm(list = ls())
if (!is.null(dev.list()["RStudioGD"])) {
  dev.off(dev.list()["RStudioGD"])
}
set.seed(1668527508) # make this reproducible
library(rjson)
library(plotrix)


botDataCount <- 30
botPosition <- 0.15
botVariance <- 0.12
botMargin <- 0.3
minBotDistance <- 0.01
maxLayoutRetry <- 50
maxPointRetry <- 5 * botDataCount

realPointInput <- "autoMPG.csv"



endOfDebugging <- function() {
  # get calling function
  callStack <- sys.calls()
  frameCount <- sys.nframe()
  funcName <- callStack[[frameCount-1]][[1]]
  
  # end execution
  msg <- paste("Reached end of ", funcName, ". Pausing.", sep = "")
  stop(msg)
}


newPointList <- function() {
  return(matrix(nrow = 0, ncol = 2, dimnames = list(NULL, c("x", "y"))))
}

distance <- function(point1, point2) {
  return(sqrt(
    (point2[1] - point1[1])^2 +
    (point2[2] - point1[2])^2
  ))
}

collisionTest <- function(testPoint, otherPoints = NULL, reservedPoint = NULL) {
  # check for collision with reserved point
  if (!is.null(reservedPoint)) {
    actualDistance <- distance(testPoint, reservedPoint)
    if (actualDistance < botMargin * 2)
      return(TRUE)
  }
  
  # check for collision with other points
  collision <- FALSE
  if (!is.null(otherPoints))
  {
    for (i in seq_len(nrow(otherPoints))) {
      
      existing <- otherPoints[i, ]
      # get actual distance
      actualDistance <- distance(testPoint, existing)
      # check if they overlap
      if (actualDistance < minBotDistance) {
        collision <- TRUE
        break
      }
    }
  }
  return(collision)
}

newPointAnywhere <- function(preserveX = NULL, preserveY = NULL, xlim = c(0,1), ylim = c(0,1)) {
  # don't allow preserving too much
  if (!is.null(preserveX) && !is.null(preserveY)) {
    stop("Can't get new point position by preserving both X and Y.")
  }
  
  # get new position in normalized coordinates
  if (missing(preserveX)) {
    x <- runif(1, min = xlim[1], max = xlim[2])
  } else {
    x <- preserveX[1]
  }
  if (missing(preserveY)) {
    y <- runif(1, min = ylim[1], max = ylim[2])
  } else {
    if (length(preserveX) >= 2)
      y <- preserveY[2]
    else
      y <- preserveY[1]
  }
  return(c(x = x, y = y))
}

newBotPoints <- function(
    reservedPoint = NULL,
    preserveX = NULL,
    preserveY = NULL,
    xlim = c(0,1),
    ylim = c(0,1),
    howMany = botDataCount
) {
  # can't preserve both
  if (!is.null(preserveX) && !is.null(preserveY)) {
    stop("Can't preserve both coordinates, because there'd be no change at all.")
  }
  
  newPoint <- function (idx) {
    if (is.null(preserveX)) {
      if (is.null(preserveY)) {
        return(newPointAnywhere(xlim = xlim, ylim = ylim))
      } else {
        return(newPointAnywhere(
          preserveY = preserveY[idx,2],
          xlim = xlim,
          ylim = ylim
        ))
      }
    } else {
      # preserveX is set and they can't both be set => no need to check Y
      return(newPointAnywhere(
        preserveX = preserveX[idx,1],
        xlim = xlim,
        ylim = ylim
      ))
    }
  }
  
  layoutRetryCount <- 0
  tryLayoutAgain <- TRUE
  while (tryLayoutAgain) {
    layoutRetryCount <- layoutRetryCount + 1
    if (layoutRetryCount > maxLayoutRetry) {
      stop("Too many layout retries.")
    }
    
    # first point won't hit anything
    positions <- newPointList()
    if (is.null(reservedPoint)) {
      positions <- rbind(positions, newPoint(1))
    }
    
    # other points: generate a new one and use it,
    # if it doesn't collide with the existing ones
    pointRetryCount <- 0
    for (pointRetryCount in 1:maxPointRetry) {
      if (nrow(positions) >= howMany) {
        break
      }
      candidate <- newPoint(nrow(positions) + 1)
      if (!collisionTest(candidate, positions, reservedPoint = reservedPoint)) {
        positions <- rbind(positions, candidate)
      }
    }
    
    tryLayoutAgain <- nrow(positions) < howMany
    #if (tryLayoutAgain) {
    #  cat("Only got", nrow(positions), "points into layout.\n")
    #}
  }
  
  # reset row names
  rownames(positions) <- NULL
  
  return(positions)
}

debugNewBotPoints <- function() {
  bp <- newBotPoints()
  print(bp)
  endOfDebugging()
}
#debugNewBotPoints()



drawPoints <- function(positions, name = NULL, highlightIdx = 1) {
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
    initPlot("", "X", "Y")
  } else {
    initPlot(name, "", "")
  }
  
  points(x = positions[,1], y = positions[,2], pch = 19, col = "black")
  if (!is.na(highlightIdx) && highlightIdx >= 1) {
    points(x = positions[highlightIdx,1], y = positions[highlightIdx,2], pch = 19, col = "red")
  }
}
debugDrawPoints <- function() {
  bp <- newBotPoints()
  drawPoints(bp)
  endOfDebugging()
}
#debugDrawPoints()


newBotTask <- function(oneD) {
  # choose one of four positions for the main point
  mainPoint1 <- sample(x = c(botPosition, 1-botPosition), size = 2, replace = T)
  
  # keep area round main point clear in x and y
  if (mainPoint1[1] < 0.5) {
    xlim <- c(botMargin, 1)
  } else {
    xlim <- c(0, 1 - botMargin)
  }
  if (mainPoint1[2] < 0.5) {
    ylim <- c(botMargin, 1)
  } else {
    ylim <- c(0, 1 - botMargin)
  }
  
  # choose points that sit in the other corners. they are necessary to span up the
  # entire range of c(0,1). otherwise, later normalization will mess up our coords.
  cornerPoints <- matrix(nrow = 3, ncol = 2)
  if (mainPoint1[1] < 0.5) {
    cornerPoints[1,] <- c(1,0)
    cornerPoints[2,] <- c(1,1)
    if (mainPoint1[2] < 0.5) {
      cornerPoints[3,] <- c(0,1)
    } else {
      cornerPoints[3,] <- c(0,0)
    }
  } else {
    cornerPoints[1,] <- c(0,0)
    cornerPoints[2,] <- c(0,1)
    if (mainPoint1[2] < 0.5) {
      cornerPoints[3,] <- c(1,1)
    } else {
      cornerPoints[3,] <- c(1,0)
    }
  }
    
  # find other bot points (-1 for mainPoint, -3 for corner points)
  view1 <- newBotPoints(
    reservedPoint = mainPoint1,
    xlim = xlim,
    ylim = ylim,
    howMany = botDataCount - 4)
  
  # move reserved point for second view.
  # move exactly the variance distance. bot test shouldn't give false negative when people click on initial position.
  angle <- runif(1, min = 0, max = 2*pi)
  mainPoint2 <- mainPoint1 + c(cos(angle) * botVariance, sin(angle) * botVariance)
  
  # find other bot points
  if (oneD) {
    # horizontal
    mainPointHor <- c(x = mainPoint2[1], y = mainPoint1[2])
    viewHor <- newBotPoints(
      reservedPoint = mainPointHor,
      preserveY = view1,
      xlim = xlim,
      ylim = ylim,
      howMany = botDataCount - 4
    )
    viewHor <- rbind(mainPointHor, cornerPoints, viewHor)
    rownames(viewHor) <- NULL
    
    # vertical
    mainPointVer <- c(x = mainPoint1[1], y = mainPoint2[2])
    viewVer <- newBotPoints(
      reservedPoint = mainPointVer,
      preserveX = view1,
      xlim = xlim,
      ylim = ylim,
      howMany = botDataCount - 4
    )
    viewVer <- rbind(mainPointVer, cornerPoints, viewVer)
    rownames(viewVer) <- NULL
    
    # combine
    view2 = cbind(viewHor[,1], viewVer[,2])
    colnames(view2) <- NULL
  } else {
    view2 <- newBotPoints(
      reservedPoint = mainPoint2,
      xlim = xlim,
      ylim = ylim,
      howMany = botDataCount - 4)
    view2 <- rbind(mainPoint2, cornerPoints, view2)
    rownames(view2) <- NULL
  }
  
  # add main point to initial view
  view1 <- rbind(mainPoint1, cornerPoints, view1)
  rownames(view1) <- NULL
  
  if (oneD) {
    result <- list(
      startData = view1,
      horData = viewHor,
      verData = viewVer,
      endData = view2
    )
  } else {
    result <- list(
      startData = view1,
      endData = view2
    )
  }
  return(result)
}

debugNewBotTask <- function() {
  bt <- newBotTask(oneD = T)
  drawPoints(bt$startData, name = "1D start view")
  drawPoints(cbind(bt$endData[,1], bt$startData[,2]), name = "1D hor end view")
  drawPoints(cbind(bt$startData[,1], bt$endData[,2]), name = "1D ver end view")
  
  bt <- newBotTask(oneD = F)
  drawPoints(bt$startData, name = "2D initial view")
  drawPoints(bt$endData, name = "2D end view")
  
  endOfDebugging()
}
#debugNewBotTasks()


drawTask <- function(task, forceOneD = F) {
  if (forceOneD || !is.null(task$horData)) {
    # separate 1D views
    drawPoints(task$startData, name = "1D start view")
    
    # create our own 1D views
    if (forceOneD) {
      horData <- cbind(x = task$endData[,1], y = task$startData[,2])
      verData <- cbind(x = task$startData[,1], y = task$endData[,2])
    } else {
      horData <- task$horData
      verData <- task$verData
    }
    
    # draw the 1D views
    drawPoints(horData, name = "1D hor end view")
    drawPoints(verData, name = "1D ver end view")
  } else {
    # use 2D
    drawPoints(task$startData, name = "2D initial view")
    drawPoints(task$endData, name = "2D end view")
  }
}


dims <- list(hor = "hor", ver = "ver", both = "both")

myColName <- function(...) {
  return(paste(..., sep="_"))
}


generateBotData <- function(repetitions) {
  # initialize data frame
  allData <- data.frame(matrix(ncol = 0, nrow = botDataCount))
  
  # how many tasks we already produced
  dataSetCount <- 0
  addData <- function(taskData, name, x = T, y = T) {
    if (x) {
      colName <- myColName(dataSetCount, name, "x")
      allData[colName] <<- taskData[,1]
    }
    if (y) {
      colName <- myColName(dataSetCount, name, "y")
      allData[colName] <<- taskData[,2]
    }
  }
  
  # add regular 1D tasks
  for (ignore in 1:repetitions) {
    bt <- newBotTask(oneD = T)
    dataSetCount <- dataSetCount + 1
    addData(bt$startData, "start")
    addData(bt$endData, dims$hor, y = F)
    addData(bt$endData, dims$ver, x = F)
    # debug info
    #drawTask(bt)
  }
  
  # add twice the mount of tasks for transitions that won't differentiate H/V
  for (ignore in 1:(repetitions*2)) {
    bt <- newBotTask(oneD = F)
    dataSetCount <- dataSetCount + 1
    addData(bt$startData, "start")
    addData(bt$endData, dims$both)
    # debug info
    #drawTask(bt)
  }
  
  return(allData)
}




strContains <- function(text, pattern) {
  return(grepl(x = text, pattern = pattern, fixed = TRUE))
}

createProtocol <- function(taskName, targetDir, experiments1D, experiments2D) {
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
    # adjust for 0-based indices in JS
    adjustIndices <- function(experiment) {
      experiment$datapointId <- experiment$datapointId - 1
      adjustPair <- function(dimPair) {
        dimPair$x <- dimPair$x - 1
        dimPair$y <- dimPair$y - 1
        return(dimPair)
      }
      if ("dims" %in% names(experiment)) {
        experiment$dims <- lapply(experiment$dims, adjustPair)
      }
      if ("commonDims" %in% names(experiment)) {
        experiment$commonDims <- lapply(experiment$commonDims, adjustPair)
      }
      if ("directDims" %in% names(experiment)) {
        experiment$directDims <- lapply(experiment$directDims, adjustPair)
      }
      return(experiment)
    }
    experiments1D <- lapply(experiments1D, adjustIndices)
    experiments2D <- lapply(experiments2D, adjustIndices)
    
    # remove info about correct result from public protocol
    removeActual <- function(experiment) {
      experiment$actual <- NULL
      return(experiment)
    }
    experiments1D <- lapply(experiments1D, removeActual)
    experiments1D <- lapply(experiments1D, removeActual)
    
    # convert experiments to JSON
    rawJson1D <- toJSON(experiments1D, indent = 2)
    rawJson2D <- toJSON(experiments2D, indent = 2)
    
    # add JSON indentation to match remainder of JS file
    addIndentation <- function(json, indentation) {
      return(gsub(
        x = json,
        pattern = "\n",
        replacement = paste("\n", indentation, sep = ""),
        fixed = TRUE
      ))
    }
    json1D <- addIndentation(rawJson1D, "      ")
    json2D <- addIndentation(rawJson2D, "      ")
    
    # compose JS file
    js <- paste(
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




createBotProtocol <- function(allData, taskName, targetDir) {
  # check column count
  colCount <- ncol(allData)
  pairSize <- 4
  if ((colCount %% pairSize) != 0) {
    stop("The columns in drawable data need to come in pairs of 4 (2 views with x/y each)!")
  }
  
  experiments1D <- list()
  experiments2D <- list()
  dataPointId <- 1
  datasetName <- taskName
  
  addEntry1D <- function (horizontal, dimPairs) {
    lastDimPair = dimPairs[[length(dimPairs)]]
    
    experiments1D[[length(experiments1D) + 1]] <<- list(
      datasetName = datasetName,
      datapointId = dataPointId,
      horizontal = horizontal,
      dims = dimPairs,
      actual = c(
        x = allData[dataPointId,lastDimPair$x],
        y = allData[dataPointId,lastDimPair$y]
      )
    )
  }
  
  addEntry2D <- function (horizontal, dimPairs) {
    lastDimPair = dimPairs[[length(dimPairs)]]
    
    experiments2D[[length(experiments2D) + 1]] <<- list(
      datasetName = datasetName,
      datapointId = dataPointId,
      horizontal = horizontal,
      directDims = list(dimPairs[[1]], dimPairs[[length(dimPairs)]]), # use only first and last pair
      commonDims = dimPairs, # use all pairs
      actual = c(
        x = allData[dataPointId,lastDimPair$x],
        y = allData[dataPointId,lastDimPair$y]
      )
    )
  }
  
  # check dataset count
  dataSetCount <- colCount %/% pairSize
  if (dataSetCount > 1) {
    # export all 1D experiments first
    for (t in 0:(dataSetCount-1)) {
      endNameX <- colnames(allData)[t*pairSize + 3]
      isTwoDim <- strContains(endNameX, dims$both)
      
      # experiments on 1D data sets
      if (!isTwoDim) {
        # horizontal only
        addEntry1D(
          horizontal = TRUE,
          dimPairs = list(
            list(x = (t*pairSize + 1), y = (t*pairSize + 2)),
            list(x = (t*pairSize + 3), y = (t*pairSize + 2))
          )
        )
        # vertical only
        addEntry1D(
          horizontal = FALSE,
          dimPairs = list(
            list(x = (t*pairSize + 1), y = (t*pairSize + 2)),
            list(x = (t*pairSize + 1), y = (t*pairSize + 4))
          )
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
        addEntry2D(
          horizontal = TRUE,
          dimPairs = list(
            list(x = (t*pairSize + 1), y = (t*pairSize + 2)),
            list(x = (t*pairSize + 3), y = (t*pairSize + 2)),
            list(x = (t*pairSize + 3), y = (t*pairSize + 4))
          )
        )
        # vertical first, horizontal second
        addEntry2D(
          horizontal = FALSE,
          dimPairs = list(
            list(x = (t*pairSize + 0), y = (t*pairSize + 1)),
            list(x = (t*pairSize + 0), y = (t*pairSize + 3)),
            list(x = (t*pairSize + 2), y = (t*pairSize + 3))
          )
        )
      }
    }
  }
  
  # write JS and JSON files
  createProtocol(
    taskName = taskName,
    targetDir = targetDir,
    experiments1D = experiments1D,
    experiments2D = experiments2D
  )
}


normalizeData <- function(inputData) {
  for (i in seq_len(ncol(inputData))) {
    values <- inputData[,i]
    minimum <- min(values)
    maximum <- max(values)
    
    if (minimum == maximum) {
      stop("Input data has not enough variance to normalize column '", colnames(inputData)[i], "'.")
    } else {
      inputData[,i] <- (values - minimum) / (maximum - minimum)
    }
  }
  return(inputData)
}

existingViews <- matrix(nrow = 4, ncol = 0, byrow = F)
createNewRealView <- function(inputData, uniqueView = TRUE, dimProbability = NULL) {
  dataPointId <- sample(x = nrow(inputData), size = 1, replace = T)
  
  dims <- NULL
  for(retry in 1:50) {
    dims <- sample(x = ncol(inputData), size = 4, replace = F, prob = dimProbability)
    # doesn't need to be unique
    if (!uniqueView) {
      break
    }
    # check if unique by checking if column already exists
    alreadyUsed <- any(apply(existingViews, 2, function(c) all(c== dims)))
    if (!alreadyUsed) {
      break;
    }
    dims <- NULL
  }
  existingViews <<- cbind(existingViews, dims)
  
  return(list(
    dataPointId = dataPointId,
    startView = list(x = dims[1], y = dims[2]),
    horView = list(x = dims[3], y = dims[2]),
    verView = list(x = dims[1], y = dims[4]),
    endView = list(x = dims[3], y = dims[4])
  ))
}

createRealProtocol <- function(inputData, repetitions, taskName, datasetName, targetDir, dimProbability = NULL) {
  experiments1D <- list()
  experiments2D <- list()
  
  addEntry1D <- function (horizontal, realView) {
    endView = if (horizontal) realView$horView else realView$verView
    
    experiments1D[[length(experiments1D) + 1]] <<- list(
      datasetName = datasetName,
      datapointId = realView$dataPointId,
      horizontal = horizontal,
      dims = list(realView$startView, endView),
      actual = c(
        x = inputData[realView$dataPointId, endView$x],
        y = inputData[realView$dataPointId, endView$y]
      )
    )
  }
  
  addEntry2D <- function (horizontal, realView) {
    experiments2D[[length(experiments2D) + 1]] <<- list(
      datasetName = datasetName,
      datapointId = realView$dataPointId,
      horizontal = horizontal,
      directDims = list(realView$startView, realView$endView),
      commonDims = list(
        realView$startView,
        if (horizontal) realView$horView else realView$verView,
        realView$endView
      ),
      actual = c(
        x = inputData[realView$dataPointId, realView$endView$x],
        y = inputData[realView$dataPointId, realView$endView$y]
      )
    )
  }
  
  # add for regular 1D
  for (i in 1:repetitions) {
    realView <- createNewRealView(inputData, dimProbability = dimProbability)
    existingViews
    addEntry1D(horizontal = TRUE, realView = realView)
    addEntry1D(horizontal = FALSE, realView = realView)
  }
  
  # add twice the mount of tasks for transitions that won't differentiate H/V
  for (i in 1:(repetitions*2)) {
    # add 2D experiments
    realView <- createNewRealView(inputData, dimProbability = dimProbability)
    addEntry2D(horizontal = TRUE, realView = realView)
    addEntry2D(horizontal = FALSE, realView = realView)
  }
  
  # write JS and JSON files
  createProtocol(
    taskName = taskName,
    targetDir = targetDir,
    experiments1D = experiments1D,
    experiments2D = experiments2D
  )
}

getDimProbability <- function(inputData) {
  #rm <- matrix(inputData)
  probs <- apply(inputData, 2, function(realCol) {
    distinctCount <- length(unique(realCol))
    return(log(distinctCount))
  })
  
  # limit variability. only allow 1 or 0.5
  probs <- probs/max(probs)
  probs[probs < 0.5] <- 0.5
  probs[probs > 0.5] <- 1
  
  return(probs)
}


#### bot data ####
botData <- generateBotData(repetitions = 2)
write.csv(botData, file = "pointBot.csv", row.names = FALSE, quote = FALSE)
createBotProtocol(botData, taskName = "pointBot", targetDir = "../scripts")

#### real data ####
realData <- read.csv(file = realPointInput)
if (F) {
  # strip non-numeric dims
  for (c in rev(seq_len(ncol(realData)))) {
    if (!is.numeric(realData[,c])) {
      realData <- subset(realData, select = -c)
    }
  }
  
  # normalize it
  realData <- normalizeData(realData)
  # re-write the normalized data to the file
  write.csv(realData, file = realPointInput, row.names = FALSE, quote = FALSE)
}
# prefer continuous dims
dimProb <- getDimProbability(realData)
datasetName <- tools::file_path_sans_ext(basename(realPointInput))
createRealProtocol(
  inputData = realData,
  repetitions = 1,
  taskName = "pointTrain",
  datasetName = datasetName,
  targetDir = "../scripts",
  dimProbability = dimProb
)
createRealProtocol(
  inputData = realData,
  repetitions = 3,
  taskName = "pointStudy",
  datasetName = datasetName,
  targetDir = "../scripts",
  dimProbability = dimProb
)

