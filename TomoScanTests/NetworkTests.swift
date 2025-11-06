//
//  NetworkTests.swift
//  TomoScanTests
//
//  Tests pour la connectivité réseau et retry
//

import XCTest
@testable import Aidoku

final class NetworkTests: XCTestCase {
    
    // MARK: - Reachability Tests
    
    func testReachabilityExists() {
        // Test que la classe Reachability existe et peut être utilisée
        let connectionType = Reachability.getConnectionType()
        
        // Le type de connexion devrait être l'un des trois types
        let validTypes: [NetworkDataType] = [.none, .cellular, .wifi]
        XCTAssertTrue(validTypes.contains(connectionType), "Connection type should be valid")
    }
    
    func testNetworkDataTypeValues() {
        // Test que tous les types de réseau existent
        let types: [NetworkDataType] = [.none, .cellular, .wifi]
        XCTAssertEqual(types.count, 3, "Should have 3 network types")
    }
    
    // MARK: - Error Manager Tests
    
    func testErrorManagerSingleton() {
        let instance1 = ErrorManager.shared
        let instance2 = ErrorManager.shared
        
        XCTAssertTrue(instance1 === instance2, "ErrorManager should be a singleton")
    }
    
    func testErrorManagerInitialState() {
        let errorManager = ErrorManager.shared
        errorManager.clearError() // Reset state
        
        XCTAssertNil(errorManager.currentError, "Initial error should be nil")
        XCTAssertFalse(errorManager.showError, "showError should be false initially")
    }
    
    func testErrorManagerHandleError() {
        let errorManager = ErrorManager.shared
        errorManager.clearError()
        
        let testError = SupabaseError.networkError
        errorManager.handleError(testError, context: "Test")
        
        // Attendre que le main thread mette à jour
        let expectation = XCTestExpectation(description: "Error should be set")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertNotNil(errorManager.currentError)
            XCTAssertTrue(errorManager.showError)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testErrorManagerClearError() {
        let errorManager = ErrorManager.shared
        
        // Set an error
        errorManager.handleError(SupabaseError.networkError, context: "Test")
        
        // Clear it
        errorManager.clearError()
        
        let expectation = XCTestExpectation(description: "Error should be cleared")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertNil(errorManager.currentError)
            XCTAssertFalse(errorManager.showError)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - UserFacingError Tests
    
    func testUserFacingErrorFromNetworkError() {
        let error = SupabaseError.networkError
        let userError = UserFacingError(from: error, context: "Test")
        
        XCTAssertEqual(userError.title, "Pas de connexion")
        XCTAssertEqual(userError.icon, "wifi.slash")
        XCTAssertFalse(userError.message.isEmpty)
    }
    
    func testUserFacingErrorFromAuthError() {
        let error = SupabaseError.authenticationFailed
        let userError = UserFacingError(from: error, context: "Test")
        
        XCTAssertEqual(userError.title, "Session expirée")
        XCTAssertEqual(userError.icon, "person.crop.circle.badge.xmark")
        XCTAssertFalse(userError.message.isEmpty)
    }
    
    func testUserFacingErrorFromInvalidResponse() {
        let error = SupabaseError.invalidResponse
        let userError = UserFacingError(from: error, context: "Test")
        
        XCTAssertEqual(userError.title, "Erreur serveur")
        XCTAssertEqual(userError.icon, "exclamationmark.triangle")
        XCTAssertFalse(userError.message.isEmpty)
    }
    
    func testUserFacingErrorFromInvalidData() {
        let error = SupabaseError.invalidData
        let userError = UserFacingError(from: error, context: "Test")

        XCTAssertEqual(userError.title, "Erreur de données")
        XCTAssertEqual(userError.icon, "doc.badge.exclamationmark")
        XCTAssertFalse(userError.message.isEmpty)
    }

    func testUserFacingErrorFromProfileNotFound() {
        let error = SupabaseError.profileNotFound
        let userError = UserFacingError(from: error, context: "Test")

        XCTAssertEqual(userError.title, "Profil introuvable")
        XCTAssertEqual(userError.icon, "person.crop.circle.badge.questionmark")
        XCTAssertFalse(userError.message.isEmpty)
    }
    
    func testUserFacingErrorHasUniqueID() {
        let error = SupabaseError.networkError
        let userError1 = UserFacingError(from: error, context: "Test1")
        let userError2 = UserFacingError(from: error, context: "Test2")
        
        XCTAssertNotEqual(userError1.id, userError2.id, "Each error should have unique ID")
    }
    
    // MARK: - Retry Logic Tests
    
    func testRetryLogicWithSuccess() async throws {
        var attemptCount = 0
        
        let result = try await performTestRetry(maxRetries: 3) {
            attemptCount += 1
            if attemptCount < 2 {
                throw SupabaseError.networkError
            }
            return "Success"
        }
        
        XCTAssertEqual(result, "Success")
        XCTAssertEqual(attemptCount, 2, "Should succeed on second attempt")
    }
    
    func testRetryLogicWithAuthError() async {
        var attemptCount = 0
        
        do {
            _ = try await performTestRetry(maxRetries: 3) {
                attemptCount += 1
                throw SupabaseError.authenticationFailed
            }
            XCTFail("Should throw authentication error")
        } catch {
            XCTAssertEqual(attemptCount, 1, "Should not retry auth errors")
        }
    }
    
    func testRetryLogicMaxAttempts() async {
        var attemptCount = 0
        
        do {
            _ = try await performTestRetry(maxRetries: 3) {
                attemptCount += 1
                throw SupabaseError.networkError
            }
            XCTFail("Should throw after max retries")
        } catch {
            XCTAssertEqual(attemptCount, 3, "Should attempt exactly 3 times")
        }
    }
    
    // MARK: - Helper Methods
    
    private func performTestRetry<T>(
        maxRetries: Int = 3,
        retryDelay: TimeInterval = 0.1,
        operation: () async throws -> T
    ) async throws -> T {
        var lastError: Error?
        
        for attempt in 1...maxRetries {
            do {
                return try await operation()
            } catch {
                lastError = error
                
                if let supabaseError = error as? SupabaseError,
                   supabaseError == .authenticationFailed || supabaseError == .notAuthenticated {
                    throw error
                }
                
                if attempt < maxRetries {
                    try? await Task.sleep(nanoseconds: UInt64(retryDelay * 1_000_000_000))
                }
            }
        }
        
        throw lastError ?? SupabaseError.networkError
    }
}

