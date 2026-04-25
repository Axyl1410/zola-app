# Polar + Better Auth Mobile Payment Flow

This document captures a practical payment flow for Flutter mobile apps using Polar checkout with Better Auth, including deep-link return and webhook-based verification.

## Goal

- Open Polar Checkout from mobile.
- Return user back to app after payment.
- Mark payment as successful only after backend confirmation (webhook + verification).

## Core Principles

- Do not trust client redirect alone as payment truth.
- Treat webhook/backend state as source of truth for entitlement/subscription.
- Use `checkout_id` as correlation key between app, backend, and Polar.

## Recommended End-to-End Flow

1. App asks backend to create checkout session.
2. Backend (Better Auth + Polar plugin) creates checkout and returns checkout URL.
3. App opens checkout URL in browser or webview.
4. User completes payment on Polar hosted checkout.
5. Polar redirects to configured `successUrl` (include `checkout_id`).
6. Success page deep-links user back to app (`myapp://...` or universal/app link).
7. App calls backend `verify` endpoint with `checkout_id`.
8. Backend checks internal billing state (updated by webhook) and returns final status.
9. App shows success only when backend says payment/subscription is active.

## Better Auth (Server) Setup Notes

Use Polar plugin with checkout + webhooks:

- `checkout({ successUrl, returnUrl, authenticatedUsersOnly, products })`
- `webhooks({ secret, onOrderPaid, onSubscriptionCreated, onSubscriptionUpdated, ... })`

Suggested `successUrl` format:

- `https://yourdomain.com/billing/success?checkout_id={CHECKOUT_ID}`

Optional:

- `returnUrl` adds a Back button in Polar checkout UI.

## Mobile Return Strategy

### Preferred: Universal/App Link

- `successUrl` points to your web endpoint.
- Web endpoint immediately redirects to app deep link:
  - `myapp://billing/success?checkout_id=...`
  - or universal/app link route handled by app.

Benefits:

- Better cross-platform behavior.
- Web fallback when app is not installed.

### Alternative: Custom Scheme Only

- Directly use a custom scheme redirect.
- Faster to set up but less robust than universal/app links.

## WebView Completion Handling

If checkout is opened in webview:

- Listen for navigation to `successUrl`.
- Close webview and move user to a pending/success screen.
- Immediately call backend verification endpoint.

Important:

- A redirect to success URL is not final payment proof by itself.
- Webhook delivery can lag by a few seconds.

## Backend Verification Contract (Suggested)

Create endpoint:

- `GET /api/billing/verify?checkout_id=<id>`

Response example:

```json
{
  "checkoutId": "chk_...",
  "status": "pending|paid|failed|expired",
  "entitlementActive": true,
  "subscriptionId": "sub_..."
}
```

Verification logic:

1. Check local DB state (webhook-processed records).
2. If not finalized, query Polar checkout status as fallback.
3. Poll briefly (for example 2-10 seconds total) if webhook not yet applied.
4. Return `paid` only when entitlement/subscription is active in backend.

## Webhook Responsibilities

Your webhook handler should:

- Verify Polar signature.
- Persist events idempotently.
- Update customer/subscription/order state.
- Grant or revoke app entitlements based on billing state.

Typical events to process:

- Order paid
- Subscription created/updated/canceled
- Checkout updated

## Failure and Edge Cases

- User closes checkout before completing -> keep status `pending`.
- Redirect succeeded but webhook delayed -> show "processing payment" and poll verify endpoint.
- Duplicate webhook delivery -> idempotent upsert by event/checkpoint IDs.
- Expired/failed checkout -> show retry CTA and create new checkout.

## Security Notes

- Never grant premium access from client-side redirect only.
- Never trust client-sent `paid=true`; always verify server-side.
- Protect verify endpoint with user auth/session checks.

## Suggested Flutter UX States

- `idle` -> `openingCheckout` -> `returningFromCheckout` -> `verifying` -> `success|failed|pending`

For `pending`, show:

- "We are confirming your payment..."
- Auto-refresh button + timed polling.

## References

- Better Auth Polar plugin docs: https://www.better-auth.com/docs/plugins/polar
- Polar Better Auth adapter docs: https://polar.sh/docs/integrate/sdk/adapters/better-auth
- NPM package docs (`@polar-sh/better-auth`): https://www.npmjs.com/package/@polar-sh/better-auth?activeTab=readme
- Polar checkout session docs: https://docs.polar.sh/features/checkout/session
- Polar checkouts API reference: https://mintlify.com/polarsource/polar/api-reference/checkouts
- Flutter M3 Expressive status issue (context): https://github.com/flutter/flutter/issues/168813
