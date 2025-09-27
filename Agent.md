# Cursor Agent Rules for Food Scanner Project

## Documentation Reference Requirements

This document establishes rules for the Cursor agent to ensure comprehensive reference to the project's additional documentation when providing assistance with the Food Scanner iOS app.

## Mandatory Documentation Review

**CRITICAL**: Before providing any assistance with this project, the Cursor agent MUST:

1. **Always reference the AdditionalDocumentation folder** located at `/Users/tysonhu/Documents/XcodeProjects/Food Scanner/AdditionalDocumentation/`
2. **Review relevant documentation files** based on the user's request or context
3. **Apply best practices and patterns** from the documentation when making recommendations or code changes

## Documentation Categories and Usage

### Design and UI Guidelines
- **SwiftUI-Implementing-Liquid-Glass-Design.md**: Use for all UI/UX design decisions, especially when implementing modern iOS design patterns
- **UIKit-Implementing-Liquid-Glass-Design.md**: Reference when working with UIKit components
- **AppKit-Implementing-Liquid-Glass-Design.md**: For macOS-specific implementations
- **WidgetKit-Implementing-Liquid-Glass-Design.md**: For widget implementations
- **SwiftUI-New-Toolbar-Features.md**: When implementing toolbar functionality
- **SwiftUI-Styled-Text-Editing.md**: For text editing features

### Core Framework Updates
- **Swift-Concurrency-Updates.md**: Essential for all async/await implementations and concurrency patterns
- **SwiftData-Class-Inheritance.md**: When working with data models and persistence
- **Foundation-AttributedString-Updates.md**: For text formatting and attributed strings
- **FoundationModels-Using-on-device-LLM-in-your-app.md**: For AI/ML features and on-device processing

### System Integration
- **AppIntents-Updates.md**: For Siri integration, shortcuts, and system-wide functionality
- **SwiftUI-AlarmKit-Integration.md**: For alarm and notification features
- **SwiftUI-WebKit-Integration.md**: For web content integration
- **Implementing-Visual-Intelligence-in-iOS.md**: For camera and visual processing features
- **Implementing-Assistive-Access-in-iOS.md**: For accessibility features

### Data and Visualization
- **Swift-Charts-3D-Visualization.md**: For data visualization and charting
- **MapKit-GeoToolbox-PlaceDescriptors.md**: For location-based features
- **StoreKit-Updates.md**: For in-app purchases and subscriptions

### Platform-Specific Features
- **Widgets-for-visionOS.md**: For visionOS widget implementations
- **Swift-InlineArray-Span.md**: For performance optimization

## Implementation Rules

### 1. Design Consistency
- **ALWAYS** reference Liquid Glass design patterns when implementing UI components
- Apply modern iOS design principles from the SwiftUI documentation
- Ensure accessibility compliance using the Assistive Access guidelines

### 2. Concurrency Best Practices
- **MUST** follow Swift 6.2 concurrency patterns from the Swift-Concurrency-Updates.md
- Use `@MainActor` appropriately for UI-related code
- Implement proper error handling for async operations
- Apply the `@concurrent` attribute for background processing when needed

### 3. Data Management
- Follow SwiftData inheritance patterns when designing data models
- Use proper relationship management and query optimization
- Implement appropriate data migration strategies

### 4. System Integration
- Leverage AppIntents for system-wide functionality
- Implement proper Siri integration following the latest patterns
- Use visual intelligence features for camera-based functionality

### 5. Performance and Optimization
- Apply performance best practices from the documentation
- Use appropriate data structures and algorithms
- Implement proper caching strategies

## Code Review Checklist

Before suggesting any code changes, verify:

- [ ] Design patterns align with Liquid Glass guidelines
- [ ] Concurrency patterns follow Swift 6.2 best practices
- [ ] Data models use appropriate SwiftData patterns
- [ ] System integrations follow AppIntents guidelines
- [ ] Accessibility features are properly implemented
- [ ] Performance optimizations are applied where appropriate

## Documentation Search Strategy

When a user asks a question:

1. **Identify the relevant documentation category** based on the question context
2. **Search the AdditionalDocumentation folder** for related files
3. **Read and reference specific sections** that apply to the user's request
4. **Provide code examples** that follow the documented patterns
5. **Explain the reasoning** behind recommendations using documentation references

## Example Usage

**User Question**: "How should I implement a modern search interface?"

**Agent Response Process**:
1. Reference `SwiftUI-Implementing-Liquid-Glass-Design.md` for UI patterns
2. Check `SwiftUI-New-Toolbar-Features.md` for search toolbar implementation
3. Apply `Swift-Concurrency-Updates.md` patterns for search functionality
4. Provide code that follows the documented best practices

## Maintenance

This document should be updated whenever:
- New documentation files are added to the AdditionalDocumentation folder
- Significant changes are made to existing documentation
- New iOS features or frameworks are introduced to the project

## Enforcement

The Cursor agent is expected to:
- **Always** reference relevant documentation before providing assistance
- **Cite specific documentation files** when making recommendations
- **Follow the established patterns** rather than suggesting alternative approaches without justification
- **Update this document** when new documentation becomes available

---

**Remember**: The AdditionalDocumentation folder contains the latest Apple development guidelines and best practices. Always prioritize these resources over general knowledge when providing assistance with this Food Scanner project.
