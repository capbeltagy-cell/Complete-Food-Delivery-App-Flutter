# Dierb self-hosted migration audit

## Current applications

- `user_app`: customer Flutter application.
- `seller_app`: merchant Flutter application.
- `rider_app`: rider Flutter application.
- `admin_web_portal`: Flutter Web administration portal.
- `packages/dierb_core`: shared domain value objects and order status compatibility.

## Existing backend dependencies

The four clients currently access Firebase directly. The highest-use Firestore collections are `orders`, `users`, `sellers`, `stores`, `riders`, legacy `items`/`menus`, `categories`, `userAddress`, `products`, `communityPosts`, `merchantApplications`, `notifications`, and geographic collections. Firebase Auth owns sessions and identities. Firebase Storage remains referenced by legacy registration code. FCM is used for Android push delivery. No active Supabase client was found in the application source.

Hard-coded legacy upload endpoints referencing the retired VPS exist in merchant registration, product upload, and store settings and must be replaced by the new `/v1/uploads` endpoint.

## Migration rule

Firebase Auth, Firestore, and Storage are not removed until each corresponding API-backed flow is implemented and verified. During migration, clients use repository interfaces and an environment-selected backend. FCM may remain solely as a push transport; PostgreSQL is the notification source of truth.

## Order flow found

Customer creates a COD order in Firestore with embedded item snapshots. Merchant transitions `waitingMerchantApproval → acceptedByMerchant/rejected → preparing → readyForPickup`. An approved available rider atomically claims a ready order, then transitions `pickedUpByRider → onTheWay → delivered`. The shared `OrderStatusCodec` also maps legacy names. The new backend adds explicit `arrived` and persists every transition in `OrderStatusHistory`.

## Cutover sequence

1. Deploy PostgreSQL/Redis/backend and apply migrations.
2. Import Firebase identities and data through a one-time authenticated migration tool (password hashes cannot be exported; users receive reset links).
3. Ship clients with API mode enabled in staging and execute the end-to-end order test.
4. Freeze Firestore writes, perform final delta import, switch production API base URL, then remove Firebase Auth/Firestore/Storage dependencies.
5. Retain only Firebase Messaging and server-side FCM credentials if Android push is enabled.
