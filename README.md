# Laundry Service Mobile App

Full-featured laundry app built with Flutter 3, Riverpod, and Firebase. Includes end-to-end ordering, discounts, fragrances, addresses, admin tooling, and real-time order tracking.

## Tech
- Flutter 3.x (null-safety), Dart
- Riverpod (state/DI), go_router (navigation)
- Firebase: Auth, Firestore, Storage (FCM placeholder)
- Google Maps picker, geolocator/geocoding
- sqflite for local addresses
- Clean Architecture (data/domain/presentation)

## Core User Features
- Auth: email/password (Firebase Auth)
- Home: laundries, services, auto-select first fragrance, discounts
- Fragrances: select/deselect, stored and shown by name in cart/order
- Cart:
  - Items with quantity, per-piece/per-kg, fragrance, item name
  - Selected laundry discount applied to all items
  - Order summary + payment placeholder (COD/online stub)
  - Address selection from local sqflite store
  - Validates pickup/delivery datetime and address before placing
- Orders:
  - Tabs: Active / Completed / Cancelled
  - Real-time streams; refresh on open/resume; refresh before details
  - Timeline: pending → accepted → processing → ready for pickup → out for delivery → delivered
  - Cancelled shows a banner (not in timeline)
  - Cancel order moves to cancel collection
- Navigation:
  - Bottom nav on Home/Orders/Cart uses `go()` (no stacked back buttons)
  - Key routes: `/home`, `/orders`, `/cart`, `/order/:id`, `/order/success/:id`

## Admin Features
- Role check: `role = "admin"`
- Admin home with quick actions: Add Laundry, Add Services, Add Service Items, Add Pricing
- Add Laundry: text fields + Google Map picker → `laundries`
- Add Service: select laundry; name, priceType, duration, icon → `services`
- Add Service Item: select service; itemName, price, min, max → `services/{serviceId}/items`
- Admin setup/seed routes (`/admin`, `/admin/seed`)

## Firestore Data (key paths)
- `users/{uid}`
- `laundries/{laundryId}`
- `services/{serviceId}` and `services/{serviceId}/items/{itemId}`
- `fragrances/{id}`
- `carts/{userId}/items/{itemId}`
- Orders:
  - Main: `orders/{orderId}`
  - Pending: `orders/pending/pending/{orderId}`
  - Cancelled: `orders/cancel/cancel/{orderId}`
  - Completed: `orders/complete/complete/{orderId}`

## Order Status Handling
- Accepted strings (normalized in `OrderStatus.fromString`):
  - `pending`, `accepted`, `processing`
  - `ready_for_pickup`, `ready for pickup`, `readyforpickup`
  - `out_for_delivery`, `out for delivery`, `outfordelivery`
  - `delivered`, `complete`
  - `cancelled`
- Delivered moves the doc to `orders/complete/complete/{id}`
- Cancelled moves the doc to `orders/cancel/cancel/{id}`
- List/detail streams combine main + pending + cancel + complete

## Discounts & Pricing
- Selected laundry discount applies to all cart items
- Items show crossed-out price + discounted price (per-item badge removed; main badge on selected laundry card)

## Addresses
- Stored locally via sqflite
- Map picker for add/edit/select
- Selected address shown in order summary and saved in order notes

## Real-Time Refresh
- Orders page: refresh on open, on resume, and before opening details
- Order details: invalidates provider on open to avoid stale status
- Streams (`orderListProvider`, `orderDetailProvider`) drive live updates

## Setup
1) `flutter pub get`
2) Configure Firebase (`flutterfire configure`) and add platform config files
3) Add Google Maps API keys to Android/iOS configs
4) `flutter run`

## Build
- Android: `flutter build apk` or `flutter build appbundle`
- iOS: `flutter build ios`

## Notes
- Bottom nav uses `go()` for top-level tabs
- Cancelled orders show a banner instead of a timeline step
- Status strings are normalized to prevent “Pending” fallbacks


# laundry-app
