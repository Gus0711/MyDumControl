# API V1 — Protocols

Chemins relatifs à `https://<hôte>/api/rest/v1`. Auth : Basic. API legacy, préférer la V2. Voir [INDEX](../INDEX.md).

## BACnet › Communication › Network › MSTP › ID

#### mstp-ports-id
`GET /protocols/bacnet/communication/network/mstp-ports/1`

http://eclypseapi.distech-controls.com/restApi/bacnet/resources/1037/GET

GET /protocols/bacnet/communication/network/mstp-ports/{id}

This resource allows you to view and to set the MS/TP network configuration parameters.

#### mstp-ports-id
`POST /protocols/bacnet/communication/network/mstp-ports/1`

http://eclypseapi.distech-controls.com/restApi/bacnet/resources/1037/POST

POST /protocols/bacnet/communication/network/mstp-ports/{id}

This resource allows you to view and to set the MS/TP network configuration parameters.

{
  "enabled": false,
  "networkNumber": 6,
  "baudRate": 38400,
  "macAddress": 0,
  "maxMaster": 127,
  "maxInfoFrame": 3
}

Corps :
```json
{
  "enabled": true,
  "networkNumber": 16,
  "baudRate": 38400,
  "macAddress": 0,
  "maxMaster": 127,
  "maxInfoFrame": 21
}
```

## BACnet › Communication › Network › MSTP

#### mstp-ports
`GET /protocols/bacnet/communication/network/mstp-ports`

http://eclypseapi.distech-controls.com/restApi/bacnet/resources/1036/GET

GET /protocols/bacnet/communication/network/mstp-ports

This resource lists all BACnet MS/TP ports.

## BACnet › Communication › Network › IP › ID › BBMD › ID

#### bbmd-Id
`GET /protocols/bacnet/communication/network/ip-ports/1/bbmd-list/1`

http://eclypseapi.distech-controls.com/restApi/bacnet/resources/1041/GET

GET /protocols/bacnet/communication/network/ip-ports/{id}/bbmd-list/{bbmdId}

#### bbmd-Id
`DELETE /protocols/bacnet/communication/network/ip-ports/1/bbmd-list/1`

http://eclypseapi.distech-controls.com/restApi/bacnet/resources/1041/DELETE

DELETE /protocols/bacnet/communication/network/ip-ports/{id}/bbmd-list/{bbmdId}

This is the details of a specific BBMD.

No body is needed.

#### bbmd-Id
`PUT /protocols/bacnet/communication/network/ip-ports/1/bbmd-list/1`

http://eclypseapi.distech-controls.com/restApi/bacnet/resources/1041/PUT

PUT /protocols/bacnet/communication/network/ip-ports/{id}/bbmd-list/{bbmdId}

This is the details of a specific BBMD.

This method is used to edit a BBMD.
All fields are required.

{
  "ip": "192.168.1.1",
  "port": 47807,
  "mask": "255.255.252.0"
}

Corps :
```json
{
  "ip": "10.222.101.50",
  "port": 47808,
  "mask": "255.255.252.254"
}
```

## BACnet › Communication › Network › IP › ID › BBMD

#### bbmd-list
`GET /protocols/bacnet/communication/network/ip-ports/1/bbmd-list`

http://eclypseapi.distech-controls.com/restApi/bacnet/resources/1040/GET

GET /protocols/bacnet/communication/network/ip-ports/{id}/bbmd-list

This resource lists all the BBMD-enabled controllers located on other subnetworks.

BACnet/IP devices send broadcast discovery messages such as “Who-Is” as a means to discover other BACnet devices on the network. However, when there are two or more BACnet/IP subnetworks, broadcast messages do not pass through network routers that separate these subnetworks.
BBMD allows broadcast message to pass through a router: on each subnet, a single device has BBMD enabled. Each BBMD device ensures BACnet/IP connectivity between subnets by forwarding broadcast messages found on its subnetwork to each other, and then onto the local subnetwork as a broadcast message.

#### bbmd-list
`POST /protocols/bacnet/communication/network/ip-ports/1/bbmd-list`

http://eclypseapi.distech-controls.com/restApi/bacnet/resources/1040/POST

POST /protocols/bacnet/communication/network/ip-ports/{id}/bbmd-list

This resource lists all the BBMD-enabled controllers located on other subnetworks.

BACnet/IP devices send broadcast discovery messages such as “Who-Is” as a means to discover other BACnet devices on the network. However, when there are two or more BACnet/IP subnetworks, broadcast messages do not pass through network routers that separate these subnetworks.
BBMD allows broadcast message to pass through a router: on each subnet, a single device has BBMD enabled. Each BBMD device ensures BACnet/IP connectivity between subnets by forwarding broadcast messages found on its subnetwork to each other, and then onto the local subnetwork as a broadcast message.

All properties are required.

If the request is successful, the server responds with an Http Code 201 Created.


{
  "ip": "1.1.1.1",
  "port": 47807,
  "mask": "255.255.252.0"
}

Corps :
```json
{
  "ip": "10.222.101.50",
  "port": 47808,
  "mask": "255.255.252.255"
}
```

## BACnet › Communication › Network › IP › ID › Foreign-Devices

#### IP Port {ID} FDevice List
`GET /protocols/bacnet/communication/network/ip-ports/1/foreign-devices`

http://eclypseapi.distech-controls.com/restApi/bacnet/resources/1042/GET

GET /protocols/bacnet/communication/network/ip-ports/{id}/foreign-devices

Some BACnet/IP devices also support a feature called Foreign Device Registration (FDR). FDR allows a BACnet/IP device to send broadcast messages to a device with BBMD enabled. The BBMD-enabled device will then forward these broadcast messages to all other BBMDs and onto all other FDR devices. If a subnet has only FDR supported devices then it does not need a local BBMD. These devices can register directly with a BBMD on another subnetwork.

#### IP Port {ID} FDevice {ID} Config
`GET /protocols/bacnet/communication/network/ip-ports/1/foreign-devices/1`

http://eclypseapi.distech-controls.com/restApi/bacnet/resources/1043/GET

GET /protocols/bacnet/communication/network/ip-ports/{id}/foreign-devices/{foreignDeviceId}

This resource shows the details of a specific foreign device.

## BACnet › Communication › Network › IP › ID

#### ip-ports-id
`GET /protocols/bacnet/communication/network/ip-ports/1`

http://eclypseapi.distech-controls.com/restApi/bacnet/resources/1039/GET

GET /protocols/bacnet/communication/network/ip-ports/{id}

This resource allows you to view and set the IP network configuration parameters including BACnet Broadcast Management Device (BBMD) and Foreign Device for intranetwork connectivity.

#### ip-ports-id
`POST /protocols/bacnet/communication/network/ip-ports/1`

http://eclypseapi.distech-controls.com/restApi/bacnet/resources/1039/POST

POST /protocols/bacnet/communication/network/ip-ports/{id}

This resource allows you to view and set the IP network configuration parameters including BACnet Broadcast Management Device (BBMD) and Foreign Device for intranetwork connectivity.

{
  "enabled": true,
  "networkNumber": 0,
  "bacnetIpUdpPort": 47809,
  "enabledBbmd": true,
  "enabledForeignDevice": false
}

Corps :
```json
{
  "enabledBbmd": true,
  "enabledForeignDevice": false
}
```

## BACnet › Communication › Network › IP

#### ip-ports
`GET /protocols/bacnet/communication/network/ip-ports`

http://eclypseapi.distech-controls.com/restApi/bacnet/resources/1038/GET#

## BACnet › Communication › Network › Router-Entries › Number

#### networkNumber
`GET /protocols/bacnet/communication/network/router-entries/22202`

http://eclypseapi.distech-controls.com/restApi/bacnet/resources/1076/GET

GET /protocols/bacnet/communication/network/router-entries/{networkNumber}

This resource prints all the details about a routing value.

## BACnet › Communication › Network › Router-Entries

#### router-entries
`GET /protocols/bacnet/communication/network/router-entries`

http://eclypseapi.distech-controls.com/restApi/bacnet/resources/1075/GET

GET /protocols/bacnet/communication/network/router-entries

This resource list all the value include in the routing table.

## BACnet › Communication › Network

#### network
`GET /protocols/bacnet/communication/network`

http://eclypseapi.distech-controls.com/restApi/bacnet/resources/1035/GET

This resource allows you to enable the routing of BACnet packets between BACnet MS/TP controllers connected to the ECLYPSE Controller’s RS-485 port and other IP-connected controllers (for example, BACnet/IP controllers connected to the ECLYPSE Controller’s Ethernet Switch ports or controllers connected through Wi-Fi). For example, routing must be enabled for EC-NetAX to discover the BACnet MS/TP controllers connected to the ECLYPSE Connected System Controller’s RS-485 port.

#### network
`POST /protocols/bacnet/communication/network`

http://eclypseapi.distech-controls.com/restApi/bacnet/resources/1035/POST

This resource allows you to enable the routing of BACnet packets between BACnet MS/TP controllers connected to the ECLYPSE Controller’s RS-485 port and other IP-connected controllers (for example, BACnet/IP controllers connected to the ECLYPSE Controller’s Ethernet Switch ports or controllers connected through Wi-Fi). For example, routing must be enabled for EC-NetAX to discover the BACnet MS/TP controllers connected to the ECLYPSE Connected System Controller’s RS-485 port.

Corps :
```json
{
  "enabled": true
}
```

## BACnet › Communication

#### communication
`GET /protocols/bacnet/communication`

http://eclypseapi.distech-controls.com/restApi/bacnet/resources/1034/GET

#### local
`GET /protocols/bacnet/local`

GET /protocols/bacnet/local

Resource URL: https://{deviceIP}/api/rest/v1/protocols/bacnet/local

Documentation: http://eclypseapi.distech-controls.com/restApi/bacnet/resources/1022/GET

## BACnet › Local › Objects › Calendar

#### date-list
`GET /protocols/bacnet/local/objects/calendar/1/properties/date-list`

http://eclypseapi.distech-controls.com/restApi/bacnet/resources/1023/GET

GET /protocols/bacnet/local/objects

These objects represent physical inputs, outputs, and values used by and coming from software processes.

This resource lists all of the current objects on the device.

#### date-list
`POST /protocols/bacnet/local/objects/calendar/1/properties/date-list`

http://eclypseapi.distech-controls.com/restApi/bacnet/resources/1023/GET

GET /protocols/bacnet/local/objects

These objects represent physical inputs, outputs, and values used by and coming from software processes.

This resource lists all of the current objects on the device.

Corps :
```json
{
  "value": [
    {
      "type": "simpleDate",
      "simpleDate": {
        "date": "2024-2-1",
        "dayOfWeek": "***"
      }
    },
    {
      "type": "dateRange",
      "dateRange": {
        "startDate": "2019-2-2",
        "endDate": "2026-2-22"
      }
    },
    {
      "type": "weekAndDay",
      "weekAndDay": {
        "month": "August",
        "dayOfWeek": "***",
        "week": 1
      }
    }
  ]
}
```

## BACnet › Local › Objects › Clear

#### clear-values
`POST /protocols/bacnet/local/objects/clear-values`

http://eclypseapi.distech-controls.com/restApi/bacnet/resources/1023/GET

GET /protocols/bacnet/local/objects

These objects represent physical inputs, outputs, and values used by and coming from software processes.

This resource lists all of the current objects on the device.

## BACnet › Local › Objects › ObjectType › ObjectInstance › Properties › Name

#### propertyName
`GET /protocols/bacnet/local/objects/analog-value/1/properties/objectName`

This resource shows all the elements concerning a specific BACnet property and particularly the **value** attribute.

&nbsp;

## Resource Information:

* URL:  **https://{deviceIP}/api/rest/v1/protocols/bacnet/local/objects/{objectType}/{objectInstance}/properties/{propertyName}** 
* Support Query Parameter? **YES** 
* Requires Authentication? **YES** 

&nbsp;

## Parameters

### encode (optional) 

Used when you are operating a browser without access to the header parameter. This allows you to choose which encoding you want to use for the response:
* json
* xml 
* text
* bin

All these resources can be used according what the resource allows.

* <span style="color:darkred">Located in : </span> **Query**
* <span style="color:darkred">Example values : </span> **encode=json**

&nbsp;

### accept (optional) 

If this parameter is not in the request, the **Application/Json** will be chosen by default.
There are multiple possible values (according the resource): 
* Application/Json 
* Application/Xml 
* Application/Octet-stream
* Text/Plain

The first two are the most often used.

* <span style="color:darkred">Located in : </span> **Header**
* <span style="color:darkred">Example values : </span> **accept:application/json**

&nbsp;

### objectType (required)

This is the object type string value.

* <span style="color:darkred">Located in : </span> **Path**
* <span style="color:darkred">Example values : </span> **analog-value**

&nbsp;

### objectInstance (required)

This is the instance of a specific BACnet object type.

* <span style="color:darkred">Located in : </span> **Path**
* <span style="color:darkred">Example values : </span> **1**

&nbsp;

### propertyName (required)

This is the name of the property.

* <span style="color:darkred">Located in : </span> **Path**
* <span style="color:darkred">Example values : </span> **object-name**

&nbsp;

## Object(s) Representation

<span style="color:darkred">Object Name: </span>**BacnetProperty** 

| Property Name | Type | Description | Method |
| --- | :---: | --- | :---: |
| **Name** | String | This property is the name of the BACnet property. | <span style="color:green">GET</span> |   
| **IsArray**  | Boolean | This property indicates if the BACnet property is an array or not. | <span style="color:green">GET</span> |   
| **Implementation** | String |  | <span style="color:green">GET</span> |   
| **AsnValue**  | String | This property is the ASN value of a BACnet property encoded in Base64. | <span style="color:green">GET</span> |   
| **Value** <br/> required | String | This property is the readable value of a BACnet property. <br/>According the  BACnet property, it's possible the type of this property vary. (See the description of the resource for more details) | <span style="color:green">GET</span> <br/> <span style="color:orange">POST</span> | 


&nbsp;

## Example Body Response

### <span style="color:darkblue">Application/Json</span>


URL Example: https://0.0.0.0/api/rest/v1/protocols/bacnet/local/objects/analog-value/1/properties/object-name

```json

{
  "value": "VUBH_2AS01BOWW509PC22_U_",
  "asnValue": "dRkAVlVCSF8yQVMwMUJPV1c1MDlQQzIyX1Vf",
  "isArray": false,
  "implementation": "",
  "name": "objectName"
}

```

&nbsp;

### <span style="color:darkblue">Application/Xml</span>

URL Example: https://0.0.0.0/api/rest/v1/protocols/bacnet/local/objects/analog-value/1/properties/object-name

```xml

<?xml version="1.0" encoding="utf-8"?>
<BacnetProperty>
	<Name>objectName</Name>
	<IsArray>false</IsArray>
	<Implementation />
	<AsnValue>dRkAVlVCSF8yQVMwMUJPV1c1MDlQQzIyX1Vf</AsnValue>
	<Value>VUBH_2AS01BOWW509PC22_U_</Value>
</BacnetProperty>

```

&nbsp;

#### propertyName
`POST /protocols/bacnet/local/objects/analog-value/1/properties/objectName`

http://eclypseapi.distech-controls.com/restApi/bacnet/resources/1023/GET

GET /protocols/bacnet/local/objects

These objects represent physical inputs, outputs, and values used by and coming from software processes.

This resource lists all of the current objects on the device.

Corps :
```json
{
  "value": "Analog Value 1"
}
```

## BACnet › Local › Objects › ObjectType › ObjectInstance › Properties

#### properties
`GET /protocols/bacnet/local/objects/analog-value/1/properties`

http://eclypseapi.distech-controls.com/restApi/bacnet/resources/1023/GET

GET /protocols/bacnet/local/objects

These objects represent physical inputs, outputs, and values used by and coming from software processes.

This resource lists all of the current objects on the device.

## BACnet › Local › Objects › ObjectType › ObjectInstance › Trend

#### trend
`GET /protocols/bacnet/local/objects/analog-value/1/trend?dataOnly=true`

GET /protocols/bacnet/local/objects/{objectType}

This resource lists all object IDs for a specific object type.

Resource URL: https://{deviceIP}/api/rest/v1/protocols/bacnet/local/objects/{objectType}

Documentation: http://eclypseapi.distech-controls.com/restApi/bacnet/resources/1027/GET

## BACnet › Local › Objects › ObjectType › ObjectInstance

#### objectInstance
`GET /protocols/bacnet/local/objects/analog-value/1`

http://eclypseapi.distech-controls.com/restApi/bacnet/resources/1023/GET

GET /protocols/bacnet/local/objects

These objects represent physical inputs, outputs, and values used by and coming from software processes.

This resource lists all of the current objects on the device.

## BACnet › Local › Objects › ObjectType › Overrides

#### overrides
`GET /protocols/bacnet/local/objects/overrides`

http://eclypseapi.distech-controls.com/restApi/bacnet/resources/1023/GET

GET /protocols/bacnet/local/objects

These objects represent physical inputs, outputs, and values used by and coming from software processes.

This resource lists all of the current objects on the device.

## BACnet › Local › Objects › ObjectType

#### objectType
`GET /protocols/bacnet/local/objects/analog-value`

http://eclypseapi.distech-controls.com/restApi/bacnet/resources/1023/GET

GET /protocols/bacnet/local/objects

These objects represent physical inputs, outputs, and values used by and coming from software processes.

This resource lists all of the current objects on the device.

## BACnet › Local › Objects › ReadPropertyMultiple

#### Priority Array
`POST /protocols/bacnet/local/objects/read-property-multiple`

***
> <span style="color:orange">POST</span> /protocols/bacnet/local/objects/read-property-multiple
{.is-warning}

***

Read multiple points in one request. This reduces
the amount of network traffic required to transmit data.

This resource supports three Content-types:
* Application/Xml
* Application/JSON
* Text/Plain

In the Body request, you need to specify the encoding attributes (*asn or text*).

If you want to view all instances of one specific type use **instance=\"-1\"**.

If you want to view all properties of one specific object use **property=\"all\"**.

Both attributes can be combined.

All fields are <span class=\"small-warning\">required</span> except the **arrayIndex**.

&nbsp;
## Resource Information:

* URL:  **https://{deviceIP}/api/rest/v1/protocols/bacnet/local/objects/read-property-multiple** 
* Support Query Parameter? **NO** 
* Requires Authentication? **YES** 

&nbsp;
## Parameters



### accept (optional) 

If this parameter is not in the request, the **Application/Json** will be chosen by default.
There are multiple possible values (according the resource): 
* Application/Json 
* Application/Xml 
* Application/Octet-stream
* Text/Plain

The first two are the most often used.

* <span style="color:darkred">Located in : </span> **Header**

&nbsp;
* <span style="color:darkred">Example values : </span> **accept:application/json**

&nbsp;
### content-type

There are multiple possible values according the resource: 
* Application/Json 
* Application/Xml 
* Application/Octet-stream
* Text/Plain
* Multipart/Form-data

If this parameter is not present during the request, and error **415 Unsupported Media Type** will be thrown.

* <span style="color:darkred">Located in : </span> **Header**

&nbsp;
* <span style="color:darkred">Example values : </span> **content-type:application/json**

&nbsp;
### content-length

The Content-Length entity-header field indicates the size of the entity-body.

* <span style="color:darkred">Located in : </span> **Header**

&nbsp;
* <span style="color:darkred">Example values : </span> **content-length:526**

&nbsp;

&nbsp;
## Object(s) Representation

<span style="color:darkred">Object Name: </span>**ReadPropertyMultiple** 

| propertyName|type|description|post|
|  --- |  --- |  --- |  --- | 
| **encode**  | String | This property is used to indicate which type is needed to recover the values, or the type you are writing the values from/in the device :
* text
* asn
 | <span style="color:orange">POST</span> | 
**PropertyReferences**  | Array<PropertyReference> | This object is an array of PropertyReference object. | <span style="color:orange">POST</span> | 

<span style="color:darkred">Object Name: </span>**PropertyReference** 

| propertyName|type|description|post|
|  --- |  --- |  --- |  --- | 
| **Type**  | <td> | This property is the name of the object type. | <span style="color:orange">POST</span> | 
**Instance**  | <td> | This property is the object's instance. | <span style="color:orange">POST</span> | 
**Property**  | <td> | This property is the object's property name | <span style="color:orange">POST</span> | 
**ArrayIndex**  | <td> | This property is the index used to read a table property value.
Use **-1** if there is no array index. | <span style="color:orange">POST</span> | 
**Message**  | String | This property refers to the property value recovered. | <span style="color:orange">POST</span> | 
**Value**  | <td> | This property is used during a write property multiple to write the value. | <span style="color:orange">POST</span> | 


&nbsp;
## Example Body Request

### <span style="color:darkblue">Application/Json</span>



Url Example: https://1.1.1.1/api/rest/v1/protocols/bacnet/local/objects/read-property-multiple

```json

{
  "encode": "asn",
  "propertyReferences": [
    {
      "type": "analogValue",
      "instance": 1,
      "property": "objectName",
      "arrayIndex": -1
    },
    {
      "type": "analogValue",
      "instance": 2,
      "property": "objectName",
      "arrayIndex": -1
    },
    {
      "type": "analogValue",
      "instance": 95959,
      "property": "objectName",
      "arrayIndex": -1
    },
    {
      "type": "analogValue",
      "instance": 4,
      "property": "objectName",
      "arrayIndex": -1
    }
  ]
}

```

&nbsp;
### <span style="color:darkblue">Text/Plain</span>



Url Example: https://1.1.1.1/api/rest/v1/protocols/bacnet/local/objects/read-property-multiple

```

asn
analogValue¤1,2,3¤objectName,presentValue,priorityArray
binaryValue¤-1¤objectName

```

&nbsp;
### <span style="color:darkblue">Application/Xml</span>



Url Example: https://1.1.1.1/api/rest/v1/protocols/bacnet/local/objects/read-property-multiple

```xml

<?xml version="1.0" encoding="utf-8"?>
<PropertyReferences encode="asn">
	<PropertyReference type="analogValue" instance="1" property="objectName" arrayIndex="-1" />
	<PropertyReference type="analogValue" instance="2" property="objectName" arrayIndex="-1" />
	<PropertyReference type="analogValue" instance="95959" property="objectName" arrayIndex="-1" />
	<PropertyReference type="analogValue" instance="4" property="objectName" arrayIndex="-1" />
</PropertyReferences>

```

&nbsp;
## Example Body Response

### <span style="color:darkblue">Application/Json</span>



Url Example: https://1.1.1.1/api/rest/v1/protocols/bacnet/local/objects/read-property-multiple

```json

{
  "encode": "asn",
  "propertyReferences": [
    {
      "type": "analogValue",
      "instance": 1,
      "property": "objectName",
      "arrayIndex": -1
    },
    {
      "type": "analogValue",
      "instance": 2,
      "property": "objectName",
      "arrayIndex": -1
    },
    {
      "type": "analogValue",
      "instance": 95959,
      "property": "objectName",
      "arrayIndex": -1
    },
    {
      "type": "analogValue",
      "instance": 4,
      "property": "objectName",
      "arrayIndex": -1
    }
  ]
}

```



&nbsp;
### <span style="color:darkblue">Application/Xml</span>



Url Example: https://1.1.1.1/api/rest/v1/protocols/bacnet/local/objects/read-property-multiple

```xml

<?xml version="1.0" encoding="utf-8"?>
<PropertyReferences encode="asn">
	<PropertyReference type="analogValue" instance="1" property="objectName" arrayIndex="-1" />
	<PropertyReference type="analogValue" instance="2" property="objectName" arrayIndex="-1" />
	<PropertyReference type="analogValue" instance="95959" property="objectName" arrayIndex="-1" />
	<PropertyReference type="analogValue" instance="4" property="objectName" arrayIndex="-1" />
</PropertyReferences>

```



&nbsp;
### <span style="color:darkblue">Text/Plain</span>



Url Example: https://1.1.1.1/api/rest/v1/protocols/bacnet/local/objects/read-property-multiple

```

asn
analogValue¤1,2,3¤objectName,presentValue,priorityArray
binaryValue¤-1¤objectName

```
&nbsp;

Corps :
```json
{
  "encode": "text",
  "propertyReferences": [
    {
      "type": "analogValue",
      "instance": -1,
      "property": "priorityArray",
      "arrayIndex": -1
    },
    {
      "type": "binaryValue",
      "instance": -1,
      "property": "priorityArray",
      "arrayIndex": -1
    },
    {
      "type": "multistateValue",
      "instance": -1,
      "property": "priorityArray",
      "arrayIndex": -1
    },
    "… 1 autres éléments"
  ]
}
```

## BACnet › Local › Objects › WritePropertyMultiple

#### Priority Array
`POST /protocols/bacnet/local/objects/write-property-multiple`

Read multiple points in one request. This reduces
the amount of network traffic required to transmit data.

http://eclypseapi.distech-controls.com/restApi/bacnet/resources/1024/POST

Corps :
```json
{
  "encode": "text",
  "propertyReferences": [
    {
      "type": "analogValue",
      "instance": 1,
      "property": "presentValue",
      "priority": 8,
      "value": "Null"
    }
  ]
}
```

## BACnet › Local › Objects › Schedule

#### weekly-schedule
`GET /protocols/bacnet/local/objects/schedule/1/properties/weekly-schedule`

http://eclypseapi.distech-controls.com/restApi/bacnet/resources/1023/GET

GET /protocols/bacnet/local/objects

These objects represent physical inputs, outputs, and values used by and coming from software processes.

This resource lists all of the current objects on the device.

#### exception-schedule
`GET /protocols/bacnet/local/objects/schedule/1/properties/exception-schedule`

http://eclypseapi.distech-controls.com/restApi/bacnet/resources/1023/GET

GET /protocols/bacnet/local/objects

These objects represent physical inputs, outputs, and values used by and coming from software processes.

This resource lists all of the current objects on the device.

#### weekly-schedule
`POST /protocols/bacnet/local/objects/schedule/1/properties/weekly-schedule`

http://eclypseapi.distech-controls.com/restApi/bacnet/resources/1023/GET

GET /protocols/bacnet/local/objects

These objects represent physical inputs, outputs, and values used by and coming from software processes.

This resource lists all of the current objects on the device.

Corps :
```json
{
  "value": [
    {
      "timeValues": [
        {
          "value": 2,
          "type": "enumerated",
          "time": "08:00:00.00"
        },
        {
          "value": null,
          "type": "null",
          "time": "09:00:00.00"
        },
        {
          "value": 4,
          "type": "enumerated",
          "time": "14:00:00.00"
        },
        "… 1 autres éléments"
      ]
    }
  ]
}
```

#### exception-schedule
`POST /protocols/bacnet/local/objects/schedule/1/properties/exception-schedule`

http://eclypseapi.distech-controls.com/restApi/bacnet/resources/1023/GET

GET /protocols/bacnet/local/objects

These objects represent physical inputs, outputs, and values used by and coming from software processes.

This resource lists all of the current objects on the device.

Corps :
```json
{
  "value": [
    {
      "type": "dateRange",
      "dateRange": {
        "timeValues": [
          {
            "value": 2,
            "type": "enumerated",
            "time": "09:00:00.00"
          },
          {
            "value": null,
            "type": "null",
            "time": "13:00:00.00"
          }
        ],
        "startDate": "*-*-*",
        "endDate": "*-*-*"
      }
    },
    {
      "type": "weekAndDay",
      "weekAndDay": {
        "timeValues": [
          {
            "value": 4,
            "type": "enumerated",
            "time": "12:00:00.00"
          },
          {
            "value": null,
            "type": "null",
            "time": "14:00:00.00"
          }
        ],
        "month": "***",
        "dayOfWeek": "***",
        "week": 255
      }
    },
    {
      "type": "simpleDate",
      "simpleDate": {
        "timeValues": [
          {
            "value": 1,
            "type": "enumerated",
            "time": "07:00:00.00"
          },
          {
            "value": null,
            "type": "null",
            "time": "10:00:00.00"
          }
        ],
        "date": "*-*-1",
        "dayOfWeek": "***"
      }
    },
    "… 1 autres éléments"
  ]
}
```

## BACnet › Local › Objects

#### objects
`GET /protocols/bacnet/local/objects`

http://eclypseapi.distech-controls.com/restApi/bacnet/resources/1023/GET

GET /protocols/bacnet/local/objects

These objects represent physical inputs, outputs, and values used by and coming from software processes.

This resource lists all of the current objects on the device.

## BACnet › Local › Management › Reinitializable

#### reinitializable
`POST /protocols/bacnet/local/management/{reinitializable}/`

http://eclypseapi.distech-controls.com/restApi/bacnet/resources/1023/GET

GET /protocols/bacnet/local/objects

These objects represent physical inputs, outputs, and values used by and coming from software processes.

This resource lists all of the current objects on the device.

## BACnet › Local › Event-Notifications › UUID

#### uuid
`GET /protocols/bacnet/local/event-notifications/1d794037-b0dc-47c2-b5b5-1609e3725736/`

http://eclypseapi.distech-controls.com/restApi/bacnet/resources/1023/GET

GET /protocols/bacnet/local/objects

These objects represent physical inputs, outputs, and values used by and coming from software processes.

This resource lists all of the current objects on the device.

## BACnet › Local › Event-Notifications

#### event-notifications
`GET /protocols/bacnet/local/event-notifications`

http://eclypseapi.distech-controls.com/restApi/bacnet/resources/1023/GET

GET /protocols/bacnet/local/objects

These objects represent physical inputs, outputs, and values used by and coming from software processes.

This resource lists all of the current objects on the device.

## BACnet › Local

#### local
`GET /protocols/bacnet/local`

http://eclypseapi.distech-controls.com/restApi/bacnet/resources/1023/GET

GET /protocols/bacnet/local/objects

These objects represent physical inputs, outputs, and values used by and coming from software processes.

This resource lists all of the current objects on the device.

## BACnet › Remote › Devices › ID › Objects › Discovery

#### start-discovery
`POST /protocols/bacnet/remote/devices/52001/objects/start-discovery`

http://eclypseapi.distech-controls.com/restApi/bacnet/resources/1023/GET

GET /protocols/bacnet/local/objects

These objects represent physical inputs, outputs, and values used by and coming from software processes.

This resource lists all of the current objects on the device.

Corps :
```json
{
  "forceUpdate": false,
  "aliveTimeout": 1000
}
```

## BACnet › Remote › Devices › ID › Objects › ObjectType › ObjectInstance › Properties › Name

#### propertyName
`GET /protocols/bacnet/remote/devices/52001/objects/analog-value/1/properties/objectName`

http://eclypseapi.distech-controls.com/restApi/bacnet/resources/1023/GET

GET /protocols/bacnet/local/objects

These objects represent physical inputs, outputs, and values used by and coming from software processes.

This resource lists all of the current objects on the device.

#### propertyName
`POST /protocols/bacnet/remote/devices/52001/objects/analog-value/1/properties/objectName`

http://eclypseapi.distech-controls.com/restApi/bacnet/resources/1023/GET

GET /protocols/bacnet/local/objects

These objects represent physical inputs, outputs, and values used by and coming from software processes.

This resource lists all of the current objects on the device.

Corps :
```json
{
  "value": "AV1"
}
```

## BACnet › Remote › Devices › ID › Objects › ObjectType › ObjectInstance › Properties

#### properties
`GET /protocols/bacnet/remote/devices/52001/objects/analog-value/1/properties`

http://eclypseapi.distech-controls.com/restApi/bacnet/resources/1023/GET

GET /protocols/bacnet/local/objects

These objects represent physical inputs, outputs, and values used by and coming from software processes.

This resource lists all of the current objects on the device.

## BACnet › Remote › Devices › ID › Objects › ObjectType › ObjectInstance

#### objectInstance
`GET /protocols/bacnet/remote/devices/52001/objects/analog-value/1`

http://eclypseapi.distech-controls.com/restApi/bacnet/resources/1023/GET

GET /protocols/bacnet/local/objects

These objects represent physical inputs, outputs, and values used by and coming from software processes.

This resource lists all of the current objects on the device.

## BACnet › Remote › Devices › ID › Objects › ObjectType

#### objectsType
`GET /protocols/bacnet/remote/devices/52001/objects/analog-value`

http://eclypseapi.distech-controls.com/restApi/bacnet/resources/1023/GET

GET /protocols/bacnet/local/objects

These objects represent physical inputs, outputs, and values used by and coming from software processes.

This resource lists all of the current objects on the device.

## BACnet › Remote › Devices › ID › Objects › ReadPropertyMultiple

#### read-property-multiple
`POST /protocols/bacnet/remote/devices/52001/objects/read-property-multiple`

***
> <span style="color:orange">POST</span> /protocols/bacnet/local/objects/read-property-multiple
{.is-warning}

***

Read multiple points in one request. This reduces
the amount of network traffic required to transmit data.

This resource supports three Content-types:
* Application/Xml
* Application/JSON
* Text/Plain

In the Body request, you need to specify the encoding attributes (*asn or text*).

If you want to view all instances of one specific type use **instance=\"-1\"**.

If you want to view all properties of one specific object use **property=\"all\"**.

Both attributes can be combined.

All fields are <span class=\"small-warning\">required</span> except the **arrayIndex**.

&nbsp;
## Resource Information:

* URL:  **https://{deviceIP}/api/rest/v1/protocols/bacnet/local/objects/read-property-multiple** 
* Support Query Parameter? **NO** 
* Requires Authentication? **YES** 

&nbsp;
## Parameters



### accept (optional) 

If this parameter is not in the request, the **Application/Json** will be chosen by default.
There are multiple possible values (according the resource): 
* Application/Json 
* Application/Xml 
* Application/Octet-stream
* Text/Plain

The first two are the most often used.

* <span style="color:darkred">Located in : </span> **Header**

&nbsp;
* <span style="color:darkred">Example values : </span> **accept:application/json**

&nbsp;
### content-type

There are multiple possible values according the resource: 
* Application/Json 
* Application/Xml 
* Application/Octet-stream
* Text/Plain
* Multipart/Form-data

If this parameter is not present during the request, and error **415 Unsupported Media Type** will be thrown.

* <span style="color:darkred">Located in : </span> **Header**

&nbsp;
* <span style="color:darkred">Example values : </span> **content-type:application/json**

&nbsp;
### content-length

The Content-Length entity-header field indicates the size of the entity-body.

* <span style="color:darkred">Located in : </span> **Header**

&nbsp;
* <span style="color:darkred">Example values : </span> **content-length:526**

&nbsp;

&nbsp;
## Object(s) Representation

<span style="color:darkred">Object Name: </span>**ReadPropertyMultiple** 

| propertyName|type|description|post|
|  --- |  --- |  --- |  --- | 
| **encode**  | String | This property is used to indicate which type is needed to recover the values, or the type you are writing the values from/in the device :
* text
* asn
 | <span style="color:orange">POST</span> | 
**PropertyReferences**  | Array<PropertyReference> | This object is an array of PropertyReference object. | <span style="color:orange">POST</span> | 

<span style="color:darkred">Object Name: </span>**PropertyReference** 

| propertyName|type|description|post|
|  --- |  --- |  --- |  --- | 
| **Type**  | <td> | This property is the name of the object type. | <span style="color:orange">POST</span> | 
**Instance**  | <td> | This property is the object's instance. | <span style="color:orange">POST</span> | 
**Property**  | <td> | This property is the object's property name | <span style="color:orange">POST</span> | 
**ArrayIndex**  | <td> | This property is the index used to read a table property value.
Use **-1** if there is no array index. | <span style="color:orange">POST</span> | 
**Message**  | String | This property refers to the property value recovered. | <span style="color:orange">POST</span> | 
**Value**  | <td> | This property is used during a write property multiple to write the value. | <span style="color:orange">POST</span> | 


&nbsp;
## Example Body Request

### <span style="color:darkblue">Application/Json</span>



Url Example: https://1.1.1.1/api/rest/v1/protocols/bacnet/local/objects/read-property-multiple

```json

{
  "encode": "asn",
  "propertyReferences": [
    {
      "type": "analogValue",
      "instance": 1,
      "property": "objectName",
      "arrayIndex": -1
    },
    {
      "type": "analogValue",
      "instance": 2,
      "property": "objectName",
      "arrayIndex": -1
    },
    {
      "type": "analogValue",
      "instance": 95959,
      "property": "objectName",
      "arrayIndex": -1
    },
    {
      "type": "analogValue",
      "instance": 4,
      "property": "objectName",
      "arrayIndex": -1
    }
  ]
}

```

&nbsp;
### <span style="color:darkblue">Text/Plain</span>



Url Example: https://1.1.1.1/api/rest/v1/protocols/bacnet/local/objects/read-property-multiple

```

asn
analogValue¤1,2,3¤objectName,presentValue,priorityArray
binaryValue¤-1¤objectName

```

&nbsp;
### <span style="color:darkblue">Application/Xml</span>



Url Example: https://1.1.1.1/api/rest/v1/protocols/bacnet/local/objects/read-property-multiple

```xml

<?xml version="1.0" encoding="utf-8"?>
<PropertyReferences encode="asn">
	<PropertyReference type="analogValue" instance="1" property="objectName" arrayIndex="-1" />
	<PropertyReference type="analogValue" instance="2" property="objectName" arrayIndex="-1" />
	<PropertyReference type="analogValue" instance="95959" property="objectName" arrayIndex="-1" />
	<PropertyReference type="analogValue" instance="4" property="objectName" arrayIndex="-1" />
</PropertyReferences>

```

&nbsp;
## Example Body Response

### <span style="color:darkblue">Application/Json</span>



Url Example: https://1.1.1.1/api/rest/v1/protocols/bacnet/local/objects/read-property-multiple

```json

{
  "encode": "asn",
  "propertyReferences": [
    {
      "type": "analogValue",
      "instance": 1,
      "property": "objectName",
      "arrayIndex": -1
    },
    {
      "type": "analogValue",
      "instance": 2,
      "property": "objectName",
      "arrayIndex": -1
    },
    {
      "type": "analogValue",
      "instance": 95959,
      "property": "objectName",
      "arrayIndex": -1
    },
    {
      "type": "analogValue",
      "instance": 4,
      "property": "objectName",
      "arrayIndex": -1
    }
  ]
}

```



&nbsp;
### <span style="color:darkblue">Application/Xml</span>



Url Example: https://1.1.1.1/api/rest/v1/protocols/bacnet/local/objects/read-property-multiple

```xml

<?xml version="1.0" encoding="utf-8"?>
<PropertyReferences encode="asn">
	<PropertyReference type="analogValue" instance="1" property="objectName" arrayIndex="-1" />
	<PropertyReference type="analogValue" instance="2" property="objectName" arrayIndex="-1" />
	<PropertyReference type="analogValue" instance="95959" property="objectName" arrayIndex="-1" />
	<PropertyReference type="analogValue" instance="4" property="objectName" arrayIndex="-1" />
</PropertyReferences>

```



&nbsp;
### <span style="color:darkblue">Text/Plain</span>



Url Example: https://1.1.1.1/api/rest/v1/protocols/bacnet/local/objects/read-property-multiple

```

asn
analogValue¤1,2,3¤objectName,presentValue,priorityArray
binaryValue¤-1¤objectName

```
&nbsp;

Corps :
```json
{
  "encode": "text",
  "propertyReferences": [
    {
      "type": "analogValue",
      "instance": 1,
      "property": "presentValue",
      "arrayIndex": -1
    },
    {
      "type": "analogValue",
      "instance": 2,
      "property": "presentValue",
      "arrayIndex": -1
    }
  ]
}
```

## BACnet › Remote › Devices › ID › Objects › WritePropertyMultiple

#### write-property-multiple
`POST /protocols/bacnet/remote/devices/52001/objects/write-property-multiple`

***
> <span style="color:orange">POST</span> /protocols/bacnet/local/objects/read-property-multiple
{.is-warning}

***

Read multiple points in one request. This reduces
the amount of network traffic required to transmit data.

This resource supports three Content-types:
* Application/Xml
* Application/JSON
* Text/Plain

In the Body request, you need to specify the encoding attributes (*asn or text*).

If you want to view all instances of one specific type use **instance=\"-1\"**.

If you want to view all properties of one specific object use **property=\"all\"**.

Both attributes can be combined.

All fields are <span class=\"small-warning\">required</span> except the **arrayIndex**.

&nbsp;
## Resource Information:

* URL:  **https://{deviceIP}/api/rest/v1/protocols/bacnet/local/objects/read-property-multiple** 
* Support Query Parameter? **NO** 
* Requires Authentication? **YES** 

&nbsp;
## Parameters



### accept (optional) 

If this parameter is not in the request, the **Application/Json** will be chosen by default.
There are multiple possible values (according the resource): 
* Application/Json 
* Application/Xml 
* Application/Octet-stream
* Text/Plain

The first two are the most often used.

* <span style="color:darkred">Located in : </span> **Header**

&nbsp;
* <span style="color:darkred">Example values : </span> **accept:application/json**

&nbsp;
### content-type

There are multiple possible values according the resource: 
* Application/Json 
* Application/Xml 
* Application/Octet-stream
* Text/Plain
* Multipart/Form-data

If this parameter is not present during the request, and error **415 Unsupported Media Type** will be thrown.

* <span style="color:darkred">Located in : </span> **Header**

&nbsp;
* <span style="color:darkred">Example values : </span> **content-type:application/json**

&nbsp;
### content-length

The Content-Length entity-header field indicates the size of the entity-body.

* <span style="color:darkred">Located in : </span> **Header**

&nbsp;
* <span style="color:darkred">Example values : </span> **content-length:526**

&nbsp;

&nbsp;
## Object(s) Representation

<span style="color:darkred">Object Name: </span>**ReadPropertyMultiple** 

| propertyName|type|description|post|
|  --- |  --- |  --- |  --- | 
| **encode**  | String | This property is used to indicate which type is needed to recover the values, or the type you are writing the values from/in the device :
* text
* asn
 | <span style="color:orange">POST</span> | 
**PropertyReferences**  | Array<PropertyReference> | This object is an array of PropertyReference object. | <span style="color:orange">POST</span> | 

<span style="color:darkred">Object Name: </span>**PropertyReference** 

| propertyName|type|description|post|
|  --- |  --- |  --- |  --- | 
| **Type**  | <td> | This property is the name of the object type. | <span style="color:orange">POST</span> | 
**Instance**  | <td> | This property is the object's instance. | <span style="color:orange">POST</span> | 
**Property**  | <td> | This property is the object's property name | <span style="color:orange">POST</span> | 
**ArrayIndex**  | <td> | This property is the index used to read a table property value.
Use **-1** if there is no array index. | <span style="color:orange">POST</span> | 
**Message**  | String | This property refers to the property value recovered. | <span style="color:orange">POST</span> | 
**Value**  | <td> | This property is used during a write property multiple to write the value. | <span style="color:orange">POST</span> | 


&nbsp;
## Example Body Request

### <span style="color:darkblue">Application/Json</span>



Url Example: https://1.1.1.1/api/rest/v1/protocols/bacnet/local/objects/read-property-multiple

```json

{
  "encode": "asn",
  "propertyReferences": [
    {
      "type": "analogValue",
      "instance": 1,
      "property": "objectName",
      "arrayIndex": -1
    },
    {
      "type": "analogValue",
      "instance": 2,
      "property": "objectName",
      "arrayIndex": -1
    },
    {
      "type": "analogValue",
      "instance": 95959,
      "property": "objectName",
      "arrayIndex": -1
    },
    {
      "type": "analogValue",
      "instance": 4,
      "property": "objectName",
      "arrayIndex": -1
    }
  ]
}

```

&nbsp;
### <span style="color:darkblue">Text/Plain</span>



Url Example: https://1.1.1.1/api/rest/v1/protocols/bacnet/local/objects/read-property-multiple

```

asn
analogValue¤1,2,3¤objectName,presentValue,priorityArray
binaryValue¤-1¤objectName

```

&nbsp;
### <span style="color:darkblue">Application/Xml</span>



Url Example: https://1.1.1.1/api/rest/v1/protocols/bacnet/local/objects/read-property-multiple

```xml

<?xml version="1.0" encoding="utf-8"?>
<PropertyReferences encode="asn">
	<PropertyReference type="analogValue" instance="1" property="objectName" arrayIndex="-1" />
	<PropertyReference type="analogValue" instance="2" property="objectName" arrayIndex="-1" />
	<PropertyReference type="analogValue" instance="95959" property="objectName" arrayIndex="-1" />
	<PropertyReference type="analogValue" instance="4" property="objectName" arrayIndex="-1" />
</PropertyReferences>

```

&nbsp;
## Example Body Response

### <span style="color:darkblue">Application/Json</span>



Url Example: https://1.1.1.1/api/rest/v1/protocols/bacnet/local/objects/read-property-multiple

```json

{
  "encode": "asn",
  "propertyReferences": [
    {
      "type": "analogValue",
      "instance": 1,
      "property": "objectName",
      "arrayIndex": -1
    },
    {
      "type": "analogValue",
      "instance": 2,
      "property": "objectName",
      "arrayIndex": -1
    },
    {
      "type": "analogValue",
      "instance": 95959,
      "property": "objectName",
      "arrayIndex": -1
    },
    {
      "type": "analogValue",
      "instance": 4,
      "property": "objectName",
      "arrayIndex": -1
    }
  ]
}

```



&nbsp;
### <span style="color:darkblue">Application/Xml</span>



Url Example: https://1.1.1.1/api/rest/v1/protocols/bacnet/local/objects/read-property-multiple

```xml

<?xml version="1.0" encoding="utf-8"?>
<PropertyReferences encode="asn">
	<PropertyReference type="analogValue" instance="1" property="objectName" arrayIndex="-1" />
	<PropertyReference type="analogValue" instance="2" property="objectName" arrayIndex="-1" />
	<PropertyReference type="analogValue" instance="95959" property="objectName" arrayIndex="-1" />
	<PropertyReference type="analogValue" instance="4" property="objectName" arrayIndex="-1" />
</PropertyReferences>

```



&nbsp;
### <span style="color:darkblue">Text/Plain</span>



Url Example: https://1.1.1.1/api/rest/v1/protocols/bacnet/local/objects/read-property-multiple

```

asn
analogValue¤1,2,3¤objectName,presentValue,priorityArray
binaryValue¤-1¤objectName

```
&nbsp;

Corps :
```json
{
  "encode": "text",
  "propertyReferences": [
    {
      "type": "analogValue",
      "instance": 1,
      "property": "presentValue",
      "priority": 8,
      "value": "50"
    },
    {
      "type": "analogValue",
      "instance": 2,
      "property": "presentValue",
      "priority": 8,
      "value": "51"
    }
  ]
}
```

## BACnet › Remote › Devices › ID › Objects

#### objects
`GET /protocols/bacnet/remote/devices/52001/objects`

http://eclypseapi.distech-controls.com/restApi/bacnet/resources/1023/GET

GET /protocols/bacnet/local/objects

These objects represent physical inputs, outputs, and values used by and coming from software processes.

This resource lists all of the current objects on the device.

## BACnet › Remote › Devices › ID

#### remoteDeviceId
`GET /protocols/bacnet/remote/devices/52001`

http://eclypseapi.distech-controls.com/restApi/bacnet/resources/1023/GET

GET /protocols/bacnet/local/objects

These objects represent physical inputs, outputs, and values used by and coming from software processes.

This resource lists all of the current objects on the device.

## BACnet › Remote › Devices

#### devices
`GET /protocols/bacnet/remote/devices`

http://eclypseapi.distech-controls.com/restApi/bacnet/resources/1023/GET

GET /protocols/bacnet/local/objects

These objects represent physical inputs, outputs, and values used by and coming from software processes.

This resource lists all of the current objects on the device.

## BACnet › Remote

#### remote
`GET /protocols/bacnet/remote`

http://eclypseapi.distech-controls.com/restApi/bacnet/resources/1023/GET

GET /protocols/bacnet/local/objects

These objects represent physical inputs, outputs, and values used by and coming from software processes.

This resource lists all of the current objects on the device.

## BACnet

#### bacnet
`GET /protocols/bacnet`

This resource is the root of all BACnet objects and properties.

http://eclypseapi.distech-controls.com/restApi/bacnet/resources/1021/GET

#### Date TIme
`GET /protocols/bacnet`

This resource is the root of all BACnet objects and properties.

http://eclypseapi.distech-controls.com/restApi/bacnet/resources/1021/GET
