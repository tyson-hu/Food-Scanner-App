# [Scanner] Vision/VisionKit barcode flow

## Scope
- [ ] VisionKit `DataScannerViewController` (iOS 26)
- [ ] Vision `DetectBarcodesRequest` for UPC/EAN fallback (iOS 18+)
- [ ] Handoff to results → details → log

## UX / Accessibility
- [ ] Camera permissions prompt copy
- [ ] Haptics/feedback on capture
- [ ] VoiceOver labels; clear affordances to dismiss/pause

## Performance
- [ ] On-device processing; no main-thread stalls
- [ ] Memory/CPU observed during scan

## Tests
- [ ] Vision tests (mocks/stubs)
- [ ] UI smoke test for scan→result navigation
- [ ] Snapshot for results list

## Privacy
- [ ] No images persisted without consent
- [ ] Photo access usage strings present
