# Vitrify — Feature Roadmap

_Drafted 2026-06-12. Each entry: what it is, why it matters, concrete plan, size._
_Sizes: S = a session, M = a few sessions, L = a project._

---

## Tier 1 — quick wins (visible value, small effort)

> **Status: Tier 1 shipped 2026-06-12.** Notes: the Library "stub" turned out to
> already have a full material browser + Learn articles (docs were stale) — the
> Cones tab was the missing piece and was added. `glaze_fundamentals.md` is a
> placeholder, so the markdown viewer was skipped (and `flutter_markdown` is
> discontinued anyway); revisit if real content gets written. Share card +
> mix delete landed as planned (web shares via download, mobile via share sheet).

### 1. Library tab (replace the stub) — M — ✅ done (Cones tab added; browser already existed)
**Why:** It's a visible stub in the bottom nav; reads as "unfinished app." Almost all
the data it needs is already on-device.

**Plan:**
1. Material browser: new list view in `library_screen.dart` over the cached
   materials DB (`materialsRepositoryProvider` — 1000+ `MaterialModel`s, already
   local). Search field at top (match `recipes_screen.dart` search pattern),
   list rows showing name + hazard icon.
2. Material detail: bottom sheet or pushed page with the oxide analysis table
   (reuse the UMF table styling from `recipe_detail_screen.dart`), description,
   hazardous warning banner.
3. Knowledge section: render `assets/knowledge/glaze_fundamentals.md` with the
   `flutter_markdown` package (new dep). Section list → markdown viewer.
4. Static reference data: Orton cone temperature chart as a simple table
   (hardcoded data, no backend).

**Touches:** `library_screen.dart` only, plus one new dep. No backend work.

### 2. Mix delete UI — S — ✅ done
**Why:** Backend `DELETE /mixes/{id}` is deployed; the app can't invoke it.
Abandoned mix sessions pile up in recipe history.

**Plan:**
1. `deleteMix(String id)` in `mixes_repository.dart` (one-liner, mirror
   `deleteRevision`).
2. Swipe-to-delete on `_MixHistory` rows in `recipe_detail_screen.dart`,
   following the existing `_pendingDeletes` timer + undo SnackBar pattern from
   `recipes_screen.dart`.
3. Invalidate `recipeMixesProvider(recipeId)` after delete.

### 3. Recipe share card (export) — M — ✅ done
**Why:** Potters tape recipe cards to studio walls and share them in guild
groups. Cheap to build, spreads the app organically.

**Plan:**
1. `RecipeShareCard` widget: fixed-width (e.g. 800px logical) branded card —
   name, cone/atmosphere chips, materials table (base + additions), UMF
   one-liner, app wordmark. Render off-screen via `RepaintBoundary` →
   `toImage()` → PNG bytes.
2. Share: `share_plus` package (new dep) for mobile share sheet; on web,
   trigger a download via the existing `lib/core/platform/` shim pattern
   (add a `downloadBytes` web util with `package:web`).
3. Entry point: "Share as image" in the recipe detail `PopupMenuButton`,
   next to Duplicate.
4. (Later, optional) PDF via the `printing` package if image cards prove popular.

---

## Tier 2 — closes existing loops

> **Status: Tier 2 shipped 2026-06-12** (backend deployed; snapshot triggered
> manually once so Popular works immediately). Notes: offline cache went with
> SharedPreferences on all platforms instead of sqflite (web-compatible, one
> code path) — `sqflite`/`path`/`path_provider` deps removed. `displayName` on
> old items backfills lazily as each recipe/schedule is next saved.

### 4. Public user profiles — M (frontend) + S (backend) — ✅ done
**Why:** The backend already serves public profiles, follower lists, and a
following feed — but the app has no `/user/:uid` route. You can't tap a feed
item's author, so following is blind. This is the missing half of community.

**Plan — backend first (small):**
1. New endpoint `GET /users/{uid}/recipes` (public) in UsersApi: query
   `pk = USER#{uid}, begins_with(sk, RECIPE#)` with `FilterExpression public = true`
   (the exact query `QueryUserAdjacency` in CommunityApi already does). Add the
   public route in the CDK.
2. Denormalize `displayName` onto recipe/schedule METADATA + adjacency items at
   create/update time (fetch profile once per save), and map it into
   `MapFeedItem`. Without this, feed cards and profile headers can't show
   author names without N+1 profile fetches. Old items lack the field — map as
   empty and let the profile screen be the fallback.

**Plan — frontend:**
3. Route `/user/:uid` outside the shell (use the `_slide` transition helper).
4. `user_profile_screen.dart`: header (displayName, photo, bio, follower/
   following counts), follow/unfollow `FilledButton` with optimistic state
   (mirror `_HeartButton`), then a grid/list of their public recipes reusing
   the feed card widgets.
5. New providers: `userProfileProvider(uid)` (`GET /users/{uid}`),
   `userRecipesProvider(uid)`. Repository methods in `community_repository.dart`.
6. Make the author area of `_FeedCard` tappable → `context.push('/user/$uid')`.

### 5. Offline support, phase 1: read-only cache — M — ✅ done
**Why:** Studios have terrible Wi-Fi, and the moments the app matters most
(reading a recipe while mixing, logging a tile at the kiln) are exactly when
you're offline. `sqflite` and `connectivity_plus` are already in pubspec, unused.

**Plan:**
1. New `lib/core/cache/response_cache.dart`: sqflite table
   `(cache_key TEXT PRIMARY KEY, body TEXT, updated_at TEXT)`. On web, back it
   with SharedPreferences via a conditional import (sqflite is not web-compatible)
   or accept web as online-only for phase 1.
2. Write-through: repositories store successful GET bodies under their URL as
   key (recipes list, recipe detail, schedules, batches, materials are already
   cached separately).
3. Fallback: in `ApiClient.get`, on `SocketException`/timeout, return the cached
   body with a flag; surface a "showing offline copy" banner via a simple
   `connectivityProvider` (`connectivity_plus` stream).
4. Editor screens check connectivity and disable save with a clear message
   (no silent data loss).
5. **Phase 2 (separate, L):** mutation outbox with replay — design later;
   conflict story needed because of the revision system.

### 6. Honest "Popular" feed — M (backend only) — ✅ done
**Why:** The Popular tab currently just re-sorts whatever page it fetched by
likes. With more than one page of content it's misleading.

**Plan (recommended: precomputed trending, no new GSI):**
1. New scheduled Lambda (EventBridge rule, e.g. hourly): query GSI1
   (`FEED#RECIPES` + `FEED#SCHEDULES`, last ~30 days), score by
   `likeCount` (optionally time-decayed), write the top ~100 ids + denormalized
   card data to a single item `pk=FEED#POPULAR, sk=SNAPSHOT`.
2. `GetGlobalFeed` with `filter=popular` reads that item and paginates it
   in-memory (cursor = offset). Response shape unchanged — frontend needs no work.
3. Alternative considered and rejected for now: a likeCount-keyed GSI — real-time
   but adds index cost and hot-partition risk for marginal benefit at this scale.

---

## Tier 3 — launch blockers for iOS (do before App Store submission)

### 7. Apple Sign-In — M
**Why:** App Store guideline 4.8 **requires** Sign in with Apple when other
third-party logins (Google/Facebook) are offered. Hard blocker for iOS release.

**Plan:**
1. Apple Developer portal: create a Sign in with Apple key + Services ID;
   authorize the Cognito domain redirect
   (`https://glazevault-auth.auth.us-east-2.amazoncognito.com/oauth2/idpresponse`).
2. Secrets Manager: `vitrify/apple-oauth` → `{ teamId, keyId, privateKey, servicesId }`.
3. CDK: `UserPoolIdentityProviderApple` + add `APPLE` to the app client's
   `SupportedIdentityProviders` (the InfraStack TODO comment already stubs this).
4. Xcode: enable the Sign in with Apple capability on the Runner target.
5. Flutter: add the Apple button to `login_screen.dart`
   (`signInWithWebUI(provider: AuthProvider.apple)`), shown on iOS + web.
6. Gotcha to verify: Apple private-relay emails (`@privaterelay.appleid.com`)
   flow through the same lazy-profile-creation path in UsersApi — should work,
   but test the display-name fallback (email prefix will be opaque).

### 8. Device-test social sign-in — S (test task)
**Why:** The `vitrify://` scheme is registered but unproven on hardware.

**Plan:** `flutter run` on a physical Android device → Google sign-in → confirm
the custom-tab returns to the app and `[GlazeVault]` logs show a session; repeat
on iOS. Verify `amplify_config.dart` lists `vitrify://callback` in the mobile
redirect URIs. Fix whatever breaks (most likely: missing `queries` entry or
config redirect mismatch).

### 9. Premium receipt validation + paywall — L
**Why:** `POST /users/me/premium` currently grants premium to anyone
authenticated. Fine in beta; not at launch.

**Plan (decision needed first):**
- **Option A — RevenueCat (recommended):** `purchases_flutter` SDK, webhook →
  small new Lambda that sets `isPremium` on the profile + Cognito attribute.
  Outsources receipt validation, restore-purchases, and cross-platform
  entitlement state. Vendor dependency, free tier generous.
- **Option B — first-party:** `in_app_purchase` plugin; extend `GrantPremium`
  to require `{ platform, receipt }` and verify against Apple
  `verifyReceipt` / Google Play Developer API (needs a Play service account +
  App Store shared secret in Secrets Manager). More control, much more code.
- Either way: paywall sheet in the app (trigger: AI limit hit, premium-only
  features), `isPremium` already flows through the JWT custom attribute.

---

## Tier 4 — backend hygiene & later bets

### 10. Orphan cleanup on recipe/schedule delete — S/M (backend)
**Plan:** In `DeleteRecipe`: (a) parse S3 keys out of every revision's
`imageUrls` and batch-delete from the images bucket; (b) query
`pk = USER#{uid}/RECIPE#{id}` and delete mix-history index items. Leave hearts
lazy (favorites already skips missing recipes) — a `targetId` GSI isn't worth
it yet. Mirror for schedules (no images there).

### 11. Push notifications — L (defer)
Comment/heart/follow notifications. Needs FCM + APNs setup, device-token
registration endpoint + storage, SNS platform applications (IAM is already in
place), notification preferences UI, and badge handling. Don't start until the
community has actual activity.

### 12. Riverpod 3 migration via build_runner — M (do opportunistically)
Regenerate all `.g.dart` with `build_runner`, migrate deprecated `*Ref` types,
pin riverpod 3.x. Mechanical but wide; do it in a quiet week, not alongside
feature work.

---

## Suggested order

| When | Items |
|------|-------|
| Next sessions | 2 (mix delete), 1 (Library), 3 (share card) |
| Then | 4 (profiles), 5 (offline phase 1), 6 (popular) |
| Before iOS submission | 7 (Apple), 8 (device test), 9 (receipts) |
| Background / as needed | 10, 11, 12 |
