{
const PointBot = {
  Experiments1D: [
        {
          "datasetName":"pointBot",
          "datapointId":    0,
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
          "datasetName":"pointBot",
          "datapointId":    0,
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
          "datasetName":"pointBot",
          "datapointId":    0,
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
          "datasetName":"pointBot",
          "datapointId":    0,
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
        }
      ],
  Experiments2D: [
        {
          "datasetName":"pointBot",
          "datapointId":    0,
          "horizontal":    true,
          "directDims":[
            {
              "x":        8,
              "y":        9
            },
            {
              "x":        10,
              "y":        11
            }
          ],
          "commonDims":[
            {
              "x":        8,
              "y":        9
            },
            {
              "x":        10,
              "y":        9
            },
            {
              "x":        10,
              "y":        11
            }
          ],
          "actual":{
            "x":0.0980413935281069,
            "y":0.741832060140266
          }
        },
        {
          "datasetName":"pointBot",
          "datapointId":    0,
          "horizontal":    false,
          "directDims":[
            {
              "x":        7,
              "y":        8
            },
            {
              "x":        9,
              "y":        10
            }
          ],
          "commonDims":[
            {
              "x":        7,
              "y":        8
            },
            {
              "x":        7,
              "y":        10
            },
            {
              "x":        9,
              "y":        10
            }
          ],
          "actual":{
            "x":0.85,
            "y":0.0980413935281069
          }
        },
        {
          "datasetName":"pointBot",
          "datapointId":    0,
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
          "actual":{
            "x":0.237175080147781,
            "y":0.932465176900483
          }
        },
        {
          "datasetName":"pointBot",
          "datapointId":    0,
          "horizontal":    false,
          "directDims":[
            {
              "x":        11,
              "y":        12
            },
            {
              "x":        13,
              "y":        14
            }
          ],
          "commonDims":[
            {
              "x":        11,
              "y":        12
            },
            {
              "x":        11,
              "y":        14
            },
            {
              "x":        13,
              "y":        14
            }
          ],
          "actual":{
            "x":0.85,
            "y":0.237175080147781
          }
        },
        {
          "datasetName":"pointBot",
          "datapointId":    0,
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
          "actual":{
            "x":0.239949555687728,
            "y":0.229429701192818
          }
        },
        {
          "datasetName":"pointBot",
          "datapointId":    0,
          "horizontal":    false,
          "directDims":[
            {
              "x":        15,
              "y":        16
            },
            {
              "x":        17,
              "y":        18
            }
          ],
          "commonDims":[
            {
              "x":        15,
              "y":        16
            },
            {
              "x":        15,
              "y":        18
            },
            {
              "x":        17,
              "y":        18
            }
          ],
          "actual":{
            "x":0.15,
            "y":0.239949555687728
          }
        },
        {
          "datasetName":"pointBot",
          "datapointId":    0,
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
          "actual":{
            "x":0.21563927182211,
            "y":0.250456388520905
          }
        },
        {
          "datasetName":"pointBot",
          "datapointId":    0,
          "horizontal":    false,
          "directDims":[
            {
              "x":        19,
              "y":        20
            },
            {
              "x":        21,
              "y":        22
            }
          ],
          "commonDims":[
            {
              "x":        19,
              "y":        20
            },
            {
              "x":        19,
              "y":        22
            },
            {
              "x":        21,
              "y":        22
            }
          ],
          "actual":{
            "x":0.15,
            "y":0.21563927182211
          }
        }
      ],
};

const sp = window.sp || {};
sp.PointBot = PointBot;
window.sp = sp;
}
