# Founder Storefront Integration — Greyskull LP

**Owner / Product Authority:** [@TheDevWhoSaysNi](https://github.com/TheDevWhoSaysNi)  
**Delivery Lead:** [@umerwaqas92](https://github.com/umerwaqas92)  
**Repository:** [suncoast-servers/GreyskullLP](https://github.com/suncoast-servers/GreyskullLP)  
**Related Issue:** Closes #20

---

## 1. Storefront Platform Identification

- **Official Store URL:** `https://store.greyskullnation.com/`
- **Host / Platform:** **Shopify** (Confirmed via response headers: `powered-by: Shopify`, `cdn.shopify.com`, `_shopify_essential`, Shopify complexity headers).
- **CDN & Edge:** Cloudflare with Shopify CDN asset pipelines.
- **Product Catalog Collections:**
  - `/collections/ebooks` — **Official Books & Ebooks** (Johnny Pain Greyskull LP manual, Second Edition, specialized templates).
  - `/collections/coaching` — **Personal Coaching** with Johnny Pain.
  - `/collections/men` — **Greyskull Nation Apparel** (T-shirts, hoodies, lifting merchandise).

---

## 2. In-App Embed Approach & Trade-Offs

We evaluated three potential architectural approaches for presenting the founder storefront in Flutter:

| Approach | User Experience | Checkout & Payments | App Store Policy Compliance | Offline Resilience |
|---|---|---|---|---|
| **A. In-App WebView (`webview_flutter`)** *(Implemented)* | ⭐⭐⭐⭐⭐ Highest continuity; user stays inside the app with integrated toolbar (Back, Forward, Reload, Category chips). | Standard Shopify web checkout (Shop Pay, credit card). | High compliance for physical apparel & coaching. Reader app rules apply for ebooks. | Handled gracefully with network state detection and retry UI. |
| **B. Native Custom Tabs / SFSafariViewController** | ⭐⭐⭐⭐ Good; opens semi-modal browser overlay with full autofill and Apple Pay. | Full native Apple Pay web integration. | Clean separation from app core. | System browser handles error pages. |
| **C. Native StoreKit / In-App Purchase (IAP)** | ⭐⭐ Poor fit for physical merchandise; 15–30% platform fee; impossible for physical apparel. | Apple / Google IAP billing engine. | Required only for in-app digital unlocks, NOT physical goods. | N/A |

### Decision: Hybrid WebView + External Browser Escape Hatch

The app implements **Approach A (In-App WebView)** with a 1-tap **External Browser Escape Hatch (Approach B)**:
1. **Primary in-app viewing:** Built with `webview_flutter` 4.x. Users browse books, coaching, and apparel directly inside the app with standard forward/back navigation and quick collection filters.
2. **External browser button:** An `Icons.open_in_new` button is always accessible on the toolbar so users who prefer Safari / Chrome or native web autofill can jump out at any point.

---

## 3. App Store & Google Play Policy Alignment

- **Physical Merchandise:** Apple App Store Review Guideline **3.1.3(e) (Goods and Services Outside the App)** and Google Play Billing policy explicitly permit web-based checkout for physical goods (apparel, shirts, shipped books).
- **No StoreKit Lock-in:** Because the app is 100% free with no digital subscriptions or locked features, the storefront is an external fan community resource, not an in-app purchase paywall.
- **Configurability:** Store URL is fully configurable in `SettingsPage` with a "Reset to Default" fallback.

---

## 4. Resilience & Network Error Handling

In gym environments with poor Wi-Fi or cellular dead zones, the storefront must not display a broken or blank white screen.

`StorePage` implements:
- `onWebResourceError` detection: Intercepts network disconnects, DNS timeouts, and SSL errors.
- Visual state transition to `_StoreOfflineErrorView`:
  - Indicates connection failure cleanly.
  - One-tap **Try Again** reload button.
  - One-tap **Open in Browser** fallback.
- `LinearProgressIndicator`: Provides real-time page loading feedback to prevent perceived freezing.

