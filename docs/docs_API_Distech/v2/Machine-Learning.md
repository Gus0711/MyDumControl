# API V2 — Machine-Learning

Chemins relatifs à `https://<hôte>/api/rest/v2` sauf mention contraire. Auth : Basic. Voir [INDEX](../INDEX.md).

## Thermal Sensor

#### People Count
`GET /services/machine-learning/thermal-sensor/people-count`

#### Presence Detection
`GET /services/machine-learning/thermal-sensor/presence-detection`

#### Max-Age
`GET /services/machine-learning/thermal-sensor/max-age`

#### Min Consecutive Detections
`GET /services/machine-learning/thermal-sensor/min-consecutive-detections`

#### IOU Filter Threshold
`GET /services/machine-learning/thermal-sensor/iou-filter-threshold`

#### Counting Zone
`GET /services/machine-learning/thermal-sensor/counting-zone`

#### Counting Zone
`POST /services/machine-learning/thermal-sensor/counting-zone`

Corps :
```json
{
  "$value": [
    248,
    0,
    0,
    "… 21 autres éléments"
  ]
}
```

#### Min Score
`GET /services/machine-learning/thermal-sensor/min-score`

#### Min Score
`POST /services/machine-learning/thermal-sensor/min-score`

Corps :
```json
{
  "$value": 0.5
}
```

## Machine-Learning

#### Machine-Learning
`GET /services/machine-learning`

#### Thermal-Sensor
`GET /services/machine-learning/thermal-sensor`

#### Save IR-Frame
`POST /services/machine-learning/thermal-sensor/save-irframe`
