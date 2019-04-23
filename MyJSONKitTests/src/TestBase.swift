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

open class TestBase : XCTestCase {
    open var DEBUGGING: Bool {
        return false
    }
    
    func DEBUG(_ msg: String) {
        if DEBUGGING {
            print(msg)
        }
    }

    func subtest(_ msg: String = "", _ test: () throws -> Void) throws {
        try test()
    }
    
    func subtest(_ msg: String = "", _ test: () -> Void) {
        test()
    }

    func testResPath(_ rpath: String? = nil) -> String {
        guard var url = Bundle(for: TestBase.self).resourceURL?.appendingPathComponent("resources.bundle", isDirectory: true) else {
            preconditionFailure()
        }
        if rpath != nil {
            url = url.appendingPathComponent(rpath!, isDirectory: false)
        }
        return url.path
    }
    
    func testResData(_ rpath: String? = nil) throws -> Data {
        guard let data = FileManager.default.contents(atPath: testResPath(rpath)) else {
            preconditionFailure()
        }
        return data
    }
    
}
