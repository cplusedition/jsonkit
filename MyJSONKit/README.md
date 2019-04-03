# MyJSONKit

## Introduction

This is a small library that wrap the Object-C JSONSerialization functions 
and provide the traditional JSONObject / JSONArray API in type safe manner.

```
let settings = MyJSONObject()
    .put("fonts", MyJSONArray()
        .put(MyJSONObject()
            .put("name", "Sans")
            .put("size", 12))
        .put(MyJSONObject()
            .put("name", "Serif")
            .put("size", 13)))
let output = try settings.serializeAsString()
let input = try MyJSONObject.from(string: output)
let fontsize = input.array("fonts")?.object(1)?.int("size") ?? 10
```

**NOTE** The project has only been tested to work under MacOS and iOS.

## License

Copyright (c) Cplusedition Limited. All rights reserved.

Licensed under the [Apache](LICENSE.txt) License.
