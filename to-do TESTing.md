# To-Do: Testing

## Targeted Test List

1. **DNSEngine**
   - Add tests for `updateRecord`, `signZone`, and `verifyZone` to ensure record updates and DNSSEC signing/verification work as intended
   - Cover `handleQuery` branches for AAAA and CNAME records, plus invalid-query logging

2. **DNSHandler**
   - Write NIO pipeline tests verifying that `channelRead` forwards responses and `channelReadComplete` flushes writes

3. ~~**DNSSECSigner**~~
   - ~~Create tests for `sign(zone:)` and `verify(zone:signature:)` using generated key pairs to validate signing correctness~~

4. **DNSServer**
   - Implement integration tests that start the server, send UDP/TCP queries, and verify responses, covering `start` and `stop` paths

5. ~~**DNSMetrics**~~
   - ~~Add async tests for `wait(forQueries:timeout:)` ensuring it resolves after expected query counts or times out correctly~~

6. **ZoneManager**
   - Write tests for `updateRecord`, `record`, and persistence with optional signer, including file reload behavior when the YAML source changes

7. **RateLimiter Gateway Plugin**
   - Test `rateLimitStats` to confirm counters and JSON response formatting after simulated traffic

8. **BudgetBreaker Gateway Plugin**
   - Create unit tests for `budgetCheck` and `budgetHealth` to validate responses for valid/invalid bodies

9. **DestructiveGuardian Gateway Plugin**
   - Add tests for `guardianEvaluate` covering protected vs. unprotected paths, manual approvals, and audit logging side effects

10. **SecuritySentinel Gateway Plugin**
    - Implement tests exercising `sentinelConsult` decisions and router behavior for valid requests, malformed bodies, and unknown routes
