{
const PointTrain = {
  Experiments1D: [
        {
          "datasetName":"autoMPG",
          "datapointId":    272,
          "horizontal":    true,
          "dims":[
            {
              "x":        1,
              "y":        4
            },
            {
              "x":        5,
              "y":        4
            }
          ]
        },
        {
          "datasetName":"autoMPG",
          "datapointId":    272,
          "horizontal":    false,
          "dims":[
            {
              "x":        1,
              "y":        4
            },
            {
              "x":        1,
              "y":        6
            }
          ]
        }
      ],
  Experiments2D: [
        {
          "datasetName":"autoMPG",
          "datapointId":    311,
          "horizontal":    true,
          "directDims":[
            {
              "x":        5,
              "y":        0
            },
            {
              "x":        4,
              "y":        7
            }
          ],
          "commonDims":[
            {
              "x":        5,
              "y":        0
            },
            {
              "x":        4,
              "y":        0
            },
            {
              "x":        4,
              "y":        7
            }
          ],
          "actual":{
            "x":0.301956336830167,
            "y":0
          }
        },
        {
          "datasetName":"autoMPG",
          "datapointId":    311,
          "horizontal":    false,
          "directDims":[
            {
              "x":        5,
              "y":        0
            },
            {
              "x":        4,
              "y":        7
            }
          ],
          "commonDims":[
            {
              "x":        5,
              "y":        0
            },
            {
              "x":        5,
              "y":        7
            },
            {
              "x":        4,
              "y":        7
            }
          ],
          "actual":{
            "x":0.301956336830167,
            "y":0
          }
        },
        {
          "datasetName":"autoMPG",
          "datapointId":    1,
          "horizontal":    true,
          "directDims":[
            {
              "x":        5,
              "y":        3
            },
            {
              "x":        2,
              "y":        6
            }
          ],
          "commonDims":[
            {
              "x":        5,
              "y":        3
            },
            {
              "x":        2,
              "y":        3
            },
            {
              "x":        2,
              "y":        6
            }
          ],
          "actual":{
            "x":0.728682170542636,
            "y":0
          }
        },
        {
          "datasetName":"autoMPG",
          "datapointId":    1,
          "horizontal":    false,
          "directDims":[
            {
              "x":        5,
              "y":        3
            },
            {
              "x":        2,
              "y":        6
            }
          ],
          "commonDims":[
            {
              "x":        5,
              "y":        3
            },
            {
              "x":        5,
              "y":        6
            },
            {
              "x":        2,
              "y":        6
            }
          ],
          "actual":{
            "x":0.728682170542636,
            "y":0
          }
        }
      ],
};

const sp = window.sp || {};
sp.PointTrain = PointTrain;
window.sp = sp;
}
