fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios build_dev

```sh
[bundle exec] fastlane ios build_dev
```

Build the app for development

### ios build_only

```sh
[bundle exec] fastlane ios build_only
```

Build the app for TestFlight (without upload)

### ios testflight_xcode

```sh
[bundle exec] fastlane ios testflight_xcode
```

Build and upload to TestFlight using Xcode archive

### ios testflight

```sh
[bundle exec] fastlane ios testflight
```

Build and upload to TestFlight

### ios fix_build

```sh
[bundle exec] fastlane ios fix_build
```

Fix common build issues

### ios resolve_dependencies

```sh
[bundle exec] fastlane ios resolve_dependencies
```

Resolve SPM dependencies

### ios validate

```sh
[bundle exec] fastlane ios validate
```

Validate the app before submission

### ios upload_ipa

```sh
[bundle exec] fastlane ios upload_ipa
```



### ios test_all

```sh
[bundle exec] fastlane ios test_all
```

Run all tests

### ios test_unit

```sh
[bundle exec] fastlane ios test_unit
```

Run unit tests only

### ios test_integration

```sh
[bundle exec] fastlane ios test_integration
```

Run integration tests

### ios test_performance

```sh
[bundle exec] fastlane ios test_performance
```

Run performance tests

### ios test_snapshots

```sh
[bundle exec] fastlane ios test_snapshots
```

Run snapshot tests

### ios test_security

```sh
[bundle exec] fastlane ios test_security
```

Run security tests

### ios test_ui_matrix

```sh
[bundle exec] fastlane ios test_ui_matrix
```

Run UI tests on multiple devices

### ios ci_pr

```sh
[bundle exec] fastlane ios ci_pr
```

CI - Pull Request validation

### ios ci_nightly

```sh
[bundle exec] fastlane ios ci_nightly
```

CI - Nightly build and test

### ios coverage_report

```sh
[bundle exec] fastlane ios coverage_report
```

Generate test coverage report

### ios danger_check

```sh
[bundle exec] fastlane ios danger_check
```

Run Danger for PR review

### ios setup_tests

```sh
[bundle exec] fastlane ios setup_tests
```

Setup test environment

### ios clean_tests

```sh
[bundle exec] fastlane ios clean_tests
```

Clean test artifacts

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
