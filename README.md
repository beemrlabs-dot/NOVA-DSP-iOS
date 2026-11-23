# NOVA DSP — iOS starter project

Native SwiftUI iPhone app with an AVAudioEngine / AVAudioUnitEQ processing chain and an initial CarPlay audio-app scene.

## Included

- Dark NOVA DSP interface
- 10-band EQ (31 Hz to 16 kHz), ±12 dB per band
- Output preamp control
- Flat, Bass Boost, Vocal, Rock, Pop, Jazz, Classical and Night Drive presets
- Audio file import and playback through the DSP engine
- Initial CarPlay preset list
- Audio background mode declaration
- Shared Xcode scheme: `NOVADSP`
- GitHub Actions workflow at `.github/workflows/ios-build.yml`

## Audio limitation

This app cannot intercept and EQ audio from unrelated iPhone apps such as Spotify, YouTube or Apple Music. iOS does not provide a public system-wide audio-processing API for this use case. The DSP chain processes audio routed through NOVA DSP itself.

## Build with GitHub Actions

1. Create a GitHub repository (for example, `NOVA-DSP-iOS`).
2. Upload the contents of this folder to the repository root, including the hidden `.github` folder.
3. Push to the `main` or `master` branch, or open **Actions → NOVA DSP iOS Build → Run workflow**.
4. When the workflow completes, open its run and download the `NOVA-DSP-unsigned-iphone-build` artifact.

The workflow uses a GitHub-hosted macOS runner and Xcode to build both the iOS Simulator target and an unsigned iPhone-device target. The unsigned `.app` artifact is for build validation; it is **not installable on an iPhone** until it is signed with a matching Apple certificate and provisioning profile.

## Signing and installation

To create an installable IPA, configure an Apple signing certificate and matching provisioning profile, then add them as encrypted GitHub Actions secrets and extend the workflow with an export step. Do not commit certificates, private keys, or provisioning profiles to the repository.

## CarPlay requirements

The CarPlay scene in this starter project is not an entitlement grant. Apple must approve the relevant CarPlay entitlement and it must be included in the App ID and provisioning profile before the app can appear in CarPlay. Apple requires a manually managed provisioning profile for CarPlay apps. Apply through https://developer.apple.com/contact/carplay.

## Current status

This is a starter project, not a tested App Store release. Swift source syntax and the Xcode project file have been checked in this environment, but a full Apple SDK build has not yet been run. GitHub Actions performs that build using Xcode on macOS.
