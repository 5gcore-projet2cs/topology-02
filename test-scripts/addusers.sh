#!/bin/sh

LOGIN_URL="http://localhost:5000/api/login"
ADMIN_USER=admin
ADMIN_PASS=free5gc

get_access_token() {
  echo "Logging in to get the access token..."
  response=$(curl -s -X POST "$LOGIN_URL" \
    -H "Content-Type: application/json" \
    -d "{\"username\": \"${ADMIN_USER}\", \"password\": \"${ADMIN_PASS}\"}")

  access_token=$(echo "$response" | jq -r '.access_token')
  echo "Access token retrieved successfully."
}

get_access_token

MNC=93
SUBSCRIBER_URL="http://localhost:5000/api/subscriber"

for i in $(seq 1 6); do
  IMSI=$(printf "%03d" "$i")
  UE_ID="imsi-208${MNC}0000000${IMSI}"

  echo "Adding subscriber $UE_ID..."

  curl -s -X POST "$SUBSCRIBER_URL/$UE_ID/208${MNC}" \
    -H "Content-Type: application/json" \
    -H "Token: $access_token" \
    -d @- <<EOF
{
  "userNumber": $i,
  "ueId": "$UE_ID",
  "plmnID": "208$MNC",
  "AuthenticationSubscription": {
    "authenticationMethod": "5G_AKA",
    "permanentKey": {
      "permanentKeyValue": "8baf473f2f8fd09487cccbd7097c6862",
      "encryptionKey": 0,
      "encryptionAlgorithm": 0
    },
    "sequenceNumber": "000000000023",
    "authenticationManagementField": "8000",
    "milenage": {
      "op": {
        "opValue": "",
        "encryptionKey": 0,
        "encryptionAlgorithm": 0
      }
    },
    "opc": {
      "opcValue": "8e27b6af0e692e750f32667a3b14605d",
      "encryptionKey": 0,
      "encryptionAlgorithm": 0
    }
  },
  "AccessAndMobilitySubscriptionData": {
    "gpsis": ["msisdn-"],
    "subscribedUeAmbr": {
      "uplink": "1 Gbps",
      "downlink": "2 Gbps"
    },
    "nssai": {
      "defaultSingleNssais": [{"sst": 1, "sd": "010203"}],
      "singleNssais": [{"sst": 1, "sd": "112233"}]
    }
  },
  "SessionManagementSubscriptionData": [
    {
      "singleNssai": {"sst": 1, "sd": "010203"},
      "dnnConfigurations": {
        "internet": {
          "pduSessionTypes": {
            "defaultSessionType": "IPV4",
            "allowedSessionTypes": ["IPV4"]
          },
          "sscModes": {
            "defaultSscMode": "SSC_MODE_1",
            "allowedSscModes": ["SSC_MODE_2", "SSC_MODE_3"]
          },
          "5gQosProfile": {
            "5qi": 9,
            "arp": {
              "priorityLevel": 8,
              "preemptCap": "",
              "preemptVuln": ""
            },
            "priorityLevel": 8
          },
          "sessionAmbr": {
            "uplink": "1000 Mbps",
            "downlink": "1000 Mbps"
          },
          "staticIpAddress": []
        }
      }
    },
    {
      "singleNssai": {"sst": 1, "sd": "112233"},
      "dnnConfigurations": {
        "internet": {
          "pduSessionTypes": {
            "defaultSessionType": "IPV4",
            "allowedSessionTypes": ["IPV4"]
          },
          "sscModes": {
            "defaultSscMode": "SSC_MODE_1",
            "allowedSscModes": ["SSC_MODE_2", "SSC_MODE_3"]
          },
          "5gQosProfile": {
            "5qi": 8,
            "arp": {
              "priorityLevel": 8,
              "preemptCap": "",
              "preemptVuln": ""
            },
            "priorityLevel": 8
          },
          "sessionAmbr": {
            "uplink": "1000 Mbps",
            "downlink": "1000 Mbps"
          },
          "staticIpAddress": []
        }
      }
    }
  ],
  "SmfSelectionSubscriptionData": {
    "subscribedSnssaiInfos": {
      "01010203": {
        "dnnInfos": [{"dnn": "internet"}]
      },
      "01112233": {
        "dnnInfos": [{"dnn": "internet"}]
      }
    }
  },
  "AmPolicyData": {
    "subscCats": ["free5gc"]
  },
  "SmPolicyData": {
    "smPolicySnssaiData": {
      "01010203": {
        "snssai": {"sst": 1, "sd": "010203"},
        "smPolicyDnnData": {
          "internet": {"dnn": "internet"}
        }
      },
      "01112233": {
        "snssai": {"sst": 1, "sd": "112233"},
        "smPolicyDnnData": {
          "internet": {"dnn": "internet"}
        }
      }
    }
  },
  "FlowRules": [
    {
      "filter": "1.1.1.1/32",
      "precedence": 128,
      "snssai": "01010203",
      "dnn": "internet",
      "qosRef": 1
    },
    {
      "filter": "1.1.1.1/32",
      "precedence": 127,
      "snssai": "01112233",
      "dnn": "internet",
      "qosRef": 2
    }
  ],
  "QosFlows": [
    {
      "snssai": "01010203",
      "dnn": "internet",
      "qosRef": 1,
      "5qi": 8,
      "mbrUL": "208 Mbps",
      "mbrDL": "208 Mbps",
      "gbrUL": "108 Mbps",
      "gbrDL": "108 Mbps"
    },
    {
      "snssai": "01112233",
      "dnn": "internet",
      "qosRef": 2,
      "5qi": 7,
      "mbrUL": "407 Mbps",
      "mbrDL": "407 Mbps",
      "gbrUL": "207 Mbps",
      "gbrDL": "207 Mbps"
    }
  ],
  "ChargingDatas": [
    {
      "chargingMethod": "Offline",
      "quota": "100000",
      "unitCost": "1",
      "snssai": "01010203",
      "dnn": "",
      "filter": ""
    },
    {
      "chargingMethod": "Offline",
      "quota": "100000",
      "unitCost": "1",
      "snssai": "01010203",
      "dnn": "internet",
      "filter": "1.1.1.1/32",
      "qosRef": 1
    },
    {
      "chargingMethod": "Online",
      "quota": "100000",
      "unitCost": "1",
      "snssai": "01112233",
      "dnn": "",
      "filter": ""
    },
    {
      "chargingMethod": "Online",
      "quota": "5000",
      "unitCost": "1",
      "snssai": "01112233",
      "dnn": "internet",
      "filter": "1.1.1.1/32",
      "qosRef": 2
    }
  ]
}
EOF
done

