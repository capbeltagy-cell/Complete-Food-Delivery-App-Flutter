# Dierb production Firebase setup

The repository keeps Firebase as the backend but does not contain new production credentials.

1. Create the production Firebase project and enable Authentication, Cloud Firestore, and Storage.
2. Register Android app `com.capbeltagy.dierb`. Register separate packages for the merchant and rider apps when their Android identifiers are finalized.
3. Run FlutterFire configuration from each app directory and keep generated environment-specific files out of public source control. Install the customer `google-services.json` locally under `user_app/android/app/` only after it matches `com.capbeltagy.dierb`.
4. Configure authorized web domains and web options for the customer and admin web applications.
5. Deploy `admin_web_portal/firestore.rules` and `admin_web_portal/firestore.indexes.json` with the Firebase CLI.
6. Create the first `admins/{uid}` record from the Firebase Console or a trusted server environment. Never allow a client to create its own admin record.
7. Seed `config/seeds/dierb_launch.json` and `config/seeds/marketplace_taxonomy.json` from a trusted Admin/CLI process, not from a public client.

Legacy Firebase files remain migration inputs only. They must be replaced locally before production release and should not be reused for the new project.
