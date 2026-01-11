# Testing Guide

This document provides information about testing the Hotel Management System Flutter application.

## Test Structure

```
test/
├── models/              # Unit tests for data models
│   └── guest_model_test.dart
├── services/            # Unit tests for services
│   └── guest_service_test.dart
└── widgets/             # Widget tests
    └── guest_card_test.dart
```

## Running Tests

### Run all tests
```bash
flutter test
```

### Run specific test file
```bash
flutter test test/models/guest_model_test.dart
```

### Run tests with coverage
```bash
flutter test --coverage
```

### Generate coverage report
```bash
genhtml coverage/lcov.info -o coverage/html
```

## Test Categories

### Unit Tests
- **Models**: Test JSON serialization/deserialization, copyWith methods, helper methods
- **Services**: Test API calls, offline storage, sync operations, error handling
- **Providers**: Test state management, data loading, error states

### Widget Tests
- Test widget rendering
- Test user interactions
- Test state changes

### Integration Tests
- Test complete user flows
- Test API integrations
- Test offline/online scenarios

## Writing Tests

### Example: Model Test
```dart
test('should create model from JSON', () {
  final json = {'id': 1, 'name': 'Test'};
  final model = Model.fromJson(json);
  expect(model.id, equals(1));
  expect(model.name, equals('Test'));
});
```

### Example: Service Test
```dart
test('should fetch data from API', () async {
  final service = Service();
  final data = await service.fetchData();
  expect(data, isNotNull);
});
```

### Example: Widget Test
```dart
testWidgets('should display widget', (WidgetTester tester) async {
  await tester.pumpWidget(MyWidget());
  expect(find.text('Hello'), findsOneWidget);
});
```

## Testing Best Practices

1. **Test Coverage**: Aim for at least 80% code coverage
2. **Test Independence**: Each test should be independent and not rely on others
3. **Clear Test Names**: Use descriptive names that explain what is being tested
4. **Arrange-Act-Assert**: Structure tests with clear sections
5. **Mock External Dependencies**: Use mocks for API calls, database operations
6. **Test Edge Cases**: Include tests for null values, empty lists, error conditions

## Continuous Integration

Tests should be run automatically on:
- Pull requests
- Commits to main branch
- Before deployments

## Performance Testing

- Test app startup time
- Test data loading performance
- Test offline sync performance
- Test memory usage

## Platform-Specific Testing

- **iOS**: Test on iOS devices/simulators
- **Android**: Test on Android devices/emulators
- **Web**: Test in Chrome, Firefox, Safari
- **Desktop**: Test on Windows, macOS, Linux

## Troubleshooting

### Common Issues

1. **Tests timeout**: Increase timeout duration or optimize test code
2. **Hive initialization errors**: Ensure Hive is initialized in setUp
3. **Network errors in tests**: Use mocks for API services
4. **Flaky tests**: Ensure tests are deterministic and independent

## Next Steps

- [ ] Add integration tests
- [ ] Add performance tests
- [ ] Set up CI/CD test pipeline
- [ ] Add snapshot tests for UI components
- [ ] Add accessibility tests


