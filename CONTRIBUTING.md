# Contributing to TeleDrive

Thanks for your interest in improving TeleDrive.

## Before you start

- Search existing issues before opening a new one.
- For bugs, include the Android version, device/emulator details, TeleDrive version, and clear reproduction steps.
- For larger features or architectural changes, open an issue first so the approach can be discussed before implementation.
- Never include Telegram API credentials, phone numbers, session files, tokens, or other secrets in issues, logs, screenshots, or commits.

## Development setup

1. Fork or clone the repository.
2. Install the latest stable Flutter SDK and Android Studio / Android SDK.
3. Run:

   ```bash
   flutter pub get
   ```

4. Configure your own Telegram API ID and API Hash from [my.telegram.org](https://my.telegram.org/).
5. Run the application on an Android emulator or device:

   ```bash
   flutter run
   ```

## Code quality

Before opening a pull request, please run:

```bash
flutter analyze
flutter test
```

If a test cannot be added for a change, explain why in the pull request description and include clear manual verification steps.

## Pull requests

Keep pull requests focused on one change where possible. A useful pull request description should include:

- What changed.
- Why the change is needed.
- How it was tested.
- Screenshots or recordings for user-interface changes when relevant.
- Any known limitations or follow-up work.

Please avoid unrelated formatting or refactoring in the same pull request unless it is necessary for the change.

## Issues and feature requests

Feature requests are welcome. Describe the user problem first, then the proposed behavior. For transfer-related features, note expected behavior for large files, interrupted transfers, and Android background restrictions when relevant.

## Security and privacy

TeleDrive interacts with Telegram accounts and locally stored session information. Do not publish sensitive account data in public issues. If you discover a security issue that would expose credentials, sessions, or user files, avoid posting exploit details publicly until the maintainer has had a reasonable opportunity to investigate.

## License

By contributing to TeleDrive, you agree that your contributions will be licensed under the MIT License used by this repository.
