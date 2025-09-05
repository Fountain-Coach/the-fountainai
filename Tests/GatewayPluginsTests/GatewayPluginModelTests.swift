import XCTest
@testable import AuthGatewayPlugin
@testable import BudgetBreakerGatewayPlugin
@testable import DestructiveGuardianGatewayPlugin
@testable import LLMGatewayPlugin
@testable import PayloadInspectionGatewayPlugin
@testable import RateLimiterGatewayPlugin
@testable import RoleHealthCheckGatewayPlugin
@testable import SecuritySentinelGatewayPlugin

final class AuthGatewayPluginModelTests: XCTestCase {
    func testAuthModelsCodable() throws {
        let validate = ValidateRequest(token: "t")
        let validateData = try JSONEncoder().encode(validate)
        let validateDecoded = try JSONDecoder().decode(ValidateRequest.self, from: validateData)
        XCTAssertEqual(validateDecoded.token, "t")

        let validation = ValidationResponse(valid: true, role: "admin")
        let validationData = try JSONEncoder().encode(validation)
        let validationDecoded = try JSONDecoder().decode(ValidationResponse.self, from: validationData)
        XCTAssertTrue(validationDecoded.valid)
        XCTAssertEqual(validationDecoded.role, "admin")

        let claims = ClaimsResponse(role: nil, scopes: ["s1", "s2"])
        let claimsData = try JSONEncoder().encode(claims)
        let claimsDecoded = try JSONDecoder().decode(ClaimsResponse.self, from: claimsData)
        XCTAssertNil(claimsDecoded.role)
        XCTAssertEqual(claimsDecoded.scopes, ["s1", "s2"])
    }
}

final class BudgetBreakerGatewayPluginModelTests: XCTestCase {
    func testBudgetModelsCodable() throws {
        let request = BudgetCheckRequest(routeId: "r", clientId: "c", amount: 5)
        let requestData = try JSONEncoder().encode(request)
        let requestDecoded = try JSONDecoder().decode(BudgetCheckRequest.self, from: requestData)
        XCTAssertEqual(requestDecoded.routeId, "r")
        XCTAssertEqual(requestDecoded.clientId, "c")
        XCTAssertEqual(requestDecoded.amount, 5)

        let response = BudgetCheckResponse(allowed: false, remaining: 10)
        let responseData = try JSONEncoder().encode(response)
        let responseDecoded = try JSONDecoder().decode(BudgetCheckResponse.self, from: responseData)
        XCTAssertFalse(responseDecoded.allowed)
        XCTAssertEqual(responseDecoded.remaining, 10)

        let health = BudgetHealthResponse(status: "ok")
        let healthData = try JSONEncoder().encode(health)
        let healthDecoded = try JSONDecoder().decode(BudgetHealthResponse.self, from: healthData)
        XCTAssertEqual(healthDecoded.status, "ok")
    }
}

final class DestructiveGuardianGatewayPluginModelTests: XCTestCase {
    func testGuardianModelsCodable() throws {
        let request = GuardianEvaluateRequest(method: "POST", path: "/p", manualApproval: true, serviceToken: "s")
        let requestData = try JSONEncoder().encode(request)
        let requestDecoded = try JSONDecoder().decode(GuardianEvaluateRequest.self, from: requestData)
        XCTAssertEqual(requestDecoded.method, "POST")
        XCTAssertEqual(requestDecoded.path, "/p")
        XCTAssertEqual(requestDecoded.manualApproval, true)
        XCTAssertEqual(requestDecoded.serviceToken, "s")

        let response = GuardianEvaluateResponse(decision: "allow")
        let responseData = try JSONEncoder().encode(response)
        let responseDecoded = try JSONDecoder().decode(GuardianEvaluateResponse.self, from: responseData)
        XCTAssertEqual(responseDecoded.decision, "allow")
    }
}

final class LLMGatewayPluginModelTests: XCTestCase {
    func testMessageAndFunctionObjectsCodable() throws {
        let msg = MessageObject(role: "user", content: "hello")
        let msgData = try JSONEncoder().encode(msg)
        let msgDecoded = try JSONDecoder().decode(MessageObject.self, from: msgData)
        XCTAssertEqual(msgDecoded.role, "user")
        XCTAssertEqual(msgDecoded.content, "hello")

        let funcObj = FunctionObject(name: "f", description: "d")
        let funcData = try JSONEncoder().encode(funcObj)
        let funcDecoded = try JSONDecoder().decode(FunctionObject.self, from: funcData)
        XCTAssertEqual(funcDecoded.name, "f")
        XCTAssertEqual(funcDecoded.description, "d")

        let callObj = FunctionCallObject(name: "g")
        let callData = try JSONEncoder().encode(callObj)
        let callDecoded = try JSONDecoder().decode(FunctionCallObject.self, from: callData)
        XCTAssertEqual(callDecoded.name, "g")
    }

    func testFunctionCallCoding() throws {
        let autoCall = FunctionCall.auto
        let autoData = try JSONEncoder().encode(autoCall)
        let autoDecoded = try JSONDecoder().decode(FunctionCall.self, from: autoData)
        if case .auto = autoDecoded {} else { XCTFail("expected auto") }

        let namedCall = FunctionCall.named(FunctionCallObject(name: "x"))
        let namedData = try JSONEncoder().encode(namedCall)
        let namedDecoded = try JSONDecoder().decode(FunctionCall.self, from: namedData)
        if case .named(let obj) = namedDecoded {
            XCTAssertEqual(obj.name, "x")
        } else {
            XCTFail("expected named")
        }
    }

    func testChatRequestCodable() throws {
        let msg = MessageObject(role: "user", content: "hi")
        let funcObj = FunctionObject(name: "f", description: nil)
        let request = ChatRequest(model: "m", messages: [msg], functions: [funcObj], function_call: .auto)
        let data = try JSONEncoder().encode(request)
        let decoded = try JSONDecoder().decode(ChatRequest.self, from: data)
        XCTAssertEqual(decoded.model, "m")
        XCTAssertEqual(decoded.messages.first?.content, "hi")
        XCTAssertEqual(decoded.functions?.first?.name, "f")
        if case .auto? = decoded.function_call {} else { XCTFail("expected auto") }
    }
}

final class PayloadInspectionGatewayPluginModelTests: XCTestCase {
    func testPayloadInspectionModelsCodable() throws {
        let request = PayloadInspectionRequest(payload: "data")
        let requestData = try JSONEncoder().encode(request)
        let requestDecoded = try JSONDecoder().decode(PayloadInspectionRequest.self, from: requestData)
        XCTAssertEqual(requestDecoded.payload, "data")

        let response = PayloadInspectionResponse(sanitized: "clean", violations: ["v1"])
        let responseData = try JSONEncoder().encode(response)
        let responseDecoded = try JSONDecoder().decode(PayloadInspectionResponse.self, from: responseData)
        XCTAssertEqual(responseDecoded.sanitized, "clean")
        XCTAssertEqual(responseDecoded.violations, ["v1"])
    }
}

final class RateLimiterGatewayPluginModelTests: XCTestCase {
    func testRateLimiterModelsCodable() throws {
        let request = RateLimitCheckRequest(routeId: "r", clientId: "c", limitPerMinute: 1)
        let requestData = try JSONEncoder().encode(request)
        let requestDecoded = try JSONDecoder().decode(RateLimitCheckRequest.self, from: requestData)
        XCTAssertEqual(requestDecoded.limitPerMinute, 1)

        let requestNil = RateLimitCheckRequest(routeId: "r", clientId: "c", limitPerMinute: nil)
        let requestNilData = try JSONEncoder().encode(requestNil)
        let requestNilDecoded = try JSONDecoder().decode(RateLimitCheckRequest.self, from: requestNilData)
        XCTAssertNil(requestNilDecoded.limitPerMinute)

        let response = RateLimitCheckResponse(allowed: true)
        let responseData = try JSONEncoder().encode(response)
        let responseDecoded = try JSONDecoder().decode(RateLimitCheckResponse.self, from: responseData)
        XCTAssertTrue(responseDecoded.allowed)

        let stats = RateLimitStatsResponse(allowed: 2, throttled: 3)
        let statsData = try JSONEncoder().encode(stats)
        let statsDecoded = try JSONDecoder().decode(RateLimitStatsResponse.self, from: statsData)
        XCTAssertEqual(statsDecoded.allowed, 2)
        XCTAssertEqual(statsDecoded.throttled, 3)
    }
}

final class RoleHealthCheckGatewayPluginModelTests: XCTestCase {
    func testRoleHealthCheckModelsCodable() throws {
        let request = RoleHealthCheckRequest(corpusId: "c", roleName: "r")
        let requestData = try JSONEncoder().encode(request)
        let requestDecoded = try JSONDecoder().decode(RoleHealthCheckRequest.self, from: requestData)
        XCTAssertEqual(requestDecoded.corpusId, "c")
        XCTAssertEqual(requestDecoded.roleName, "r")

        let info = RoleInfo(name: "n", prompt: "p")
        let infoData = try JSONEncoder().encode(info)
        let infoDecoded = try JSONDecoder().decode(RoleInfo.self, from: infoData)
        XCTAssertEqual(infoDecoded.name, "n")
        XCTAssertEqual(infoDecoded.prompt, "p")

        let nob = NoBody()
        let nobData = try JSONEncoder().encode(nob)
        _ = try JSONDecoder().decode(NoBody.self, from: nobData)
    }
}

final class SecuritySentinelGatewayPluginModelTests: XCTestCase {
    func testConsultRequestCodableAndValidate() throws {
        let request = ConsultRequest(summary: "s", context: "c")
        try request.validate()
        let data = try JSONEncoder().encode(request)
        let decoded = try JSONDecoder().decode(ConsultRequest.self, from: data)
        XCTAssertEqual(decoded.summary, "s")
        XCTAssertEqual(decoded.context, "c")
    }

    func testConsultRequestValidateFails() throws {
        let request = ConsultRequest(summary: " ", context: "c")
        XCTAssertThrowsError(try request.validate())
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
