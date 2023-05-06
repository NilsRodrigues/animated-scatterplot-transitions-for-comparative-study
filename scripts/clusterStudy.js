{

const pointIndices = [...Array(80).keys()]
const ClusterStudy = {
  Experiments1D: [
        {
          "datasetName":"clusterStudy",
          "datapointIds":pointIndices,
          "horizontal":    true,
          "dims":[
            {
              "x":        0,
              "y":        1
            },
            {
              "x":        2,
              "y":        1
            }
          ]
        },
        {
          "datasetName":"clusterStudy",
          "datapointIds":pointIndices,
          "horizontal":    false,
          "dims":[
            {
              "x":        0,
              "y":        1
            },
            {
              "x":        0,
              "y":        3
            }
          ]
        },
        {
          "datasetName":"clusterStudy",
          "datapointIds":pointIndices,
          "horizontal":    true,
          "dims":[
            {
              "x":        4,
              "y":        5
            },
            {
              "x":        6,
              "y":        5
            }
          ]
        },
        {
          "datasetName":"clusterStudy",
          "datapointIds":pointIndices,
          "horizontal":    false,
          "dims":[
            {
              "x":        4,
              "y":        5
            },
            {
              "x":        4,
              "y":        7
            }
          ]
        },
        {
          "datasetName":"clusterStudy",
          "datapointIds":pointIndices,
          "horizontal":    true,
          "dims":[
            {
              "x":        8,
              "y":        9
            },
            {
              "x":        10,
              "y":        9
            }
          ]
        },
        {
          "datasetName":"clusterStudy",
          "datapointIds":pointIndices,
          "horizontal":    false,
          "dims":[
            {
              "x":        8,
              "y":        9
            },
            {
              "x":        8,
              "y":        11
            }
          ]
        }
      ],
  Experiments2D: [
        {
          "datasetName":"clusterStudy",
          "datapointIds":pointIndices,
          "horizontal":    true,
          "directDims":[
            {
              "x":        12,
              "y":        13
            },
            {
              "x":        14,
              "y":        15
            }
          ],
          "commonDims":[
            {
              "x":        12,
              "y":        13
            },
            {
              "x":        14,
              "y":        13
            },
            {
              "x":        14,
              "y":        15
            }
          ],
          "actual":"stay"
        },
        {
          "datasetName":"clusterStudy",
          "datapointIds":pointIndices,
          "horizontal":    false,
          "directDims":[
            {
              "x":        12,
              "y":        13
            },
            {
              "x":        14,
              "y":        15
            }
          ],
          "commonDims":[
            {
              "x":        12,
              "y":        13
            },
            {
              "x":        12,
              "y":        15
            },
            {
              "x":        14,
              "y":        15
            }
          ],
          "actual":"stay"
        },
        {
          "datasetName":"clusterStudy",
          "datapointIds":pointIndices,
          "horizontal":    true,
          "directDims":[
            {
              "x":        16,
              "y":        17
            },
            {
              "x":        18,
              "y":        19
            }
          ],
          "commonDims":[
            {
              "x":        16,
              "y":        17
            },
            {
              "x":        18,
              "y":        17
            },
            {
              "x":        18,
              "y":        19
            }
          ],
          "actual":"merge"
        },
        {
          "datasetName":"clusterStudy",
          "datapointIds":pointIndices,
          "horizontal":    false,
          "directDims":[
            {
              "x":        16,
              "y":        17
            },
            {
              "x":        18,
              "y":        19
            }
          ],
          "commonDims":[
            {
              "x":        16,
              "y":        17
            },
            {
              "x":        16,
              "y":        19
            },
            {
              "x":        18,
              "y":        19
            }
          ],
          "actual":"merge"
        },
        {
          "datasetName":"clusterStudy",
          "datapointIds":pointIndices,
          "horizontal":    true,
          "directDims":[
            {
              "x":        20,
              "y":        21
            },
            {
              "x":        22,
              "y":        23
            }
          ],
          "commonDims":[
            {
              "x":        20,
              "y":        21
            },
            {
              "x":        22,
              "y":        21
            },
            {
              "x":        22,
              "y":        23
            }
          ],
          "actual":"split"
        },
        {
          "datasetName":"clusterStudy",
          "datapointIds":pointIndices,
          "horizontal":    false,
          "directDims":[
            {
              "x":        20,
              "y":        21
            },
            {
              "x":        22,
              "y":        23
            }
          ],
          "commonDims":[
            {
              "x":        20,
              "y":        21
            },
            {
              "x":        20,
              "y":        23
            },
            {
              "x":        22,
              "y":        23
            }
          ],
          "actual":"split"
        },
        {
          "datasetName":"clusterStudy",
          "datapointIds":pointIndices,
          "horizontal":    true,
          "directDims":[
            {
              "x":        24,
              "y":        25
            },
            {
              "x":        26,
              "y":        27
            }
          ],
          "commonDims":[
            {
              "x":        24,
              "y":        25
            },
            {
              "x":        26,
              "y":        25
            },
            {
              "x":        26,
              "y":        27
            }
          ],
          "actual":"stay"
        },
        {
          "datasetName":"clusterStudy",
          "datapointIds":pointIndices,
          "horizontal":    false,
          "directDims":[
            {
              "x":        24,
              "y":        25
            },
            {
              "x":        26,
              "y":        27
            }
          ],
          "commonDims":[
            {
              "x":        24,
              "y":        25
            },
            {
              "x":        24,
              "y":        27
            },
            {
              "x":        26,
              "y":        27
            }
          ],
          "actual":"stay"
        },
        {
          "datasetName":"clusterStudy",
          "datapointIds":pointIndices,
          "horizontal":    true,
          "directDims":[
            {
              "x":        28,
              "y":        29
            },
            {
              "x":        30,
              "y":        31
            }
          ],
          "commonDims":[
            {
              "x":        28,
              "y":        29
            },
            {
              "x":        30,
              "y":        29
            },
            {
              "x":        30,
              "y":        31
            }
          ],
          "actual":"merge"
        },
        {
          "datasetName":"clusterStudy",
          "datapointIds":pointIndices,
          "horizontal":    false,
          "directDims":[
            {
              "x":        28,
              "y":        29
            },
            {
              "x":        30,
              "y":        31
            }
          ],
          "commonDims":[
            {
              "x":        28,
              "y":        29
            },
            {
              "x":        28,
              "y":        31
            },
            {
              "x":        30,
              "y":        31
            }
          ],
          "actual":"merge"
        },
        {
          "datasetName":"clusterStudy",
          "datapointIds":pointIndices,
          "horizontal":    true,
          "directDims":[
            {
              "x":        32,
              "y":        33
            },
            {
              "x":        34,
              "y":        35
            }
          ],
          "commonDims":[
            {
              "x":        32,
              "y":        33
            },
            {
              "x":        34,
              "y":        33
            },
            {
              "x":        34,
              "y":        35
            }
          ],
          "actual":"split"
        },
        {
          "datasetName":"clusterStudy",
          "datapointIds":pointIndices,
          "horizontal":    false,
          "directDims":[
            {
              "x":        32,
              "y":        33
            },
            {
              "x":        34,
              "y":        35
            }
          ],
          "commonDims":[
            {
              "x":        32,
              "y":        33
            },
            {
              "x":        32,
              "y":        35
            },
            {
              "x":        34,
              "y":        35
            }
          ],
          "actual":"split"
        }
      ],
};

const sp = window.sp || {};
sp.ClusterStudy = ClusterStudy;
window.sp = sp;
}
