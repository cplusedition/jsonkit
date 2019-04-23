/*
 *  Copyright (c) 2017, Cplusedition Limited.  All rights reserved.
 *
 *  This file is licensed to you under the Apache License, Version 2.0
 *  (the "License"); you may not use this file except in compliance with
 *  the License.  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 *
 */

import Foundation
import XCTest
@testable import MyJSONKit

class TestMyJSON01: TestBase {
    
    override var DEBUGGING: Bool {
        return super.DEBUGGING
    }
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    /// Basic tests for MyJSONObject.
    func testBasic01() throws {
        let myint = MyJSONValue(123)
        XCTAssertEqual(123, myint.int, "int")
        let myarray = MyJSONArray([ 1, 2, 3])
        XCTAssertTrue(myarray.isValid())
        XCTAssertEqual(2, myarray[1]?.int)
        let m = myarray
        XCTAssertTrue(m.isValid())
        try m.put(1, 9)
        XCTAssertTrue(myarray.isValid())
        XCTAssertEqual(9, m[1]?.int)
        XCTAssertEqual(9, myarray[1]?.int)
    }
    
    func testBasic01a() throws {
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
        let fontsize = input.array("fonts")?.object(1)?.int("size") ?? 0
        XCTAssertEqual(13, fontsize)
    }
    
    /// Check that String and NSString can be used as MyJSONObject values
    func testString01() throws {
        let json = MyJSONObject()
        let string: String = "String"
        let nsstring: NSString = "NSString"
        json.put("String", string)
        json.put("NSString", nsstring)
        XCTAssertTrue(json.isValid())
        XCTAssertEqual("NSString", json["NSString"]?.string, "nsstring")
        XCTAssertEqual("String", json["String"]?.string, "string")
        /// Check that this constructor create an NSArray[NSString]
        let jsonstringarray = MyJSONArray(["1", "2", "3"])
        XCTAssertTrue(jsonstringarray.isValid())
        XCTAssertEqual("2", jsonstringarray[1]?.string, "jsonstringarray")
        let jsonstring = jsonstringarray[1]
        XCTAssertEqual("Optional<Any>", "\(type(of: jsonstring?.raw))", "jsonstring")
        XCTAssertEqual("Optional<Any>", String(describing: type(of: jsonstring?.raw)), "jsonstring")
        XCTAssertEqual("Swift.Optional<Any>", String(reflecting: type(of: jsonstring?.raw)), "jsonstring")
        let arraymirror = Mirror(reflecting: jsonstringarray.raw.self)
        let mirror = Mirror(reflecting: jsonstring!.raw.self)
        DEBUG("# mirror=\(mirror)")
        DEBUG("# mirror=\(mirror.description)")
        DEBUG("# mirror=\(mirror.subjectType)")
        // XCTAssertEqual("__NSCFString", "\(mirror.subjectType)", "jsonstring")
        //#BEGIN NOTE For iOS < 12
        //        XCTAssertEqual("_NSContiguousString", "\(mirror.subjectType)", "jsonstring")
        //#END NOTE
        //#BEGIN NOTE For iOS >= 12
        XCTAssertEqual("NSTaggedPointerString", "\(mirror.subjectType)", "jsonstring")
        //#END NOTE
        XCTAssertEqual("Array<AnyObject>", "\(arraymirror.subjectType)", "jsonstring")
        let nsarray = NSMutableArray()
        XCTAssertEqual("Array<AnyObject>", "\(Mirror(reflecting: nsarray).subjectType)", "nsarray")
    }
    
    func testJSONSerialization01() throws {
        let jsonWithError = "{ \"key1\" : [ 1, 2, 3 ], \"key2\": { \"a\": trueorfalse }, \"key3\": null, \"key4\": 1.23 }"
        do {
            _ = try JSONSerialization.jsonObject(with: jsonWithError.data(using: .utf8)!)
            XCTFail()
        } catch {
            // Expected errors
            DEBUG("# Expected error: \(error)")
        }
        let json = "{ \"key1\" : [ 1, 2, 3 ], \"key2\": { \"a\": true }, \"key3\": null, \"key4\": 1.23 }"
        let jobject = try JSONSerialization.jsonObject(with: json.data(using: .utf8)!)
        XCTAssertEqual(1.23, (jobject as! [String:Any])["key4"] as! Double, "key4")
    }
    
    /// Basic tests for parse and accessors.
    /// Make sure object content are not copied on changes.
    func testBasic02() throws {
        let string = "{ \"key1\" : [ 1, 2, 3 ], \"key2\": { \"a\": true }, \"key3\": null, \"key4\": 1.23 }"
        let json = try MyJSONObject.from(string: string)
        XCTAssertEqual(1.23, json["key4"]?.double, "key4")
        let notexists = json["notexists"]
        XCTAssertNil(notexists, "notexists")
        let a = json["key1"]
        XCTAssertNotNil(a, "key1")
        XCTAssertEqual(2, a?[1]?.int, "a[1]")
        /// Note that m is an alias of the json object
        let m = json
        m.put("key1", "abc")
        if DEBUGGING {
            let m1 = m["key1"]
            let j1 = json["key1"]
            DEBUG("m[key1]: \(String(describing: m1?.raw))")
            DEBUG("json[key1]: \(String(describing: j1?.raw))")
        }
        XCTAssertEqual(true, m["key1"]?.isString)
        XCTAssertEqual(false, m["key1"]?.isArray)
        XCTAssertEqual(true, json["key1"]?.isString)
        XCTAssertEqual(false, json["key1"]?.isArray)
        XCTAssertEqual("abc", m["key1"]?.string, "m")
        XCTAssertEqual("abc", json["key1"]?.string, "json")
    }
    
    /// Simple test for MyJSONObject parser by reading test01.json. */
    func testParseFontsJsonWithJSONSerialization01() throws {
        let data = try testResData("myjson/test01.json")
        let json = try JSONSerialization.jsonObject(with: data, options: [.mutableContainers, .mutableLeaves] )
        DEBUG("\(json)")
        let dict = (json as! NSDictionary)
        let cats0 = (dict["cats0"] as! NSArray)
        XCTAssertEqual("All", (cats0[0] as! String))
    }
    
    /// Simple test for MyJSONObject parser by reading test01.json with MyJSONObject. */
    func testParseFontsJsonWithMyJSON01() throws {
        let data = try testResData("myjson/test01.json")
        let json = try MyJSONObject.from(data /*, readonly: true */)
        if DEBUGGING {
            let a = json["cats0"]
            DEBUG("\(String(describing: a?.raw))")
        }
        XCTAssertEqual("All", json["cats0"]?[0]?.string, "cats0")
        XCTAssertEqual("../fonts/symbols/fontawesome/FontAwesome.ttf", json["fonts2"]?["FontAwesome"]?["url"]?.string, "url")
        XCTAssertEqual(519, json["fonts2"]?["FontAwesome"]?["glyphcount"]?.int, "glyphcount")
        XCTAssertEqual(61506, json["fonts2"]?["FontAwesome"]?["glyphs"]?[0]?.int, "glyphs")
        // Readonly test ignored for now
        //        let a = MyJSONArray([1, 2, 3])
        //        json["fonts2"]?["FontAwesome"]?.object?.put("glyphs", a)
        //        XCTFail()
    }
    
    /// Simple test for MyJSONObject serializer with test01.json. */
    func testSerializeJSON01() throws {
        let data = try testResData("myjson/test01.json")
        let json = try MyJSONObject.from(data)
        if DEBUGGING {
            let a = json["fonts0"]?["Antonio"]
            DEBUG("# a=\(String(describing: a?.raw))")
        }
        let a = json["fonts0"]?["Antonio"]
        let s = try a?.serializeAsString()
        DEBUG("# s=\(String(describing: s))")
        let json2 = try MyJSONObject.from(string: s!)
        XCTAssertNotNil(json2, "json2")
        XCTAssertEqual("Sans Serif", json2["category"]?.string, "category")
    }
    
    /// More complete test for coverage.
    func testSerializeJSON02() throws {
        let filepath = testResPath("myjson/test01.json")
        let json = try MyJSONObject.from(path: filepath)
        XCTAssertEqual(try json.serializeAsString(), try MyJSONObject.from(path: filepath).serializeAsString())
        let jsonobject = json.object("fonts0")!.object("AdventPro")!
        let jsonarray = jsonobject.array("fontfaces")!
        DEBUG("# object: \(jsonobject)")
        DEBUG("# array: \(jsonarray)")
        try subtest {
            let data = try jsonobject.serializeAsData()
            let string = try jsonobject.serializeAsString()
            let out = try MyJSONObject.from(string: string)
            for key in jsonobject.keys {
                XCTAssertNotNil(out[key])
            }
            for key in out.keys {
                XCTAssertNotNil(jsonobject[key])
            }
            let count = string.count
            XCTAssertEqual(string, String(data: data, encoding: .utf8))
            XCTAssertEqual(count, try MyJSONObject.from(data).serializeAsString().count)
            XCTAssertEqual(count, try MyJSONObject.from(Array(data)).serializeAsString().count)
            XCTAssertEqual(data.count, try MyJSONObject.from(string: string).serializeAsData().count)
            XCTAssertEqual(count, try MyJSONValue.from(data).serializeAsString().count)
            XCTAssertEqual(count, try MyJSONValue.from(Array(data)).serializeAsString().count)
            XCTAssertEqual(data.count, try MyJSONValue.from(string: string).serializeAsData().count)
        }
        try subtest {
            let data = try jsonarray.serializeAsData()
            let string = try jsonarray.serializeAsString()
            let out = try MyJSONArray.from(string: string)
            XCTAssertEqual(jsonarray.count, out.count)
            XCTAssertEqual(string, String(data: data, encoding: .utf8))
            XCTAssertEqual(string, try MyJSONArray.from(data).serializeAsString())
            XCTAssertEqual(string, try MyJSONArray.from(Array(data)).serializeAsString())
            XCTAssertEqual(data, try MyJSONArray.from(string: string).serializeAsData())
        }
    }
    
    /// Check that jSON behaves as follows:
    /// In case a = { "key": null },
    /// optString(a, "key", "") returns "".
    /// optString(a, "notexists", "") returns "".
    /// optString(a, "key", null) returns null.
    /// optString(a, "notexists", null) returns null.
    func testOptString01() throws {
        let json = try MyJSONObject.from(string: "{ \"key\": null }")
        XCTAssertEqual("", json.string("key", ""), "#1")
        XCTAssertEqual("", json.string("notexists", ""), "#2")
    }
    
    /// Check that MyJSONObject.from() throw an exception on parse error.
    func testJSONParseError01() throws {
        do {
            try _ = MyJSONObject.from(string: "{ parse = error }")
            XCTFail("Expecting exception")
        } catch {
            DEBUG("# Expected exception: \(error)")
        }
        do {
            try _ = MyJSONObject.from(string: "{ \"key1\": 123, \"key3\" = null }")
        } catch {
            DEBUG("# Expected exception: \(error)")
        }
    }
    
    /// Check how MyJSONObject behave when setting value to nil
    func testSetNil01 () throws {
        let json = try MyJSONObject.from(string: "{ \"key1\": 123, \"key3\" : null }")
        XCTAssertEqual(123, json["key1"]?.int, "123")
        json.put("key1", NSNull())
        let v1 = json["key1"]
        let v2 = json["key2"]
        if DEBUGGING {
            DEBUG("#1: \(String(describing: v1?.raw))")
            DEBUG("#2: \(String(describing: v2?.raw))")
        }
        XCTAssertNotNil(json["key1"], "key1 exists")
        XCTAssertNil(json["key2"], "key2 not exists")
        XCTAssertEqual(nil, json["key1"]?.int, "key1.int")
        json.remove("key1")
        XCTAssertNil(json["key1"], "key1 not exists")
        XCTAssertNotNil(json["key3"], "key3 exists")
    }
    
    /// Check how MyJSONObject behave with bool
    func testBool01() throws {
        let json = MyJSONObject()
        json.put("key1", true);
        json.put("key2", false);
        json.put("key3", 0)
        json.put("key4", 1)
        let serialized = try json.serializeAsString()
        if DEBUGGING {
            let k1 = json["key1"]
            let k2 = json["key2"]
            let k3 = json["key3"]
            let k4 = json["key4"]
            DEBUG("# key1: \(String(describing: k1?.raw))")
            DEBUG("# key2: \(String(describing: k2?.raw))")
            DEBUG("# key3: \(String(describing: k3?.raw))")
            DEBUG("# key4: \(String(describing: k4?.raw))")
            DEBUG("# serialzed: \(serialized)")
        }
        XCTAssertEqual(true, json["key1"]?.bool, "key1")
        XCTAssertEqual(false, json["key2"]?.bool, "key2")
        XCTAssertEqual(nil, json["key3"]?.bool, "key3")
        XCTAssertNotNil(serialized.range(of: "\"key1\":true"))
        XCTAssertNotNil(serialized.range(of: "\"key3\":0"))
        let serialized2 = try MyJSONObject.from(string: serialized).serializeAsString()
        XCTAssertEqual(serialized, serialized2, "serialized2")
    }
    
    /// Basic test to check that various constructors works.
    func testConstructors01() throws {
        XCTAssertEqual(12, MyJSONValue(12).int)
        XCTAssertEqual(12, MyJSONValue(Int64(12)).int)
        XCTAssertEqual(12.0, MyJSONValue(Double(12)).double)
        XCTAssertEqual("12", MyJSONValue("12").string)
        XCTAssertEqual(2, MyJSONArray([1, 2, 3])[1]?.int)
        XCTAssertEqual("3", MyJSONArray(["1", "2", "3"])[2]?.string)
        XCTAssertEqual(1, MyJSONArray().put(1).put(2)[0]?.int)
        XCTAssertEqual(2, MyJSONArray().put("1").put(2)[1]?.int)
        XCTAssertEqual(true, MyJSONObject().put("k1", "v1").put("k2", 2).put("k3", true)["k3"]?.bool)
        XCTAssertEqual("a", try MyJSONObject.from(string: "{ \"k1\": 1, \"k2\": \"a\" }")["k2"]?.string)
    }
    
    /// Basic test to check that the value accessors works.
    func testAccessors01() throws {
        let json = MyJSONObject()
        let nullable: String? = nil
        json.put("k1", 1).put("k2", "a").put("k3", true).put("k4", 12.34).put("k5", NSNull()).put("nullable", nullable)
        json.put("array", MyJSONArray()).put("object", MyJSONObject())
        json["array"]?.array?.put(1).put(MyJSONArray([1, 2, 3])).put(nullable)
        json["object"]?.object?.put("k1", MyJSONObject())
        DEBUG("# json: \(try! json.serializeAsString(pretty: true))")
        //
        XCTAssertTrue(json.isValid())
        // Integer
        XCTAssertEqual(false, json["k1"]?.isNull)
        XCTAssertEqual(false, json["k1"]?.isBool)
        XCTAssertEqual(true, json["k1"]?.isNumber)
        XCTAssertEqual(false, json["k1"]?.isString)
        XCTAssertEqual(false, json["k1"]?.isArray)
        XCTAssertEqual(false, json["k1"]?.isObject)
        XCTAssertEqual(nil, json["k1"]?.null)
        XCTAssertEqual(nil, json["k1"]?.bool)
        XCTAssertEqual(1, json["k1"]?.int)
        XCTAssertEqual(1, json["k1"]?.int32)
        XCTAssertEqual(1, json["k1"]?.int64)
        XCTAssertEqual(1.0, json["k1"]?.double)
        XCTAssertEqual(nil, json["k1"]?.string)
        XCTAssertNil(json.at("k1")?.array)
        XCTAssertNil(json.at("k1")?.object)
        // String
        XCTAssertEqual(false, json["k2"]?.isNull)
        XCTAssertEqual(false, json["k2"]?.isBool)
        XCTAssertEqual(false, json["k2"]?.isNumber)
        XCTAssertEqual(true, json["k2"]?.isString)
        XCTAssertEqual(false, json["k2"]?.isArray)
        XCTAssertEqual(false, json["k2"]?.isObject)
        XCTAssertEqual(nil, json["k1"]?.null)
        XCTAssertEqual(nil, json["k2"]?.bool)
        XCTAssertEqual(nil, json["k2"]?.int)
        XCTAssertEqual(nil, json["k2"]?.int32)
        XCTAssertEqual(nil, json["k2"]?.int64)
        XCTAssertEqual(nil, json["k2"]?.double)
        XCTAssertEqual("a", json["k2"]?.string)
        XCTAssertNil(json["k2"]?.array)
        XCTAssertNil(json["k2"]?.object)
        // Bool
        XCTAssertEqual(false, json["k3"]?.isNull)
        XCTAssertEqual(true, json["k3"]?.isBool)
        XCTAssertEqual(true, json["k3"]?.isNumber)
        XCTAssertEqual(false, json["k3"]?.isString)
        XCTAssertEqual(false, json["k3"]?.isArray)
        XCTAssertEqual(false, json["k3"]?.isObject)
        XCTAssertEqual(nil, json["k1"]?.null)
        XCTAssertEqual(true, json["k3"]?.bool)
        XCTAssertEqual(1, json["k3"]?.int)
        XCTAssertEqual(1, json["k3"]?.int32)
        XCTAssertEqual(1, json["k3"]?.int64)
        XCTAssertEqual(1.0, json["k3"]?.double)
        XCTAssertEqual(nil, json["k3"]?.string)
        XCTAssertNil(json.at("k3")?.array)
        XCTAssertNil(json.at("k3")?.object)
        // Double
        XCTAssertEqual(false, json["k4"]?.isNull)
        XCTAssertEqual(false, json["k4"]?.isBool)
        XCTAssertEqual(true, json["k4"]?.isNumber)
        XCTAssertEqual(false, json["k4"]?.isString)
        XCTAssertEqual(false, json["k4"]?.isArray)
        XCTAssertEqual(false, json["k4"]?.isObject)
        XCTAssertEqual(nil, json["k1"]?.null)
        XCTAssertEqual(nil, json["k4"]?.bool)
        XCTAssertEqual(12, json["k4"]?.int)
        XCTAssertEqual(12, json["k4"]?.int32)
        XCTAssertEqual(12, json["k4"]?.int64)
        XCTAssertEqual(12.34, json["k4"]?.double)
        XCTAssertEqual(nil, json["k4"]?.string)
        XCTAssertNil(json["k4"]?.array)
        XCTAssertNil(json.at("k4")?.object)
        // Null
        XCTAssertEqual(true, json["k5"]?.isNull)
        XCTAssertEqual(false, json["k5"]?.isBool)
        XCTAssertEqual(false, json["k5"]?.isNumber)
        XCTAssertEqual(false, json["k5"]?.isString)
        XCTAssertEqual(false, json["k5"]?.isArray)
        XCTAssertEqual(false, json["k5"]?.isObject)
        XCTAssertEqual(NSNull(), json["k5"]?.null)
        XCTAssertEqual(nil, json["k5"]?.bool)
        XCTAssertEqual(nil, json["k5"]?.int)
        XCTAssertEqual(nil, json["k5"]?.int32)
        XCTAssertEqual(nil, json["k5"]?.int64)
        XCTAssertEqual(nil, json["k5"]?.double)
        XCTAssertEqual(nil, json["k5"]?.string)
        XCTAssertNil(json["k5"]?.array)
        XCTAssertNil(json.at("k5")?.object)
    }
    
    /// Like testAccessor01() but use MyJSONObject, MyJSONArray accessors instead of MyJSONValue accessors.
    func testAccessors02() throws {
        let json = MyJSONObject()
        let nullable: String? = nil
        json.put("k1", 1).put("k2", "a").put("k3", true).put("k4", 12.34).put("k5", NSNull()).put("nullable", nullable)
        json.put("array", MyJSONArray()).put("object", MyJSONObject())
        json.array("array")?.put(1).put(MyJSONArray([1, 2, 3])).put(nullable)
        json.object("object")?.put("k1", MyJSONObject())
        DEBUG("# json: \(try! json.serializeAsString(pretty: true))")
        //
        XCTAssertTrue(json.isValid())
        // Integer
        XCTAssertEqual(false, json["k1"]?.isNull)
        XCTAssertEqual(false, json["k1"]?.isBool)
        XCTAssertEqual(true, json["k1"]?.isNumber)
        XCTAssertEqual(false, json["k1"]?.isString)
        XCTAssertEqual(false, json["k1"]?.isArray)
        XCTAssertEqual(false, json["k1"]?.isObject)
        XCTAssertEqual(false, json.isNull("k1"))
        XCTAssertEqual(nil, json.bool("k1"))
        XCTAssertEqual(1, json.int("k1"))
        XCTAssertEqual(1, json.int32("k1"))
        XCTAssertEqual(1, json.int64("k1"))
        XCTAssertEqual(1.0, json.double("k1"))
        XCTAssertEqual(nil, json.string("k1"))
        XCTAssertNil(json.at("k1")?.array)
        XCTAssertNil(json.at("k1")?.object)
        // String
        XCTAssertEqual(false, json["k2"]?.isNull)
        XCTAssertEqual(false, json["k2"]?.isBool)
        XCTAssertEqual(false, json["k2"]?.isNumber)
        XCTAssertEqual(true, json["k2"]?.isString)
        XCTAssertEqual(false, json["k2"]?.isArray)
        XCTAssertEqual(false, json["k2"]?.isObject)
        XCTAssertEqual(false, json.isNull("k1"))
        XCTAssertEqual(nil, json.bool("k2"))
        XCTAssertEqual(nil, json.int("k2"))
        XCTAssertEqual(nil, json.int32("k2"))
        XCTAssertEqual(nil, json.int64("k2"))
        XCTAssertEqual(nil, json.double("k2"))
        XCTAssertEqual("a", json.string("k2"))
        XCTAssertNil(json.array("k2"))
        XCTAssertNil(json.object("k2"))
        // Bool
        XCTAssertEqual(false, json["k3"]?.isNull)
        XCTAssertEqual(true, json["k3"]?.isBool)
        XCTAssertEqual(true, json["k3"]?.isNumber)
        XCTAssertEqual(false, json["k3"]?.isString)
        XCTAssertEqual(false, json["k3"]?.isArray)
        XCTAssertEqual(false, json["k3"]?.isObject)
        XCTAssertEqual(false, json.isNull("k1"))
        XCTAssertEqual(true, json.bool("k3"))
        XCTAssertEqual(1, json.int("k3"))
        XCTAssertEqual(1, json.int32("k3"))
        XCTAssertEqual(1, json.int64("k3"))
        XCTAssertEqual(1.0, json.double("k3"))
        XCTAssertEqual(nil, json.string("k3"))
        XCTAssertNil(json.at("k3")?.array)
        XCTAssertNil(json.at("k3")?.object)
        // Double
        XCTAssertEqual(false, json["k4"]?.isNull)
        XCTAssertEqual(false, json["k4"]?.isBool)
        XCTAssertEqual(true, json["k4"]?.isNumber)
        XCTAssertEqual(false, json["k4"]?.isString)
        XCTAssertEqual(false, json["k4"]?.isArray)
        XCTAssertEqual(false, json["k4"]?.isObject)
        XCTAssertEqual(false, json.isNull("k1"))
        XCTAssertEqual(nil, json.bool("k4"))
        XCTAssertEqual(12, json.int("k4"))
        XCTAssertEqual(12, json.int32("k4"))
        XCTAssertEqual(12, json.int64("k4"))
        XCTAssertEqual(12.34, json.double("k4"))
        XCTAssertEqual(nil, json.string("k4"))
        XCTAssertNil(json.array("k4"))
        XCTAssertNil(json.at("k4")?.object)
        // Null
        XCTAssertEqual(true, json["k5"]?.isNull)
        XCTAssertEqual(false, json["k5"]?.isBool)
        XCTAssertEqual(false, json["k5"]?.isNumber)
        XCTAssertEqual(false, json["k5"]?.isString)
        XCTAssertEqual(false, json["k5"]?.isArray)
        XCTAssertEqual(false, json["k5"]?.isObject)
        XCTAssertEqual(true, json.isNull("k5"))
        XCTAssertEqual(nil, json.bool("k5"))
        XCTAssertEqual(nil, json.int("k5"))
        XCTAssertEqual(nil, json.int32("k5"))
        XCTAssertEqual(nil, json.int64("k5"))
        XCTAssertEqual(nil, json.double("k5"))
        XCTAssertEqual(nil, json.string("k5"))
        XCTAssertNil(json.array("k5"))
        XCTAssertNil(json.at("k5")?.object)
    }
    
    /// Check MyJSONObject.xxx(key, def) accessors.
    func testAccessors03() throws {
        let json = MyJSONObject()
        let nullable: String? = nil
        json.put("k1", 1).put("k2", "a").put("k3", true).put("k4", 12.34).put("k5", NSNull()).put("nullable", nullable)
        json.put("array", MyJSONArray()).put("object", MyJSONObject())
        json.array("array")?.put(1).put(MyJSONArray([1, 2, 3])).put(nullable)
        json.object("object")?.put("k1", MyJSONObject())
        DEBUG("# json: \(try! json.serializeAsString(pretty: true))")
        // Integer
        XCTAssertEqual(false, json.bool("k1", false))
        XCTAssertEqual(1, json.int("k1", 123))
        XCTAssertEqual(1, json.int32("k1", 123))
        XCTAssertEqual(1, json.int64("k1", 123))
        XCTAssertEqual(1.0, json.double("k1", 123.0))
        XCTAssertEqual("", json.string("k1", ""))
        // String
        XCTAssertEqual(true, json.bool("k2", true))
        XCTAssertEqual(123, json.int("k2", 123))
        XCTAssertEqual(123, json.int32("k2", 123))
        XCTAssertEqual(123, json.int64("k2", 123))
        XCTAssertEqual(123.0, json.double("k2", 123.0))
        XCTAssertEqual("a", json.string("k2", ""))
        // Bool
        XCTAssertEqual(true, json.bool("k3", false))
        XCTAssertEqual(1, json.int("k3", 123))
        XCTAssertEqual(1, json.int32("k3", 123))
        XCTAssertEqual(1, json.int64("k3", 123))
        XCTAssertEqual(1.0, json.double("k3", 123.0))
        XCTAssertEqual("", json.string("k3", ""))
        // Double
        XCTAssertEqual(false, json.bool("k4", false))
        XCTAssertEqual(12, json.int("k4", 999))
        XCTAssertEqual(12, json.int32("k4", 999))
        XCTAssertEqual(12, json.int64("k4", 999))
        XCTAssertEqual(12.34, json.double("k4", 123.0))
        XCTAssertEqual("", json.string("k4", ""))
        // Null
        XCTAssertEqual(false, json.bool("k5", false))
        XCTAssertEqual(999, json.int("k5", 999))
        XCTAssertEqual(999, json.int32("k5", 999))
        XCTAssertEqual(999, json.int64("k5", 999))
        XCTAssertEqual(999.9, json.double("k5", 999.9))
        XCTAssertEqual("", json.string("k5", ""))
        // Not exists
        XCTAssertEqual(true, json.bool("notexists", true))
        XCTAssertEqual(999, json.int("notexists", 999))
        XCTAssertEqual(999, json.int32("notexists", 999))
        XCTAssertEqual(999, json.int64("notexists", 999))
        XCTAssertEqual(999.9, json.double("notexists", 999.9))
        XCTAssertEqual("", json.string("notexists", ""))
    }
    
    /// Check MyJSONObject.xxx(key) accessors.
    func testAccessors04() throws {
        let json = MyJSONObject()
        let nullable: String? = nil
        json.put("k1", 1).put("k2", "a").put("k3", true).put("k4", 12.34).put("k5", NSNull()).put("nullable", nullable)
        json.put("array", MyJSONArray()).put("object", MyJSONObject())
        json.array("array")?.put(1).put(MyJSONArray([1, 2, 3])).put(nullable)
        json.object("object")?.put("k1", MyJSONObject())
        DEBUG("# json: \(try! json.serializeAsString(pretty: true))")
        // Integer
        XCTAssertEqual(nil, json.bool("k1"))
        XCTAssertEqual(1, json.int("k1"))
        XCTAssertEqual(1, json.int32("k1"))
        XCTAssertEqual(1, json.int64("k1"))
        XCTAssertEqual(1.0, json.double("k1"))
        XCTAssertEqual(nil, json.string("k1"))
        XCTAssertEqual(false, json.isNull("k1"))
        // String
        XCTAssertEqual(nil, json.bool("k2"))
        XCTAssertEqual(nil, json.int("k2"))
        XCTAssertEqual(nil, json.int32("k2"))
        XCTAssertEqual(nil, json.int64("k2"))
        XCTAssertEqual(nil, json.double("k2"))
        XCTAssertEqual("a", json.string("k2"))
        XCTAssertEqual(false, json.isNull("k2"))
        // Bool
        XCTAssertEqual(true, json.bool("k3"))
        XCTAssertEqual(1, json.int("k3"))
        XCTAssertEqual(1, json.int32("k3"))
        XCTAssertEqual(1, json.int64("k3"))
        XCTAssertEqual(1.0, json.double("k3"))
        XCTAssertEqual(nil, json.string("k3"))
        XCTAssertEqual(false, json.isNull("k3"))
        // Double
        XCTAssertEqual(nil, json.bool("k4"))
        XCTAssertEqual(12, json.int("k4"))
        XCTAssertEqual(12, json.int32("k4"))
        XCTAssertEqual(12, json.int64("k4"))
        XCTAssertEqual(12.34, json.double("k4"))
        XCTAssertEqual(nil, json.string("k4"))
        XCTAssertEqual(false, json.isNull("k4"))
        // Null
        XCTAssertEqual(nil, json.bool("k5"))
        XCTAssertEqual(nil, json.int("k5"))
        XCTAssertEqual(nil, json.int32("k5"))
        XCTAssertEqual(nil, json.int64("k5"))
        XCTAssertEqual(nil, json.double("k5"))
        XCTAssertEqual(nil, json.string("k5"))
        XCTAssertEqual(true, json.isNull("k5"))
        // Not exists
        XCTAssertEqual(nil, json.bool("notexists"))
        XCTAssertEqual(nil, json.int("notexists"))
        XCTAssertEqual(nil, json.int32("notexists"))
        XCTAssertEqual(nil, json.int64("notexists"))
        XCTAssertEqual(nil, json.double("notexists"))
        XCTAssertEqual(nil, json.string("notexists"))
        XCTAssertEqual(false, json.isNull("notexists"))
    }
    
    func testAccessorArray01() throws {
        let array = MyJSONArray().put(1).put("a").put(true).put(12.34).put(NSNull())
        // Integer
        XCTAssertEqual(nil, array.bool(0))
        XCTAssertEqual(1, array.int(0))
        XCTAssertEqual(1, array.int32(0))
        XCTAssertEqual(1, array.int64(0))
        XCTAssertEqual(1.0, array.double(0))
        XCTAssertEqual(nil, array.string(0))
        // String
        XCTAssertEqual(nil, array.bool(1))
        XCTAssertEqual(nil, array.int(1))
        XCTAssertEqual(nil, array.int32(1))
        XCTAssertEqual(nil, array.int64(1))
        XCTAssertEqual(nil, array.double(1))
        XCTAssertEqual("a", array.string(1))
        // Bool
        XCTAssertEqual(true, array.bool(2))
        XCTAssertEqual(1, array.int(2))
        XCTAssertEqual(1, array.int32(2))
        XCTAssertEqual(1, array.int64(2))
        XCTAssertEqual(1.0, array.double(2))
        XCTAssertEqual(nil, array.string(2))
        // Double
        XCTAssertEqual(nil, array.bool(3))
        XCTAssertEqual(12, array.int(3))
        XCTAssertEqual(12, array.int32(3))
        XCTAssertEqual(12, array.int64(3))
        XCTAssertEqual(12.34, array.double(3))
        XCTAssertEqual(nil, array.string(3))
        // Null
        XCTAssertEqual(nil, array.bool(4))
        XCTAssertEqual(nil, array.int(4))
        XCTAssertEqual(nil, array.int32(4))
        XCTAssertEqual(nil, array.int64(4))
        XCTAssertEqual(nil, array.double(4))
        XCTAssertEqual(nil, array.string(4))
        // Not exists
        XCTAssertEqual(nil, array.bool(999))
        XCTAssertEqual(nil, array.int(999))
        XCTAssertEqual(nil, array.int32(999))
        XCTAssertEqual(nil, array.int64(999))
        XCTAssertEqual(nil, array.double(999))
        XCTAssertEqual(nil, array.string(999))
    }
    
    func testAccessorArray02() throws {
        let array = MyJSONArray().put(1).put("a").put(true).put(12.34).put(NSNull())
        // Integer
        XCTAssertEqual(true, array.bool(0, true))
        XCTAssertEqual(1, array.int(0, 123))
        XCTAssertEqual(1, array.int32(0, 123))
        XCTAssertEqual(1, array.int64(0, 123))
        XCTAssertEqual(1.0, array.double(0, 123.0))
        XCTAssertEqual("abc", array.string(0, "abc"))
        XCTAssertEqual(false, array.isNull(0))
        // String
        XCTAssertEqual(false, array.bool(1, false))
        XCTAssertEqual(123, array.int(1, 123))
        XCTAssertEqual(123, array.int32(1, 123))
        XCTAssertEqual(123, array.int64(1, 123))
        XCTAssertEqual(123.0, array.double(1, 123.0))
        XCTAssertEqual("a", array.string(1, "abc"))
        XCTAssertEqual(false, array.isNull(1))
        // Bool
        XCTAssertEqual(true, array.bool(2, true))
        XCTAssertEqual(1, array.int(2, 123))
        XCTAssertEqual(1, array.int32(2, 123))
        XCTAssertEqual(1, array.int64(2, 123))
        XCTAssertEqual(1.0, array.double(2, 123.0))
        XCTAssertEqual("abc", array.string(2, "abc"))
        XCTAssertEqual(false, array.isNull(2))
        // Double
        XCTAssertEqual(false, array.bool(3, false))
        XCTAssertEqual(12, array.int(3, 123))
        XCTAssertEqual(12, array.int32(3, 123))
        XCTAssertEqual(12, array.int64(3, 123))
        XCTAssertEqual(12.34, array.double(3, 123.0))
        XCTAssertEqual("abc", array.string(3, "abc"))
        XCTAssertEqual(false, array.isNull(3))
        // Null
        XCTAssertEqual(true, array.bool(4, true))
        XCTAssertEqual(123, array.int(4, 123))
        XCTAssertEqual(123, array.int32(4, 123))
        XCTAssertEqual(123, array.int64(4, 123))
        XCTAssertEqual(123.0, array.double(4, 123.0))
        XCTAssertEqual("abc", array.string(4, "abc"))
        XCTAssertEqual(true, array.isNull(4))
        // Not exists
        XCTAssertEqual(false, array.bool(999, false))
        XCTAssertEqual(123, array.int(999, 123))
        XCTAssertEqual(123, array.int32(999, 123))
        XCTAssertEqual(123, array.int64(999, 123))
        XCTAssertEqual(123.0, array.double(999, 123.0))
        XCTAssertEqual("abc", array.string(999, "abc"))
        XCTAssertEqual(false, array.isNull(5))
    }
    
    /// Basic test to check that put methods works.
    func testPut01() throws {
        let json = MyJSONObject()
        let nullable: String? = nil
        json.put("k1", 1).put("k2", "a").put("k3", true).put("k4", 12.34).put("k5", NSNull()).put("nullable", nullable)
        json.put("array", MyJSONArray()).put("object", MyJSONObject())
        json["array"]?.array?.put(1).put(MyJSONArray([1, 2, 3])).put(nullable)
        let k1 = MyJSONObject()
        let k2 = MyJSONArray(["a", "b", "c"])
        let k3 = MyJSONArray([1, 2, 3])
        json["object"]?.object?.put("k1", k1)
        k1.put("k2", k2)
        try k2.put(1, k3)
        let array = json["array"]!.array!
        try array.put("1").put("2").put("3").put(0, "0").put(3, "3")
        DEBUG("# json=\(try! json.serializeAsString(pretty: true))")
        XCTAssertEqual("0", json["array"]?[0]?.string)
        XCTAssertEqual("3", json["array"]?[3]?.string)
        XCTAssertEqual(2, json["array"]?[1]?[1]?.int)
        XCTAssertEqual(2, json["object"]?["k1"]?["k2"]?[1]?[1]?.int)
        try json["object"]?.object?["k1"]?.object?["k2"]?.array?.put(1, 123)
        XCTAssertEqual(123, json["object"]?["k1"]?["k2"]?[1]?.int)
        XCTAssertEqual(123, k2[1]?.int)
        XCTAssertEqual(2, k3[1]?.int)
        // Array.put
        let array1 = MyJSONArray()
        array1.put(true).put(23).put(Int64.max).put(Double.pi).put(MyJSONObject.NULL).put("abc");
        array1.put(MyJSONArray().put("a")).put(MyJSONObject().put("k1", 123))
        XCTAssertEqual(true, array1[0]?.bool)
        XCTAssertEqual(23, array1[1]?.int)
        XCTAssertEqual(Int64.max, array1[2]?.int64)
        XCTAssertEqual(Double.pi, array1[3]?.double)
        XCTAssertEqual(NSNull(), array1[4]?.null)
        XCTAssertEqual("abc", array1[5]?.string)
        XCTAssertEqual("a", array1[6]?[0]?.string)
        XCTAssertEqual(123, array1[7]?["k1"]?.int)
        //  Array.put(index, value)
        try array1.put(0, "123").put(7, 1).put(1, true).put(2, Int64(88)).put(6, Double.pi).put(3, MyJSONObject.NULL)
        try array1.put(4, MyJSONArray().put("xyz")).put(5, MyJSONObject().put("k1", 999))
        XCTAssertEqual("123", array1[0]?.string)
        XCTAssertEqual(true, array1[1]?.bool)
        XCTAssertEqual(88, array1[2]?.int64)
        XCTAssertEqual(MyJSONObject.NULL, array1[3]?.null)
        XCTAssertEqual("xyz", array1[4]?[0]?.string)
        XCTAssertEqual(999, array1[5]?["k1"]?.int)
        XCTAssertEqual(Double.pi, array1[6]?.double)
        XCTAssertEqual(1, array1[7]?.int)
        // Object.put(key, value)
        let object1 = MyJSONObject()
        object1.put("k1", true).put("k2", 23).put("k3", Int64.max).put("k4", Double.pi).put("k5", MyJSONObject.NULL).put("k6", "abc")
        object1.put("k7", MyJSONArray().put("a")).put("k8", MyJSONObject().put("k1", 123))
        XCTAssertEqual(true, object1["k1"]?.bool)
        XCTAssertEqual(23, object1["k2"]?.int)
        XCTAssertEqual(Int64.max, object1["k3"]?.int64)
        XCTAssertEqual(Double.pi, object1["k4"]?.double)
        XCTAssertEqual(NSNull(), object1["k5"]?.null)
        XCTAssertEqual("abc", object1["k6"]?.string)
        XCTAssertEqual("a", object1["k7"]?[0]?.string)
        XCTAssertEqual(123, object1["k8"]?["k1"]?.int)
    }
    
    func testValues01() throws {
        let data = try testResData("myjson/test01.json")
        let json = try MyJSONObject.from(data)
        let fonts0 = json["fonts0"]
        XCTAssertNotNil(fonts0)
        var count = 0
        for key in fonts0!.object!.keys {
            guard "AdventPro" == key else { continue }
            for (key, value) in fonts0![key]!.object!.keyValues {
                guard key == "styles" else { continue }
                for _ in value.array!.values {
                    count += 1
                }
            }
        }
        XCTAssertEqual(7, count)
        for (key, value) in fonts0!.object!.keyValues {
            guard key == "AdventPro" else { continue }
            for (key, value) in value.object!.keyValues {
                guard key == "styles" else { continue }
                for _ in value.array!.values {
                    count += 1
                }
            }
        }
        XCTAssertEqual(14, count)
    }
    
    /// Misc tests for coverage.
    func testCoverage01() throws {
        try subtest {
            XCTAssertEqual(true, MyJSONValue(true).bool)
            XCTAssertEqual(false, MyJSONValue(false).bool)
            XCTAssertEqual(123, MyJSONValue(Int32(123)).int)
            XCTAssertNil(MyJSONValue(Int32(123)).array)
            XCTAssertEqual(-123, MyJSONValue(NSNumber(value: -123)).int)
            XCTAssertEqual("test", MyJSONValue("test" as NSString).string)
            XCTAssertNil(MyJSONValue("test" as NSString).at(0))
            XCTAssertNil(MyJSONValue("test" as NSString).at(0))
            let array = MyJSONArray()
            array.put(1)
            array.put(2)
            array.put(true)
            let b:Bool? = nil
            array.put(b) // 3
            array.put(Int32(32))
            array.put(Int64(64))
            array.put(1.23)
            array.put(NSNumber(value: 123))
            array.put("nsstring" as NSString)
            array.put(MyJSONObject())
            XCTAssertEqual(1, array[0]?.int)
            XCTAssertEqual(true, array[2]?.bool)
            XCTAssertEqual(true, array[3]?.isNull)
            XCTAssertEqual(32, array[4]?.int)
            XCTAssertEqual(Int64(64), array[5]?.int64)
            XCTAssertEqual(1.23, array[6]?.double)
            XCTAssertEqual(123, array[7]?.int)
            XCTAssertEqual("nsstring", array[8]?.string)
            XCTAssertTrue(array[9]!.isObject)
            XCTAssertEqual(10, array.count)
            XCTAssertEqual(0, MyJSONObject().count)
            // XCTAssertThrowsError(try JSONValue("test").put("123"))
            try XCTAssertThrowsError(array.put(100, 123))
        }
        try subtest {
            // MyJSONArray
            let array = MyJSONArray()
            array.put(MyJSONObject().put("a", 1)).put(MyJSONArray([1, 2, 3]))
            XCTAssertEqual(1, array.object(0)?.int("a"))
            XCTAssertEqual(2, array.array(1)?.int(1))
            XCTAssertNil(array.object(123))
            XCTAssertNil(array.array(123))
            let a = MyJSONArray([1, 2, 9, 5, 6, 0])
            var ai = a.values
            var ar = a.reversed
            XCTAssertEqual(1, ai.next()?.int)
            XCTAssertEqual(0, ar.next()?.int)
            try a.put(0, 1)
            try a.put(1, 2)
            try a.put(2, 3)
            try a.put(3, 4)
            try a.put(4, 5)
            try a.put(5, 6)
            do {
                try a.put(6, 7)
                XCTFail()
            } catch {
                // Expected exception
            }
            for i in 0..<a.count {
                XCTAssertEqual(i+1, a.int(i))
            }
            try a.put(1, true)
            XCTAssertEqual(true, a.bool(1))
            try a.put(1, 1.23)
            XCTAssertEqual(1.23, a.double(1))
            try a.put(1, 123)
            XCTAssertEqual(123, a.int(1))
            XCTAssertEqual(123, a.int32(1))
            XCTAssertEqual(123, a.int64(1))
            XCTAssertEqual(false, a.isNull(1))
            try a.put(1, "abcd")
            XCTAssertEqual("abcd", a.string(1))
            try a.put(1, NSNull())
            XCTAssertEqual(true, a.isNull(1))
            let string: String? = nil
            try a.put(1, string)
            XCTAssertEqual(true, a.isNull(1))
            XCTAssertEqual(false, a.isNull(2))
            let b = MyJSONArray().put(1).put(["c", "b"])
            XCTAssertEqual("b", b.stringArray(1)?[1])
        }
        subtest {
            // MyJSONObject
            let object = MyJSONObject()
            let array = MyJSONArray()
            array.put(MyJSONObject().put("a", 1)).put(MyJSONArray([1, 2, 3]))
            object.put("array", array)
            object.put("a", array[0])
            XCTAssertEqual(1, object.array("array")?.object(0)?.int("a"))
            let a = MyJSONObject().put("akey", "avalue").put("ckey", "cvalue").put("bkey", "bvalue")
            for key in a.keys {
                XCTAssertTrue(key == "akey" || key == "bkey" || key == "ckey")
            }
            for v in a.values {
                let value = v.string!
                XCTAssertTrue(value == "avalue" || value == "bvalue" || value == "cvalue")
            }
            let b = MyJSONObject(in: array).put("strings", ["c", "a", "b"])
            XCTAssertEqual(3, array.count)
            XCTAssertNotNil(array[2]?.object)
            XCTAssertEqual(3, b.array("strings")?.count)
            subtest {
                let nsnumber = NSNumber(value: 123)
                let a = MyJSONObject().put("nsnumber", nsnumber)
                XCTAssertEqual(123, a["nsnumber"]?.int)
            }
            subtest {
                let a = MyJSONObject().put(["a": "1", "b": "2"])
                XCTAssertEqual("1", a["a"]?.string)
                XCTAssertEqual("2", a["b"]?.string)
                XCTAssertNil(a["c"])
            }
            subtest {
                let notnull = ["1", "2", "3"]
                let null: [String]? = nil
                let a = MyJSONObject().put("notnull", notnull).put("null", "null").put("null", null)
                XCTAssertEqual(1, a.count)
                XCTAssertEqual("2", a["notnull"]?.array?[1]?.string)
                XCTAssertEqual(false, a.containsKey("null"))
            }
        }
    }
    
    /// Misc tests for coverage.
    func testCoverage02() throws {
        let data = try testResData("myjson/test01.json")
        let json = try MyJSONObject.from(data)
        let fonts0 = json.object("fonts0")!
        let jsonobject = fonts0.object("AdventPro")!
        let jsonarray = jsonobject.array("fontfaces")!
        let stringarray = jsonobject.stringArray("styles")!
        XCTAssertEqual(stringarray, jsonobject["styles"]!.stringArray!)
        XCTAssertNil(jsonobject["notexists"])
        XCTAssertNil(jsonobject.at("notexists"))
        XCTAssertNil(jsonarray[10001])
        XCTAssertNil(jsonarray.at(10001))
        subtest {
            // MyJSONValue
            XCTAssertNotNil(fonts0["AdventPro"]?.array("styles"))
            XCTAssertNotNil(fonts0["AdventPro"]?.array("styles"))
            XCTAssertNil(fonts0["AdventPro"]?.array("notexists"))
            XCTAssertNotNil(json.object("fonts0")!.object("AdventPro"))
            XCTAssertNil(json.object("fonts0")!.object("notexists"))
            XCTAssertNil(json["fonts0"]!.array("styles"))
            XCTAssertNil(json["fonts0"]!["notexists"])
            XCTAssertNil(jsonobject["styles"]?[10001])
            XCTAssertTrue(jsonobject.isValid())
            XCTAssertTrue(jsonarray.isValid())
            XCTAssertTrue(fonts0["AdventPro"]!.isValid())
            XCTAssertEqual(true, MyJSONValue.isValid(fonts0["AdventPro"]!.raw))
            let invalid = NSMutableDictionary()
            invalid["a"] = [NSSet()]
            XCTAssertEqual(false, MyJSONValue.isValid(invalid))
            let object = MyJSONObject()
            let object1 = MyJSONObject(in: object, at: "object")
            object1.put("a", MyJSONObject().put("aa", 1))
            let array = MyJSONArray(in: object, at: "array")
            array.put(MyJSONObject().put("a", 1)).put(MyJSONArray([1, 2, 3]))
            XCTAssertEqual(1, object["array"]!.object(0)?.int("a"))
            XCTAssertEqual(2, object["array"]!.array(1)?.int(1))
            XCTAssertNil(object["array"]!.object(123))
            XCTAssertNil(object["array"]!.array(123))
            XCTAssertEqual(1, object["object"]!.object("a")?.int("aa"))
            XCTAssertNil(object["object"]!.object("b"))
        }
    }
    
    func testIntMin01() throws {
        let object = MyJSONObject()
        object.put("min", Int64.min)
        object.put("max", Int64.max)
        XCTAssertEqual(Int64.min, object.int64("min"))
        XCTAssertEqual(Int64.max, object.int64("max"))
        let clone = try MyJSONObject.from(object.serializeAsData())
        XCTAssertEqual(Int64.min, clone.int64("min"))
        XCTAssertEqual(Int64.max, clone.int64("max"))
    }
    
    func testJSONValueType01() throws {
        let object = MyJSONObject()
            .put("string", "abc")
            .put("object", MyJSONObject().put("bool", true))
            .put("array", MyJSONArray().put(1).put(2).put(3))
            .put("double", 1.23)
            .put("int", 123)
            .put("int64", Int64(1234567890123))
            .put("int32", Int32(123))
            .put("null", MyJSONObject.NULL)
            .put("bool", false)
        XCTAssertEqual(nil, object["notexists"]?.type)
        XCTAssertEqual(MyJSONValueType.STRING, object["string"]?.type)
        XCTAssertEqual(MyJSONValueType.OBJECT, object["object"]?.type)
        XCTAssertEqual(MyJSONValueType.ARRAY, object["array"]?.type)
        XCTAssertEqual(MyJSONValueType.NUMBER, object["double"]?.type)
        XCTAssertEqual(MyJSONValueType.NUMBER, object["int"]?.type)
        XCTAssertEqual(MyJSONValueType.NUMBER, object["int64"]?.type)
        XCTAssertEqual(MyJSONValueType.NUMBER, object["int32"]?.type)
        XCTAssertEqual(MyJSONValueType.BOOL, object["bool"]?.type)
        XCTAssertEqual(MyJSONValueType.NULL, object["null"]?.type)
    }
    
    func testJSONValue01() throws {
        let object = MyJSONObject()
            .put("string", "abcd")
            .put("object", MyJSONObject().put("string", "abc"))
            .put("array", MyJSONArray().put(1).put(2).put(3))
        XCTAssertNil(object["array"]?.array(1))
        XCTAssertNil(object["array"]?.object(1))
        let arrayvalue = MyJSONValue(MyJSONArray().put(1).put(2).put(3))
        let objectvalue = MyJSONValue(MyJSONObject().put("string", "abc"))
        XCTAssertEqual(2, arrayvalue.array?.int(1))
        XCTAssertEqual("abc", objectvalue.object?.string("string"))
    }
    
    func testJSONArray01() throws {
        let object = MyJSONObject()
            .put("string", "abcd")
            .put("object", MyJSONObject().put("string", "abc"))
            .put("array", MyJSONArray().put(1).put(2).put(3))
        let array = MyJSONArray().put("a").put("b").put("c")
        let null: MyJSONValue? = nil
        try array.put(1, object["string"])
        try array.put(0, null)
        array.put(object["string"])
        XCTAssertEqual(true, array.isNull(0))
        XCTAssertEqual(false, array.isNull(1))
        XCTAssertEqual("abcd", array[1]?.string)
        XCTAssertEqual("abcd", array[3]?.string)
        try subtest {
            let bool: Bool? = nil
            let int: Int? = nil
            let int32: Int32? = nil
            let int64: Int64? = nil
            let double: Double? = nil
            let number: NSNumber? = nil
            let nsstring: NSString? = nil
            let string: String? = nil
            let array: MyJSONArray? = nil
            let object: MyJSONObject? = nil
            let value: MyJSONValue? = nil
            let a = MyJSONArray()
            a.put(bool)
            a.put(int)
            a.put(int32)
            a.put(int64)
            a.put(double)
            a.put(number)
            a.put(nsstring)
            a.put(string)
            a.put(array)
            a.put(object)
            a.put(value)
            for index in 0..<a.count {
                XCTAssertTrue(a[index]!.isNull)
            }
            try a.put(0, true)
            try a.put(1, 1)
            try a.put(2, Int32(2))
            try a.put(3, Int64(3))
            try a.put(4, Double(4.0))
            try a.put(5, NSNumber(value: 5.0))
            try a.put(6, NSString(string: "nsstring"))
            try a.put(7, "string")
            try a.put(8, MyJSONArray())
            try a.put(9, MyJSONObject())
            try a.put(10, MyJSONValue(false))
            for index in 0..<a.count {
                XCTAssertFalse(a[index]!.isNull)
            }
            try a.put(0, bool)
            try a.put(1, int)
            try a.put(2, int32)
            try a.put(3, int64)
            try a.put(4, double)
            try a.put(5, number)
            try a.put(6, nsstring)
            try a.put(7, string)
            try a.put(8, array)
            try a.put(9, object)
            try a.put(10, value)
            for index in 0..<a.count {
                XCTAssertTrue(a[index]!.isNull)
            }
        }
        subtest {
            // put([String]?)
            let notnull = ["a", "b", "c"]
            let null: [String]? = nil
            let a = MyJSONArray().put(notnull).put(null)
            XCTAssertEqual(2, a.count)
            XCTAssertEqual("b", a[0]?.array?[1]?.string)
            XCTAssertEqual(true, a[1]!.isNull)
        }
        subtest {
            let a = MyJSONArray().put("a")
            let b = MyJSONArray(in: a).put("b")
            XCTAssertEqual("b", b.string(0))
            XCTAssertEqual("b", a[1]?.array?.string(0))
            XCTAssertTrue(b.identical(a[1]?.array))
        }
        subtest {
            let a = MyJSONArray()
                .put(MyJSONObject().put("a", 1))
                .put(MyJSONArray().put("b"))
            XCTAssertNil(a.array(0))
            XCTAssertNil(a.object(1))
            XCTAssertNil(a.array(2))
            XCTAssertNil(a.object(2))
        }
        subtest {
            let a = MyJSONArray().put(1).put(["1", "2", "3"]).put(true)
            XCTAssertNil(a.stringArray(0))
            XCTAssertEqual(3, a.stringArray(1)?.count)
            XCTAssertNil(a.stringArray(2))
            XCTAssertNil(a.stringArray(3))
        }
    }
    
    func testJSONArrayFrom01() throws {
        XCTAssertNil(try? MyJSONArray.from(string: "{ \"a\" : 1 }"))
        XCTAssertNil(try? MyJSONArray.from(string: "[1, 2"))
        XCTAssertNil(try? MyJSONArray.from(Data("{ \"a\" : 1 }".utf8)))
        XCTAssertNil(try? MyJSONArray.from(Data("[1, 2".utf8)))
        XCTAssertNil(try? MyJSONArray.from(Array("{ \"a\" : 1 }".utf8)))
        XCTAssertNil(try? MyJSONArray.from(Array("[1, 2".utf8)))
        subtest {
            let s = InputStream(data: Data("{ \"a\" : 1 }".utf8))
            s.open()
            defer { s.close() }
            XCTAssertNil(try? MyJSONArray.from(s))
        }
        subtest {
            let s = InputStream(data: Data("[1, 2".utf8))
            s.open()
            defer { s.close() }
            XCTAssertNil(try? MyJSONArray.from(s))
        }
        subtest {
            let s = InputStream(data: Data("[1, 2]".utf8))
            s.open()
            defer { s.close() }
            XCTAssertNotNil(try? MyJSONArray.from(s))
        }
        XCTAssertNil(try? MyJSONArray.from(path: testResPath("myjson/test01.json")))
        XCTAssertNil(try? MyJSONArray.from(path: testResPath("myjson/testInvalidArray01.json")))
        XCTAssertNotNil(try? MyJSONArray.from(path: testResPath("myjson/testArray01.json")))
    }

    func testJSONObjectFrom01() throws {
        XCTAssertEqual(1, try MyJSONObject.from(string: "{ \"a\" : 1 }")["a"]?.int)
        XCTAssertNil(try? MyJSONObject.from(string: "{ \"a\" : 1 "))
        XCTAssertNil(try? MyJSONObject.from(string: "[1, 2]"))
        XCTAssertEqual(1, try MyJSONObject.from(Data("{ \"a\" : 1 }".utf8))["a"]?.int)
        XCTAssertNil(try? MyJSONObject.from(Data("{ \"a\" : 1".utf8)))
        XCTAssertNil(try? MyJSONObject.from(Data("[1, 2]".utf8)))
        XCTAssertEqual(1, try MyJSONObject.from(Array("{ \"a\" : 1 }".utf8))["a"]?.int)
        XCTAssertNil(try? MyJSONObject.from(Array("{ \"a\" : 1".utf8)))
        XCTAssertNil(try? MyJSONObject.from(Array("[1, 2]".utf8)))
        try subtest {
            let s = InputStream(data: Data("{ \"a\" : 1}".utf8))
            s.open()
            defer { s.close() }
            XCTAssertEqual(1, try MyJSONObject.from(s)["a"]?.int)
        }
        subtest {
            let s = InputStream(data: Data("{ \"a\" : 1".utf8))
            s.open()
            defer { s.close() }
            XCTAssertNil(try? MyJSONObject.from(s))
        }
        subtest {
            let s = InputStream(data: Data("[1, 2]".utf8))
            s.open()
            defer { s.close() }
            XCTAssertNil(try? MyJSONObject.from(s))
        }
        subtest {
            let s = InputStream(data: Data("{ \"a\": 1 }".utf8))
            s.open()
            defer { s.close() }
            XCTAssertNotNil(try? MyJSONObject.from(s))
        }
        XCTAssertNil(try? MyJSONObject.from(path: testResPath("myjson/testInvalidObject01.json")))
        XCTAssertNotNil(try? MyJSONObject.from(path: testResPath("myjson/testObject01.json")))
        XCTAssertNil(try? MyJSONObject.from(path: testResPath("myjson/testArray01.json")))
    }
    
    func testIdentical01() throws {
        subtest {
            let o1 = MyJSONObject().put("a", 1)
            let o2 = MyJSONObject().put("a", 1)
            XCTAssertTrue(o1.identical(o1))
            XCTAssertTrue(o2.identical(o2))
            XCTAssertFalse(o1.identical(o2))
        }
        subtest {
            let a1 = MyJSONArray().put(1)
            let a2 = MyJSONArray().put(1)
            XCTAssertTrue(a1.identical(a1))
            XCTAssertTrue(a2.identical(a2))
            XCTAssertFalse(a1.identical(a2))
        }
    }
}
