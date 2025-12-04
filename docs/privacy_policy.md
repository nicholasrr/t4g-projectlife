Effective date: December 4, 2025

Short Play Store summary
-----------------------
Project: Life stores your tasks, categories and settings locally on your device only (no account required). No third-party analytics or ads are used; we do not collect or share personal information.

Full Privacy Policy — Project: Life
----------------------------------

Introduction
Project: Life ("we", "us", "our") provides a lightweight task and cadence tracker app (the "App"). This Privacy Policy explains how the App collects, uses, stores, and shares information when you use the App.

Data Controller / Contact
- Developer: Shrek da Baixada Fluminense
- Contact email: st4rl00p@gmail.com
- Effective date: December 4, 2025

Summary (plain language)
- What we collect: The App stores tasks, categories, time periods, and settings locally on your device.
- Why we collect it: To allow the App to function (persist tasks, categories, and user preferences).
- Sharing: We do not send or share your data to any third parties by default.
- Accounts: The App does not require you to sign in.

1. Data we collect
- Local app data (stored on your device)
  - Tasks: title, description, category reference, cadence, completed flag, timePeriodId.
  - Categories: id, title, color.
  - Time period metadata used for backfilling and navigation.
  - App settings: themeMode, sortMode, dragFlip, selectedTimePeriodId, and other feature flags.
  - Storage technology: The app uses Hive for local persistence (Hive boxes: `tasks`, `categories`, `timePeriods`, `settings`).
- Automatically collected technical data
  - Crash traces or diagnostic logs: None by default. The App does not include analytics or crash-reporting SDKs in the base version.
- Personal information
  - The App does not collect explicit personal information such as name, email, or phone number unless you voluntarily add such information into task notes or descriptions; such text is stored locally as part of the task.

2. How we use data
- To provide and operate the App’s core features, including:
  - Persisting tasks and categories locally.
  - Backfilling recurring tasks across time periods per the app’s rules.
  - Applying user-selected theme, sorting, and UI preferences.
- We do not use your data for profiling, advertising, or sale.

3. Sharing and disclosures
- No third-party sharing: By default, the App does not send your data to servers or third-party services.
- Play/App store releases: Publishing the App to stores does not transmit user data to us.
- Optional integrations: If you later enable a cloud sync, analytics, or third-party integration, you'll be informed and must opt in — and we will update this policy to reflect the change.

4. Data retention and deletion
- Local data lifecycle: Your data persists on the device while the App is installed and until you delete it or explicitly remove data (delete tasks/categories, clear app data).
- Delete app: Uninstalling the App typically removes local data (depending on OS and device backup settings).
- Export / backup: If you need to move or backup data, use platform-level backup tools or request an export feature if implemented.

5. Security
- Local storage: Data is stored locally on the device using Hive. We recommend device-level security (screen lock, encrypted storage) to protect your device and its data.
- No server-held secrets: The App does not maintain a backend that stores user data by default.
- Developer security practices: We follow reasonable practices for secure development; however, no software can guarantee total security.

6. Children
- The App is not specifically targeted to children under the age of 13. If a parent/guardian believes their child has provided personal information, please contact us to request deletion.

7. Legal and compliance
- Law enforcement and legal requests: We do not hold user data on servers; therefore we generally cannot produce user data except via device-level access by the user or in the rare case of court-ordered device access.
- Changes to this policy: We may update this policy. We’ll note the effective date at the top and publish the revised policy.

8. International users
- The App stores data on the device in the user’s jurisdiction. If you reside in a region with data protection laws (GDPR, CCPA, etc.), you may have additional rights (access, deletion, portability). Contact us at the address above to exercise those rights.

9. Third-party services and links
- The App may link to external websites or services (e.g., documentation, help pages). We are not responsible for the privacy practices of external sites. Check their policies for details.

10. How to contact us or request deletion
- Contact: privacy@example.com (replace with your actual support email).
- Request types we can help with:
  - Delete your data instructions or requests (we will provide steps or a data removal action if you provide relevant device/task identifiers).
  - Questions about this policy.

Important notice about Play/App Signing and keystores
- Play App Signing: When distributing via Google Play, Play may manage your app signing key; this does not involve transferring user data.
- Keystore & credentials: Your upload and signing keys are developer-side artifacts; keep them secure. They do not affect user privacy.

If you add cloud sync, analytics, ads, or other features later
- We’ll update this policy to list any new data collected, the legal bases for processing (where required), and the third parties involved. We’ll also show whether the new behavior requires opt-in, and how to opt out.

Notes & recommended next steps (technical)
- Add this file to your repo as `docs/privacy_policy.md` and add a short link in `README.md`.
- In the Play Console, provide a privacy policy URL (if you host it — e.g., GitHub Pages, your website) or paste the text where required.
- If you plan to add analytics, crash reporting, cloud backups or sign-in, update the policy before release.
