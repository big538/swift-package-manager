/*
 This source file is part of the Swift.org open source project

 Copyright 2015 - 2016 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See http://swift.org/LICENSE.txt for license information
 See http://swift.org/CONTRIBUTORS.txt for Swift project authors
 */

import XCTest

import Basic
import PackageModel
import PackageLoading

private extension Module {
    convenience init(name: String, deps: Module...) throws {
        try self.init(name: name, type: .library, sources: Sources(paths: [], root: AbsolutePath("/")), dependencies: deps)
    }
}

func testModules(file: StaticString = #file, line: UInt = #line, body: () throws -> Void) {
    do {
        try body()
    } catch {
        XCTFail("\(error)", file: file, line: line)
    }
}

class ModuleDependencyTests: XCTestCase {

    func test1() {
        testModules {
            let t1 = try Module(name: "t1")
            let t2 = try Module(name: "t2", deps: t1)
            let t3 = try Module(name: "t3", deps: t2)

            XCTAssertEqual(t3.recursiveDeps, [t2, t1])
            XCTAssertEqual(t2.recursiveDeps, [t1])
        }
    }

    func test2() {
        testModules {
            let t1 = try Module(name: "t1")
            let t2 = try Module(name: "t2", deps: t1)
            let t3 = try Module(name: "t3", deps: t2, t1)
            let t4 = try Module(name: "t4", deps: t2, t3, t1)

            XCTAssertEqual(t4.recursiveDeps, [t3, t2, t1])
            XCTAssertEqual(t3.recursiveDeps, [t2, t1])
            XCTAssertEqual(t2.recursiveDeps, [t1])
        }
    }

    func test3() {
        testModules {
            let t1 = try Module(name: "t1")
            let t2 = try Module(name: "t2", deps: t1)
            let t3 = try Module(name: "t3", deps: t2, t1)
            let t4 = try Module(name: "t4", deps: t1, t2, t3)

            XCTAssertEqual(t4.recursiveDeps, [t3, t2, t1])
            XCTAssertEqual(t3.recursiveDeps, [t2, t1])
            XCTAssertEqual(t2.recursiveDeps, [t1])
        }
    }

    func test4() {
        testModules {
            let t1 = try Module(name: "t1")
            let t2 = try Module(name: "t2", deps: t1)
            let t3 = try Module(name: "t3", deps: t2)
            let t4 = try Module(name: "t4", deps: t3)

            XCTAssertEqual(t4.recursiveDeps, [t3, t2, t1])
            XCTAssertEqual(t3.recursiveDeps, [t2, t1])
            XCTAssertEqual(t2.recursiveDeps, [t1])
        }
    }

    func test5() {
        testModules {
            let t1 = try Module(name: "t1")
            let t2 = try Module(name: "t2", deps: t1)
            let t3 = try Module(name: "t3", deps: t2)
            let t4 = try Module(name: "t4", deps: t3)
            let t5 = try Module(name: "t5", deps: t2)
            let t6 = try Module(name: "t6", deps: t5, t4)

            // precise order is not important, but it is important that the following are true
            let t6rd = t6.recursiveDeps
            XCTAssertEqual(t6rd.index(of: t3)!, t6rd.index(after: t6rd.index(of: t4)!))
            XCTAssert(t6rd.index(of: t5)! < t6rd.index(of: t2)!)
            XCTAssert(t6rd.index(of: t5)! < t6rd.index(of: t1)!)
            XCTAssert(t6rd.index(of: t2)! < t6rd.index(of: t1)!)
            XCTAssert(t6rd.index(of: t3)! < t6rd.index(of: t2)!)

            XCTAssertEqual(t5.recursiveDeps, [t2, t1])
            XCTAssertEqual(t4.recursiveDeps, [t3, t2, t1])
            XCTAssertEqual(t3.recursiveDeps, [t2, t1])
            XCTAssertEqual(t2.recursiveDeps, [t1])
        }
    }

    func test6() {
        testModules {
            let t1 = try Module(name: "t1")
            let t2 = try Module(name: "t2", deps: t1)
            let t3 = try Module(name: "t3", deps: t2)
            let t4 = try Module(name: "t4", deps: t3)
            let t5 = try Module(name: "t5", deps: t2)
            let t6 = try Module(name: "t6", deps: t4, t5) // same as above, but these two swapped

            // precise order is not important, but it is important that the following are true
            let t6rd = t6.recursiveDeps
            XCTAssertEqual(t6rd.index(of: t3)!, t6rd.index(after: t6rd.index(of: t4)!))
            XCTAssert(t6rd.index(of: t5)! < t6rd.index(of: t2)!)
            XCTAssert(t6rd.index(of: t5)! < t6rd.index(of: t1)!)
            XCTAssert(t6rd.index(of: t2)! < t6rd.index(of: t1)!)
            XCTAssert(t6rd.index(of: t3)! < t6rd.index(of: t2)!)

            XCTAssertEqual(t5.recursiveDeps, [t2, t1])
            XCTAssertEqual(t4.recursiveDeps, [t3, t2, t1])
            XCTAssertEqual(t3.recursiveDeps, [t2, t1])
            XCTAssertEqual(t2.recursiveDeps, [t1])
        }
    }

    static var allTests = [
        ("test1", test1),
        ("test2", test2),
        ("test3", test3),
        ("test4", test4),
        ("test5", test5),
        ("test6", test6),
    ]
}

private extension Module {
    var recursiveDeps: [Module] {
        // FIXME: Eliminate this, it is a bad historical artifact.
        return recursiveDependencies.reversed()
    }
}
