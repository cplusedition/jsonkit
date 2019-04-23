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

enum JSONException: Error {
    case IndexOutOfBound
    case InvalidCharacterEncoding
    case InvalidJSONObject
    case InvalidJSONArray
    case InvalidJSONValue
    case IOException
}

// //////////////////////////////////////////////////////////////////////

/// Note that MyJSONObject value is never nil.
/// Use a NSNull object for null value.
/// Use MyJSONObject.isNull(key) to check for null value.
/// Setting value of an entry to nil remove the entry.
public struct MyJSONObject {
    
    public static let NULL = NSNull()
    
    private var _value: NSMutableDictionary
    
    var raw: Any {
        return _value
    }
    
    public var count : Int {
        return _value.count
    }
    
    /// @return the keys of the JSON object.
    public var keys : [String] {
        return _value.allKeys as! [String]
    }
    
    /// @return the values of the JSON object.
    public var values: MyJSONValueSequence  {
        return MyJSONValueSequence((_value.allValues as NSArray).makeIterator())
    }
    
    /// @return the key/value pairs of the JSON object.
    public var keyValues : MyJSONKeyValueSequence {
        return MyJSONKeyValueSequence(_value)
    }
    
    /// The relaxed constructor that do not perform any validation and assume input is valid.
    /// !!! Use with caution.
    public init(sanitized value: NSMutableDictionary) {
        self._value = value
    }
    
    public init() {
        self._value = NSMutableDictionary()
    }
    
    /// Create a new JSON object as value at the given key in the given JSON object.
    /// @return The new JSON object.
    public init(in object: MyJSONObject, at key: String) {
        self.init()
        object.put(key, self)
    }
    
    /// Create a new JSON object and added it to the given JSON array.
    public init(in array: MyJSONArray) {
        self.init()
        array.put(self)
    }
    
    public func at(_ key: String) -> MyJSONValue? {
        if let value = _value[key] {
            return MyJSONValue(sanitized: value)
        }
        return nil
    }
    
    public subscript(_ key: String) -> MyJSONValue? {
        return at(key)
    }
    
    /// @return true if the value of the two object are ===.
    public func identical(_ other: MyJSONObject?) -> Bool {
        return other != nil && _value === other!._value
    }
    
    public func object(_ key: String) -> MyJSONObject? {
        if let value = _value[key] {
            if let v  = value as? NSMutableDictionary {
                return MyJSONObject(sanitized: v)
            }
        }
        return nil
    }
    
    public func array(_ key: String) -> MyJSONArray? {
        if let value = _value[key] {
            if let v  = value as? NSMutableArray {
                return MyJSONArray(sanitized: v)
            }
        }
        return nil
    }
    
    /// @return a String if value is a string type, otherwise nil.
    public func string(_ key: String) -> String? {
        if let value = _value[key] as? String {
            return value
        }
        return nil
    }
    
    /// @return a Double value if value is a double, integer or boolean type, otherwise nil.
    public func double(_ key: String) -> Double? {
        if let value = _value[key] as? NSNumber {
            return value.doubleValue
        }
        return nil
    }
    
    /// @return a Int64 (possiblty truncated) value if value is a double, integer or boolean type, otherwise nil.
    public func int64(_ key: String) -> Int64? {
        if let value = _value[key] as? NSNumber {
            return value.int64Value
        }
        return nil
    }
    
    /// @return a Int32 (possiblty truncated) value if value is a double, integer or boolean type, otherwise nil.
    public func int32(_ key: String) -> Int32? {
        if let value = _value[key] as? NSNumber {
            return value.int32Value
        }
        return nil
    }
    
    /// @return a Int (possiblty truncated) value if value is a double, integer or boolean type, otherwise nil.
    public func int(_ key: String) -> Int? {
        if let value = _value[key] as? NSNumber {
            return value.intValue
        }
        return nil
    }
    
    /// @return a Bool value if value is a boolean type, otherwise nil.
    public func bool(_ key: String) -> Bool? {
        if let value = _value[key] as? NSNumber,
            U.isBool(value) {
            return value.boolValue
        }
        return nil
    }
    
    /// @return a String if value is a string type, otherwise def.
    public func string(_ key: String, _ def: String) -> String {
        if let value = _value[key] as? String {
            return value
        }
        return def
    }
    
    /// @return a Double value if value is a double, integer or boolean type, otherwise def.
    public func double(_ key: String, _ def: Double) -> Double {
        if let value = _value[key] as? NSNumber {
            return value.doubleValue
        }
        return def
    }
    
    /// @return a Int64 (possiblty truncated) value if value is a double, integer or boolean type, otherwise def.
    public func int64(_ key: String, _ def: Int64) -> Int64 {
        if let value = _value[key] as? NSNumber {
            return value.int64Value
        }
        return def
    }
    
    /// @return a Int32 (possiblty truncated) value if value is a double, integer or boolean type, otherwise def.
    public func int32(_ key: String, _ def: Int32) -> Int32 {
        if let value = _value[key] as? NSNumber {
            return value.int32Value
        }
        return def
    }
    
    /// @return a Int (possiblty truncated) value if value is a double, integer or boolean type, otherwise def.
    public func int(_ key: String, _ def: Int) -> Int {
        if let value = _value[key] as? NSNumber {
            return value.intValue
        }
        return def
    }
    
    /// @return a Bool value if value is a boolean type, otherwise def.
    public func bool(_ key: String, _ def: Bool) -> Bool {
        if let value = _value[key] as? NSNumber,
            U.isBool(value) {
            return value.boolValue
        }
        return def
    }
    
    /// @return true if value is a NSNull, otherwise false
    public func isNull(_ key: String) -> Bool {
        return _value[key] is NSNull
    }
    
    /// Set value at given key to null (NSNull) value.
    @discardableResult
    public func put(_ key: String, _ value: NSNull) -> MyJSONObject {
        _value[key] = value
        return self
    }
    
    /// Set value at given key to the given value. Remove the entry if given value is nil.
    @discardableResult
    public func put(_ key: String, _ value: Bool?) -> MyJSONObject {
        return put(key, sanitized: value)
    }
    
    /// Set value at given key to the given value. Remove the entry if given value is nil.
    @discardableResult
    public func put(_ key: String, _ value: Int?) -> MyJSONObject {
        return put(key, sanitized: value)
    }
    
    /// Set value at given key to the given value. Remove the entry if given value is nil.
    @discardableResult
    public func put(_ key: String, _ value: Int32?) -> MyJSONObject {
        return put(key, sanitized: value)
    }
    
    /// Set value at given key to the given value. Remove the entry if given value is nil.
    @discardableResult
    public func put(_ key: String, _ value: Int64?) -> MyJSONObject {
        return put(key, sanitized: value)
    }
    
    /// Set value at given key to the given value. Remove the entry if given value is nil.
    @discardableResult
    public func put(_ key: String, _ value: Double?) -> MyJSONObject {
        return put(key, sanitized: value)
    }
    
    /// Set value at given key to the given value. Remove the entry if given value is nil.
    @discardableResult
    public func put(_ key: String, _ value: String?) -> MyJSONObject {
        return put(key, sanitized: value)
    }
    
    /// Set value at given key to the given value. Remove the entry if given value is nil.
    @discardableResult
    public func put(_ key: String, _ value: NSNumber?) -> MyJSONObject {
        return put(key, sanitized: value)
    }
    
    /// Set value at given key to the given value. Remove the entry if given value is nil.
    @discardableResult
    public func put(_ key: String, _ value: NSString?) -> MyJSONObject {
        return put(key, sanitized: value)
    }
    
    /// Set value at given key to the given value. Remove the entry if given value is nil.
    @discardableResult
    public func put(_ key: String, _ value: MyJSONValue?) -> MyJSONObject {
        return put(key, sanitized: value?.raw)
    }
    
    /// Set value at given key to the given value. Remove the entry if given value is nil.
    @discardableResult
    public func put(_ key: String, _ value: MyJSONArray?) -> MyJSONObject {
        return put(key, sanitized: value?.raw)
    }
    
    /// Set value at given key to the given value. Remove the entry if given value is nil.
    @discardableResult
    public func put(_ key: String, _ value: MyJSONObject?) -> MyJSONObject {
        return put(key, sanitized: value?.raw)
    }
    
    @discardableResult
    private func put(_ key: String, sanitized: Any?) -> MyJSONObject {
        if sanitized == nil {
            remove(key)
        } else {
            _value[key] = sanitized!
        }
        return self
    }
    
    @discardableResult
    public func remove(_ key: String)  -> MyJSONObject {
        _value.removeObject(forKey: key)
        return self
    }

    public func containsKey(_ key: String) -> Bool {
        return _value.value(forKey: key) != nil
    }
    
    public func isValid() -> Bool {
        return MyJSONValue.isValid(_value)
    }
    
    public func serializeAsData(pretty: Bool = false) throws -> Data {
        return try U.serializeAsData(_value, pretty: pretty)
    }
    
    public func serializeAsString(pretty: Bool = false) throws -> String {
        return try U.serializeAsString(_value, pretty: pretty)
    }
}

/// Some shortcuts.
public extension MyJSONObject {
    /// @return A copy of [String] if value is an array of String, otherwise nil
    func stringArray(_ key: String) -> [String]? {
        return U.stringArray(_value[key])
    }
    
    /// Set value at given key to the given value. Remove the entry if given value is nil.
    @discardableResult
    func put(_ key: String, _ value: [String]?) -> MyJSONObject {
        if let array = value {
            return put(key, sanitized: NSMutableArray(array: array))
        }
        return put(key, sanitized: nil)
    }
    
    @discardableResult
    func put(_ keyvalues: [String: String]) -> MyJSONObject {
        _value.addEntries(from: keyvalues)
        return self
    }
}

public extension MyJSONObject {
    static func from(_ bytes: [UInt8]) throws -> MyJSONObject {
        guard let ret = try MyJSONValue.from(bytes).object else {
            throw JSONException.InvalidJSONObject
        }
        return ret
    }
    
    static func from(_ data: Data) throws -> MyJSONObject {
        guard let ret = try MyJSONValue.from(data).object else {
            throw JSONException.InvalidJSONObject
        }
        return ret
    }
    static func from(string: String) throws -> MyJSONObject {
        guard let ret = try MyJSONValue.from(string: string).object else {
            throw JSONException.InvalidJSONObject
        }
        return ret
    }
    
    static func from(path: String) throws -> MyJSONObject {
        guard let ret = try MyJSONValue.from(path: path).object else {
            throw JSONException.InvalidJSONObject
        }
        return ret
    }
    
    static func from(_ stream: InputStream) throws -> MyJSONObject {
        guard let ret = try MyJSONValue.from(stream).object else {
            throw JSONException.InvalidJSONObject
        }
        return ret
    }
}

// //////////////////////////////////////////////////////////////////////

public struct MyJSONArray {
    
    private var _value: NSMutableArray
    
    var raw: Any {
        return _value
    }
    
    public var count : Int {
        return _value.count
    }
    
    public var values: MyJSONValueSequence  {
        return MyJSONValueSequence(_value.makeIterator())
    }
    
    public var reversed: MyJSONValueSequence {
        return MyJSONValueSequence(_value.reverseObjectEnumerator().makeIterator())
    }

    /// The relaxed constructor that do not perform any validation and assume input is valid.
    /// !!! Use with caution.
    public init(sanitized: NSMutableArray) {
        _value = sanitized
    }

    public init() {
        self._value = NSMutableArray()
    }
    
    public init(_ value: [NSNumber]) {
        self._value = NSMutableArray(array: value)
    }
    
    public init(_ value: [String]) {
        self._value = NSMutableArray(array: value)
    }

    /// Create a new JSON array as value at the given key in the given JSON object.
    /// @return The new JSON array.
    public init(in object: MyJSONObject, at key: String) {
        self.init()
        object.put(key, self)
    }
    
    /// Create a new JSON array and add it to the given JSON array.
    /// @return The new JSON array.
    public init(in array: MyJSONArray) {
        self.init()
        array.put(self)
    }

    public func identical(_ other: MyJSONArray?) -> Bool {
        return other != nil && _value === other!._value
    }
    
    public func at(_ index: Int) -> MyJSONValue? {
        if index >= 0 && index < _value.count {
            return MyJSONValue(sanitized: _value[index])
        }
        return nil
    }
    
    public subscript(_ index: Int) -> MyJSONValue? {
        return at(index);
    }
    
    public func object(_ index: Int) -> MyJSONObject? {
        if index >= 0 && index < _value.count {
            if let value = _value[index] as? NSMutableDictionary{
                return MyJSONObject(sanitized: value)
            }
        }
        return nil
    }
    
    public func array(_ index: Int) -> MyJSONArray? {
        if index >= 0 && index < _value.count {
            if let value = _value[index] as? NSMutableArray {
                return MyJSONArray(sanitized: value)
            }
        }
        return nil
    }
    
    /// @return a String if value is a string type, otherwise nil.
    public func string(_ index: Int) -> String? {
        if index >= 0 && index < _value.count,
            let ret = _value[index] as? String {
            return ret
        }
        return nil
    }
    
    /// @return a Double value if value is a double, integer or boolean type, otherwise nil.
    public func double(_ index: Int) -> Double? {
        if index >= 0 && index < _value.count,
            let value = _value[index] as? NSNumber {
            return value.doubleValue
        }
        return nil
    }
    
    /// @return a Int64 (possiblty truncated) value if value is a double, integer or boolean type, otherwise nil.
    public func int64(_ index: Int) -> Int64? {
        if index >= 0 && index < _value.count,
            let value = _value[index] as? NSNumber {
            return value.int64Value
        }
        return nil
    }
    
    /// @return a Int32 (possiblty truncated) value if value is a double, integer or boolean type, otherwise nil.
    public func int32(_ index: Int) -> Int32? {
        if index >= 0 && index < _value.count,
            let value = _value[index] as? NSNumber {
            return value.int32Value
        }
        return nil
    }
    
    /// @return a Int (possiblty truncated) value if value is a double, integer or boolean type, otherwise nil.
    public func int(_ index: Int) -> Int? {
        if index >= 0 && index < _value.count,
            let value = _value[index] as? NSNumber {
            return value.intValue
        }
        return nil
    }
    
    /// @return a Bool value if value is a boolean type, otherwise nil.
    public func bool(_ index: Int) -> Bool? {
        if index >= 0 && index < _value.count,
            let value = _value[index] as? NSNumber,
            U.isBool(value) {
            return value.boolValue
        }
        return nil
    }
    
    /// @return a String if value is a string type, otherwise def.
    public func string(_ index: Int, _ def: String) -> String {
        if index >= 0 && index < _value.count,
            let ret = _value[index] as? String {
            return ret
        }
        return def
    }
    
    /// @return a Double value if value is a double, integer or boolean type, otherwise def.
    public func double(_ index: Int, _ def: Double) -> Double {
        if index >= 0 && index < _value.count,
            let value = _value[index] as? NSNumber {
            return value.doubleValue
        }
        return def
    }
    
    /// @return a Int64 (possiblty truncated) value if value is a double, integer or boolean type, otherwise def.
    public func int64(_ index: Int, _ def: Int64) -> Int64 {
        if index >= 0 && index < _value.count,
            let value = _value[index] as? NSNumber {
            return value.int64Value
        }
        return def
    }
    
    /// @return a Int32 (possiblty truncated) value if value is a double, integer or boolean type, otherwise def.
    public func int32(_ index: Int, _ def: Int32) -> Int32 {
        if index >= 0 && index < _value.count,
            let value = _value[index] as? NSNumber {
            return value.int32Value
        }
        return def
    }
    
    /// @return a Int (possiblty truncated) value if value is a double, integer or boolean type, otherwise def.
    public func int(_ index: Int, _ def: Int) -> Int {
        if index >= 0 && index < _value.count,
            let value = _value[index] as? NSNumber {
            return value.intValue
        }
        return def
    }
    
    /// @return a Bool value if value is a boolean type, otherwise def.
    public func bool(_ index: Int, _ def: Bool) -> Bool {
        if index >= 0 && index < _value.count,
            let value = _value[index] as? NSNumber,
            U.isBool(value) {
            return value.boolValue
        }
        return def
    }
    
    /// @return true if value is a NsNull object, otherwise false.
    public func isNull(_ index: Int) -> Bool {
        return index >= 0 && index < _value.count && _value[index] is NSNull
    }
    
    @discardableResult
    public func put(_ value: NSNull) -> MyJSONArray {
        _value.add(value)
        return self
    }
    
    private func put(sanitized: Any?) -> MyJSONArray {
        if let v = sanitized {
            _value.add(v)
        } else {
            _value.add(MyJSONObject.NULL)
        }
        return self
    }
    
    /// Add given value to the JSON array, add a NsNull object if value is nil.
    @discardableResult
    public func put(_ value: Bool?) -> MyJSONArray {
        return put(sanitized: value)
    }
    
    /// Add given value to the JSON array, add a NsNull object if value is nil.
    @discardableResult
    public func put(_ value: Int?) -> MyJSONArray {
        return put(sanitized: value)
    }
    
    /// Add given value to the JSON array, add a NsNull object if value is nil.
    @discardableResult
    public func put(_ value: Int32?) -> MyJSONArray {
        return put(sanitized: value)
    }
    
    /// Add given value to the JSON array, add a NsNull object if value is nil.
    @discardableResult
    public func put(_ value: Int64?) -> MyJSONArray {
        return put(sanitized: value)
    }
    
    /// Add given value to the JSON array, add a NsNull object if value is nil.
    @discardableResult
    public func put(_ value: Double?) -> MyJSONArray {
        return put(sanitized: value)
    }
    
    /// Add given value to the JSON array, add a NsNull object if value is nil.
    @discardableResult
    public func put(_ value: String?) -> MyJSONArray {
        return put(sanitized: value)
    }
    
    /// Add given value to the JSON array, add a NsNull object if value is nil.
    @discardableResult
    public func put(_ value: NSNumber?) -> MyJSONArray {
        return put(sanitized: value)
    }
    
    /// Add given value to the JSON array, add a NsNull object if value is nil.
    @discardableResult
    public func put(_ value: NSString?) -> MyJSONArray {
        return put(sanitized: value)
    }
    
    /// Add given value to the JSON array, add a NsNull object if value is nil.
    @discardableResult
    public func put(_ value: MyJSONObject?) -> MyJSONArray {
        return put(sanitized: (value == nil ? nil : value!.raw))
    }
    
    /// Add given value to the JSON array, add a NsNull object if value is nil.
    @discardableResult
    public func put(_ value: MyJSONArray?) -> MyJSONArray {
        return put(sanitized: (value == nil ? nil : value!.raw))
    }
    
    /// Add given value to the JSON array, add a NsNull object if value is nil.
    @discardableResult
    public func put(_ value: MyJSONValue?) -> MyJSONArray {
        return put(sanitized: (value == nil ? nil : value!.raw))
    }
    
    @discardableResult
    private func put(_ index: Int, sanitized value: Any) throws -> MyJSONArray {
        guard index >= 0 && index < _value.count  else {
            throw JSONException.IndexOutOfBound
        }
        _value[index] = value
        return self
    }
    
    @discardableResult
    public func put(_ index: Int, _ value: NSNull) throws -> MyJSONArray {
        return try put(index, sanitized: value)
    }
    
    /// Set value at the given index to the given value, or NsNull if given value if nil.
    @discardableResult
    public func put(_ index: Int, _ value: Bool?) throws -> MyJSONArray {
        return try put(index, sanitized: value ?? MyJSONObject.NULL)
    }
    
    /// Set value at the given index to the given value, or NsNull if given value if nil.
    @discardableResult
    public func put(_ index: Int, _ value: Int?) throws -> MyJSONArray {
        return try put(index, sanitized: value ?? MyJSONObject.NULL)
    }
    
    /// Set value at the given index to the given value, or NsNull if given value if nil.
    @discardableResult
    public func put(_ index: Int, _ value: Int32?) throws -> MyJSONArray {
        return try put(index, sanitized: value ?? MyJSONObject.NULL)
    }
    
    /// Set value at the given index to the given value, or NsNull if given value if nil.
    @discardableResult
    public func put(_ index: Int, _ value: Int64?) throws -> MyJSONArray {
        return try put(index, sanitized: value ?? MyJSONObject.NULL)
    }
    
    /// Set value at the given index to the given value, or NsNull if given value if nil.
    @discardableResult
    public func put(_ index: Int, _ value: Double?) throws -> MyJSONArray {
        return try put(index, sanitized: value ?? MyJSONObject.NULL)
    }
    
    /// Set value at the given index to the given value, or NsNull if given value if nil.
    @discardableResult
    public func put(_ index: Int, _ value: String?) throws -> MyJSONArray {
        return try put(index, sanitized: value ?? MyJSONObject.NULL)
    }
    
    /// Set value at the given index to the given value, or NsNull if given value if nil.
    @discardableResult
    public func put(_ index: Int, _ value: NSNumber?) throws -> MyJSONArray {
        return try put(index, sanitized: value ?? MyJSONObject.NULL)
    }
    
    /// Set value at the given index to the given value, or NsNull if given value if nil.
    @discardableResult
    public func put(_ index: Int, _ value: NSString?) throws -> MyJSONArray {
        return try put(index, sanitized: value ?? MyJSONObject.NULL)
    }
    
    /// Set value at the given index to the given value, or NsNull if given value if nil.
    @discardableResult
    public func put(_ index: Int, _ value: MyJSONObject?) throws -> MyJSONArray {
        return try put(index, sanitized: value?.raw ?? MyJSONObject.NULL)
    }
    
    /// Set value at the given index to the given value, or NsNull if given value if nil.
    @discardableResult
    public func put(_ index: Int, _ value: MyJSONArray?) throws -> MyJSONArray {
        return try put(index, sanitized: value?.raw ?? MyJSONObject.NULL)
    }
    
    /// Set value at the given index to the given value, or NsNull if given value if nil.
    @discardableResult
    public func put(_ index: Int, _ value: MyJSONValue?) throws -> MyJSONArray {
        return try put(index, sanitized: value?.raw ?? MyJSONObject.NULL)
    }
    
    public func isValid() -> Bool {
        return MyJSONValue.isValid(_value)
    }
    
    public func serializeAsData(pretty: Bool = false) throws -> Data {
        return try U.serializeAsData(_value, pretty: pretty)
    }
    
    public func serializeAsString(pretty: Bool = false) throws -> String {
        return try U.serializeAsString(_value, pretty: pretty)
    }
}

/// Some shortcuts
public extension MyJSONArray {
    /// @return A copy of [String] if value is an array of String, otherwise nil
    func stringArray(_ index: Int) -> [String]? {
        if index >= 0 && index < _value.count {
            return U.stringArray(_value[index])
        }
        return nil
    }
    
    /// Add given value to the JSON array, add a NsNull object if value is nil.
    @discardableResult
    func put(_ value: [String]?) -> MyJSONArray {
        if let array = value {
            return put(sanitized: NSMutableArray(array: array))
        }
        return put(sanitized: nil)
    }
}

/// Factory constructors
public extension MyJSONArray {
    static func from(_ bytes: [UInt8]) throws -> MyJSONArray {
        if let ret = try MyJSONValue.from(bytes).array {
            return ret
        }
        throw JSONException.InvalidJSONArray
    }
    
    static func from(_ data: Data) throws-> MyJSONArray {
        if let ret = try MyJSONValue.from(data).array {
            return ret
        }
        throw JSONException.InvalidJSONArray
    }

    static func from(string: String) throws -> MyJSONArray {
        if let ret = try MyJSONValue.from(string: string).array {
            return ret
        }
        throw JSONException.InvalidJSONArray
    }
    
    static func from(path: String) throws -> MyJSONArray {
        if let ret = try MyJSONValue.from(path: path).array {
            return ret
        }
        throw JSONException.InvalidJSONArray
    }
    
    static func from(_ stream: InputStream) throws -> MyJSONArray {
        if let ret = try MyJSONValue.from(stream).array {
            return ret
        }
        throw JSONException.InvalidJSONArray
    }
}

// //////////////////////////////////////////////////////////////////////

public enum MyJSONValueType {
    case OBJECT
    case ARRAY
    case STRING
    case NUMBER
    case BOOL
    case NULL
}

public struct MyJSONValue {
    
    fileprivate static let trueNumber = NSNumber(value: true)
    fileprivate static let falseNumber = NSNumber(value: false)
    fileprivate static let boolType = trueNumber.objCType.pointee // "c" for Bool

    private var _value: Any
    
    var raw: Any {
        return _value
    }
    
    fileprivate init(sanitized: Any) {
        _value = sanitized
    }
    
    public init(_ value: Bool) {
        self._value = NSNumber(value: value)
    }
    
    public init(_ value: Int) {
        self._value = NSNumber(value: value)
    }
    
    public init(_ value: Int32) {
        self._value = NSNumber(value: value)
    }
    
    public init(_ value: Int64) {
        self._value = NSNumber(value: value)
    }
    
    public init(_ value: Double) {
        self._value = NSNumber(value: value)
    }
    
    public init(_ value: String) {
        self._value = value
    }
    
    public init(_ value: NSNumber) {
        self._value = value
    }
    
    public init(_ value: NSString) {
        self._value = value
    }

    public init(_ value: MyJSONArray) {
        self._value = value.raw
    }
    
    public init(_ value: MyJSONObject) {
        self._value = value.raw
    }
    
    public func at(_ index: Int) -> MyJSONValue? {
        if let array = _value as? NSArray {
            if index >= 0 && index < array.count {
                return MyJSONValue(sanitized: array[index])
            }
        }
        return nil
    }
    
    public subscript(_ index: Int) -> MyJSONValue? {
        return at(index);
    }
    
    public func at(_ key: String) -> MyJSONValue? {
        if let dict = _value as? NSDictionary {
            if let value = dict.value(forKey: key) {
                return MyJSONValue(sanitized: value)
            }
        }
        return nil
    }
    
    public subscript(_ key: String) -> MyJSONValue? {
        return at(key)
    }

    /// @return If this is an JSONObject and the value at the given key is a JSONArray, return the JSONArray, otherwise nil.
    public func array(_ key: String) -> MyJSONArray? {
        if let value = _value as? NSMutableDictionary {
            if let array = value[key] as? NSMutableArray {
                return MyJSONArray(sanitized: array)
            }
        }
        return nil
    }
    
    /// @return If this is an JSONObject and the value at the given key is a JSONObject, return the JSONObject, otherwise nil.
    public func object(_ key: String) -> MyJSONObject? {
        if let value = _value as? NSMutableDictionary {
            if let dict = value[key] as? NSMutableDictionary {
                return MyJSONObject(sanitized: dict)
            }
        }
        return nil
    }
    
    /// @return If this is an JSONObject and the value at the given key is a JSONArray, return the JSONArray, otherwise nil.
    public func array(_ index: Int) -> MyJSONArray? {
        if let value = _value as? NSMutableArray {
            if index >= 0 && index < value.count {
                if let array = value[index] as? NSMutableArray {
                    return MyJSONArray(sanitized: array)
                }
            }
        }
        return nil
    }
    
    /// @return If this is an JSONObject and the value at the given key is a JSONObject, return the JSONObject, otherwise nil.
    public func object(_ index: Int) -> MyJSONObject? {
        if let value = _value as? NSMutableArray {
            if index >= 0 && index < value.count {
                if let dict = value[index] as? NSMutableDictionary {
                    return MyJSONObject(sanitized: dict)
                }
            }
        }
        return nil
    }
    
    /// @return self if value is an array type, otherwise nil
    public var array : MyJSONArray? {
        if let value = _value as? NSMutableArray {
            return MyJSONArray(sanitized: value)
        }
        return nil
    }
    
    /// @return self if value is an dictionary type, otherwise nil
    public var object : MyJSONObject? {
        if let value = _value as? NSMutableDictionary {
            return MyJSONObject(sanitized: value)
        }
        return nil
    }
    
    /// @return A copy of [String] if value is an array of String, otherwise nil
    public var stringArray: [String]? {
        return U.stringArray(_value)
    }
    
    /// @return a String if value is a string type, otherwise nil
    public var string: String? {
        guard let string = _value as? String else { return nil }
        return string
    }
    
    /// @return a Double value if value is a double, integer or boolean type, otherwise nil
    public var double: Double? {
        if let value = _value as? NSNumber {
            return value.doubleValue
        }
        return nil
    }
    
    /// @return a Int64 (possiblty truncated) value if value is a double, integer or boolean type, otherwise nil
    public var int64: Int64? {
        if let value = _value as? NSNumber {
            return value.int64Value
        }
        return nil
    }
    
    /// @return a Int32 (possiblty truncated) value if value is a double, integer or boolean type, otherwise nil
    public var int32: Int32? {
        if let value = _value as? NSNumber {
            return value.int32Value
        }
        return nil
    }
    
    /// @return a Int (possiblty truncated) value if value is a double, integer or boolean type, otherwise nil
    public var int: Int? {
        if let value = _value as? NSNumber {
            return value.intValue
        }
        return nil
    }
    
    /// @return a Bool value if value is a boolean type, otherwise nil
    public var bool: Bool? {
        guard let value = _value as? NSNumber else { return nil }
        if U.isBool(value) {
            return value.boolValue
        }
        return nil
    }
    
    /// @return a NSNull object if value is null type, otherwise nil
    public var null: NSNull? {
        return _value as? NSNull
    }
    
    public var isArray: Bool {
        return _value is NSMutableArray
    }
    
    public var isObject: Bool {
        return _value is NSMutableDictionary
    }
    
    public var isString: Bool {
        return _value is String
    }
    
    /// @return true if value is a number (integer or double) or a boolean
    public var isNumber: Bool {
        if _value is NSNumber {
            return true
        }
        return false
    }
    
    public var isBool: Bool {
        if let value = _value as? NSNumber {
            return U.isBool(value)
        }
        return false
    }
    
    public var isNull: Bool {
        return _value is NSNull
    }
    
    public var type: MyJSONValueType {
        switch _value {
        case is NSDictionary:
            return MyJSONValueType.OBJECT
        case is NSArray:
            return MyJSONValueType.ARRAY
        case is String:
            return MyJSONValueType.STRING
        case is NSNumber:
            return U.isBool(_value as! NSNumber) ? MyJSONValueType.BOOL : MyJSONValueType.NUMBER
        case is NSNull:
            return MyJSONValueType.NULL
        default:
            preconditionFailure()
        }
    }
    
    public func isValid() -> Bool {
        return MyJSONValue.isValid(_value)
    }
    
    public func serializeAsData(pretty: Bool = false) throws -> Data {
        return try U.serializeAsData(_value, pretty: pretty)
    }
    
    public func serializeAsString(pretty: Bool = false) throws -> String {
        return try U.serializeAsString(_value, pretty: pretty)
    }
}

/// Factory constructors.
public extension MyJSONValue {
    static func isValid(_ value: Any) -> Bool {
        return JSONSerialization.isValidJSONObject(value)
    }
    
    static func from(path: String) throws -> MyJSONValue {
        guard let stream = InputStream(fileAtPath: path) else {
            throw JSONException.IOException
        }
        stream.open()
        defer { stream.close() }
        return try from(stream)
    }
    
    static func from(string: String) throws -> MyJSONValue {
        guard let data = string.data(using: .utf8) else {
            throw JSONException.InvalidCharacterEncoding
        }
        return try from(data)
    }
    
    static func from(_ bytes: [UInt8]) throws -> MyJSONValue {
        return try from(Data(bytes))
    }
    
    static func from(_ stream: InputStream) throws -> MyJSONValue {
        let object: Any = try JSONSerialization.jsonObject(
            with: stream,
            options: [.allowFragments, .mutableContainers])
        return MyJSONValue(sanitized: object)
    }
    
    /// See JSONSerialization.jsonObject() description.
    static func from(_ data: Data /* , readonly: Bool = false */) throws -> MyJSONValue {
        let object: Any = try JSONSerialization.jsonObject(
            with: data,
            options: [.allowFragments, .mutableContainers])
        return MyJSONValue(sanitized: object)
    }
}

// //////////////////////////////////////////////////////////////////////
// Sequence

public protocol MyJSONSequence: Sequence {
}

public struct MyJSONValueSequence: Sequence, IteratorProtocol {
    private var _values: NSArray.Iterator
    init(_ iterator: NSArray.Iterator) {
        self._values = iterator
    }
    mutating public func next() -> MyJSONValue? {
        guard let ret = _values.next() else { return nil }
        return MyJSONValue(sanitized: ret)
    }
}

public struct MyJSONKeyValueSequence: Sequence, IteratorProtocol {
    private let _values: NSDictionary.Iterator
    init(_ values: NSDictionary) {
        self._values = values.makeIterator()
    }
    mutating public func next() -> (String, MyJSONValue)? {
        guard let keyvalue = _values.next() else { return nil }
        return (keyvalue.key as! String, MyJSONValue(sanitized: keyvalue.value))
    }
}

// //////////////////////////////////////////////////////////////////////

fileprivate struct U {
    
    // See JSONSerialization.data() description.
    fileprivate static func serializeAsData(_ value: Any, pretty: Bool = false) throws -> Data {
        return try JSONSerialization.data(withJSONObject: value, options: (pretty ? [.prettyPrinted]: []))
    }
    
    fileprivate static func serializeAsString(_ value: Any, pretty: Bool = false) throws -> String {
        let data = try serializeAsData(value, pretty: pretty)
        guard let ret = String(data: data, encoding: .utf8) else {
            throw JSONException.InvalidCharacterEncoding
        }
        return ret
    }
    
    fileprivate static func stringArray(_ value: Any?) -> [String]? {
        guard let a = value as? NSArray else { return nil }
        var ret = [String]()
        ret.reserveCapacity(a.count)
        for elm in a {
            guard let s = elm as? String else { return nil }
            ret.append(s)
        }
        return ret
    }
    
    fileprivate static func isBool(_ v: NSNumber) -> Bool {
        return MyJSONValue.boolType == v.objCType.pointee
    }
}

// //////////////////////////////////////////////////////////////////////

