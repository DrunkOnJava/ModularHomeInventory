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

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
