# [Networking] FDC integration/update

## Endpoints
- [/foods/search] or [/food/{fdcId}]
- Request model + query params documented
- Response parsing and unknown fields safely handled

## Rate Limiting & Retries
- [ ] 429/5xx → one retry with jittered backoff
- [ ] Idempotent calls only retried
- [ ] Errors mapped to user-facing states

## Caching
- [ ] SwiftData cache layer with 7-day TTL
- [ ] Read-through + write-through paths covered by tests
- [ ] Cache expiry/refresh behavior validated

## Security
- [ ] FDC_API_KEY loaded via config/secrets (not hardcoded)
- [ ] Logs redact API key and PII

## Tests
- [ ] Parsing unit tests
- [ ] Cache TTL + expiry tests
- [ ] Connectivity/offline behavior manual QA

## UI/UX
- [ ] Loading/empty/error states wired to client
- [ ] Debounced search (300–500ms) verified
