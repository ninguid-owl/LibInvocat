//
//  AbstractSyntaxTests.swift
//  LibInvocat
//

import XCTest
@testable import LibInvocat

class AbstractSyntaxTests: XCTestCase {
    var evaluator: Evaluator = Evaluator()

    let val_none = ""
    let val_moon = "moon"
    let val_iad = " in a dewdrop"
    let val_dot = "."
    var val_mooniad: String { return "\(val_moon)\(val_iad)" }
    var val_mooniaddot: String { return "\(val_mooniad)\(val_dot)" }
    let val_stars = "stars"
    let val_x = "x"
    let val_y = "y"
    let val_a = "a"
    let val_b = "b"
    let val_ref_x = "(x)"

    var lit_moon: InvExp { return .literal(val_moon) }
    var lit_iad: InvExp { return .literal(val_iad) }
    var lit_stars: InvExp { return .literal(val_stars) }
    var lit_dot: InvExp { return .literal(val_dot) }
    var lit_mooniaddot: InvExp { return .literal(val_mooniaddot) }

    var ref_x: InvExp { return .reference(.literal(val_x)) }
    var ref_y: InvExp { return .reference(.literal(val_y)) }
    var ref_a: InvExp { return .reference(.literal(val_a)) }

    var mix_mooniad: InvExp { return .mix(lit_moon, lit_iad) }
    var mix_mooniaddot: InvExp { return .mix(mix_mooniad, lit_dot) }

    var def_x1: InvExp { return .definition(val_x, [lit_moon]) }
    var def_x2: InvExp { return .definition(val_x, [lit_moon, lit_stars]) }
    var def_y: InvExp { return .definition(val_y, [mix_mooniad, ref_x]) }

    var evd_a: InvExp { return .evaluatingDefinition(val_a, [lit_moon, lit_stars]) }
    var evd_b: InvExp { return .evaluatingDefinition(val_b, [mix_mooniaddot, ref_a]) }

    var sel_x1: InvExp { return .selection(val_x, [lit_moon]) }
    var sel_x3: InvExp { return .selection(val_x, [mix_mooniaddot, ref_a]) }

    var evs_x1: InvExp { return .evaluatingSelection(val_x, [lit_moon]) }
    var evs_x4: InvExp { return .evaluatingSelection(val_x, [mix_mooniaddot, ref_a]) }

    var drw_x2: InvExp { return .draw(.literal(val_x)) }

    var env0: InvState = [:]
    var env_x1: InvState { return [val_x: [lit_moon]] }
    var env_x1b: InvState { return [val_x: [lit_stars]] }
    var env_x2: InvState { return [val_x: [lit_moon, lit_stars]] }
    var env_x2y: InvState { return [val_x: [lit_moon, lit_stars], val_y: [mix_mooniad, ref_x]] }
    var env_a: InvState { return [val_a: [lit_moon, lit_stars]] }
    var env_ab: InvState { return [val_a: [lit_moon, lit_stars], val_b: [lit_mooniaddot, lit_moon]] }
    var env_ax3: InvState { return [val_a: [lit_moon, lit_stars], val_x: [mix_mooniaddot]] }
    var env_ax4: InvState { return [val_a: [lit_moon, lit_stars], val_x: [lit_mooniaddot]] }


    override func setUp() {
        super.setUp()
        // Initialize the random source before each test
        self.evaluator = Evaluator(seed: "Atrament")
    }

    // Helper function to evaluate an expression and compare the
    // results to an expected state and value
    func checkEval(_ expr: InvExp, in initialState: InvState,
                   expecting result: (state: InvState, value: String)) {
        let (state, _value) = evaluator.eval(expr, in: initialState)
        let value = _value ?? ""
        XCTAssertEqual(value, result.value,
                       "\n\nExpected value \(result.value); got \(value)\n\n")
        XCTAssertEqual(state.description, result.state.description,
                       "\n\nExpected state \(result.state); got \(state)\n\n")
    }

    func testLiteral() {
        // A literal evaluates to itself
        checkEval(lit_moon, in: env0, expecting: (env0, val_moon))
    }

    func testMix() {
        // A mix evaluates to the concatentation of its (evaluated) components
        checkEval(mix_mooniad, in: env0, expecting: (env0, val_mooniad))
        checkEval(mix_mooniaddot, in: env0, expecting: (env0, val_mooniaddot))
    }

    func testDefinition() {
        // A definition updates the state with name: [item]
        checkEval(def_x1, in: env0, expecting: (env_x1, val_none))
        checkEval(def_x2, in: env_x1, expecting: (env_x2, val_none))
        checkEval(def_y, in: env_x2, expecting: (env_x2y, val_none))
    }

    func testEvaluatingDefinition() {
        // An evaluating definition updates the state with
        // name: [evaluated-item]
        checkEval(evd_a, in: env0, expecting: (env_a, val_none))
        checkEval(evd_b, in: env_a, expecting: (env_ab, val_none))
    }

    func testSelection() {
        // A selection updates the state with name: selected-item
        checkEval(sel_x1, in: env0, expecting: (env_x1, val_none))
        checkEval(sel_x3, in: env_a, expecting: (env_ax3, val_none))
    }

    func testEvaluatingSelection() {
        // An evaluating selection updates the state with
        // name: evaluated-selected-item
        checkEval(evs_x1, in: env0, expecting: (env_x1, val_none))
        checkEval(evs_x4, in: env_a, expecting: (env_ax4, val_none))
    }

    func testReference() {
        // Referenced definition doesn't exist yet -> literal reference
        checkEval(ref_x, in: env0, expecting: (env0, val_ref_x))
        // A reference selects from the def randomly and evaluates the result
        checkEval(ref_y, in: env_x2y, expecting: (env_x2y, val_mooniad))
        checkEval(ref_y, in: env_x2y, expecting: (env_x2y, val_stars))
        checkEval(ref_y, in: env_x2y, expecting: (env_x2y, val_stars))
        checkEval(ref_y, in: env_x2y, expecting: (env_x2y, val_moon))
    }

    func testDraw() {
        // A draw selects one item, removes it from the definition, and
        // evaluates it
        checkEval(drw_x2, in: env_x2, expecting: (env_x1b, val_moon))
        checkEval(drw_x2, in: env_x1b, expecting: (env0, val_stars))
    }

    func testEmptyEvaluatorSeed() {
        // Using the empty string as a seed value results in a runtime error, so
        // it's silently replaced in the Evaluator constructor.
        let _ = Evaluator(seed: "")
    }

    // Enumerate tests for Linux
    static var allTests = [
        ("testLiteral", testLiteral),
        ("testMix", testMix),
        ("testDefinition", testDefinition),
        ("testEvaluatingDefinition", testEvaluatingDefinition),
        ("testSelection", testSelection),
        ("testEvaluatingSelection", testEvaluatingSelection),
        ("testReference", testReference),
        ("testDraw", testDraw),
        ("testEmptyEvaluatorSeed", testEmptyEvaluatorSeed),
    ]
}
