# Json parser plugin for Embulk

Parser plugin for [Embulk](https://github.com/embulk/embulk).

Read data from input as json and fetch each entries by [jsonpath](http://goessner.net/articles/JsonPath/) to output.



## Overview

* **Plugin type**: parser
* **Load all or nothing**: yes
* **Resume supported**: no

### Breaking changes

A type name has been changed from **json** to **jsonpath** from v0.0.3.

## Configuration

```yaml
parser:
  type: jsonpath
  root: $.response.station
  stop_on_invalid_record: false
  schema:
    - {name: name, type: string}
    - {name: next, type: string}
    - {name: prev, type: string}
    - {name: distance, type: string}
    - {name: lat, type: double, path: x}
    - {name: lng, type: double, path: y}
    - {name: line, type: string}
    - {name: postal, type: string}
    - {name: optionals, type: json}
```

- **type**: Specify this plugin as `json`
- **root**: Root property to start fetching each entries, specify in [jsonpath](http://goessner.net/articles/JsonPath/) style, required
- **schema**: Specify the attribute of table and data type, required
- **stop_on_invalid_record**: Stop bulk load transaction if a file includes invalid record, false by default


## Example

```json
{
    "result" : "success",
    "students" : [
      { "name" : "John", "age" : 10 },
      { "name" : "Paul", "age" : 16 },
      { "name" : "George", "age" : 17 },
      { "name" : "Ringo", "age" : 18 }
    ]
}
```

### Simple schema

You can iterate "students" node by the following condifuration:

```yaml
root: $.students
schema:
  - {name: name, type: string}
  - {name: age, type: long}
```

### Handle more complicated json


If you want to handle more complicated json, you can specify jsonpath to also **path** in schema section like as follows:

```json
{
    "result" : "success",
    "students" : [
      { "names" : ["John", "Lennon"], "age" : 10 },
      { "names" : ["Paul", "Maccartney"], "age" : 10 }
    ]
}
```

```yaml
root: $.students
schema:
  - {name: firstName, type: string, path: "names[0]"}
  - {name: lastName, type: string, path: "names[1]"}
```

In this case, names[0] will be firstName of schema and names[1] will be lastName.
