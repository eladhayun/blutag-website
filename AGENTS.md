# AGENTS.md

Repository guidance for Codex and other coding agents.

## What this is

Static marketing site for BluTag. Plain HTML + a ThemeForest template, served by
`nginx:alpine`. Four pages: `index.html`, `blog.html`, `blog-details.html`,
`blog-details-bl653.html`.

**There is no build step.** CI only builds the Docker image (`.github/workflows/`);
it does not run sass, npm or bun. `Dockerfile` copies the HTML and `assets/`
verbatim into `/usr/share/nginx/html/`. Whatever is committed is what ships.

Deploys: push to `main` → CI builds `prodacr1234.azurecr.io/blutag-website:main-<sha7>`
→ updates the image tag in `eladhayun/gitops` → ArgoCD syncs. Live at
`blutag.jshipster.io`, `blutag.company`, `www.blutag.company`, `blutag.argmaxml.com`.

## Editing CSS: bump `?v=` or your change will not ship

`nginx.conf` serves static assets with `expires 1y` and
`Cache-Control: public, max-age=31536000, immutable`, and asset filenames are **not**
content-hashed. Editing `assets/css/main.css` therefore changes nothing for anyone
who has already loaded the site — Cloudflare and browsers keep serving the old file
until the **URL** changes.

**After any edit to `main.css`, bump the version query in all four pages:**

```html
<link rel="stylesheet" href="assets/css/main.css?v=2">   <!-- -> ?v=3, etc. -->
```

All four must match so the pages share one cache entry. This works because
`nginx.conf` serves `*.html` as `no-cache`, so the new `<link>` reaches clients
immediately. Cloudflare includes the query string in its cache key (verified: a
`?v=probe` URL returns `cf-cache-status: MISS`, then `HIT`, and serves the fresh
file).

**Symptom when you forget:** a CSS change that is provably in the image but has no
effect in the browser. Check the asset, not the markup:

```bash
# what the edge serves
curl -sI https://blutag.company/assets/css/main.css | grep -i 'cf-cache-status\|age'
# what is actually in the running image
POD=$(kubectl --context jshipster -n blutag get pod -l app=blutag-website -o name | head -1)
kubectl --context jshipster -n blutag exec "${POD#pod/}" -- \
  grep -c '<your-rule>' /usr/share/nginx/html/assets/css/main.css
```

If the rule is in the pod but not at the edge, it is this — not a layout bug.

Same trap applies to any immutable-cached asset. Images have been handled by
renaming the file instead (see `logo.svg` → `logo-blutag.svg`); that is fine for
one-off assets, but `main.css` changes too often to keep renaming.

Durable fix, if this keeps biting: drop `immutable` for css/js in `nginx.conf`, or
add a build step that emits content-hashed filenames.

## CSS lives in two places — edit both

`assets/css/main.css` is the artifact that ships. It is compiled from
`assets/scss/`, but **nothing in CI compiles it**. So a change made only to the scss
has no effect, and a change made only to the css silently drifts from its source.
Hand-edit both, keeping them equivalent.

Breakpoints (`assets/scss/utils/_breakpoints.scss`): `$xl` 1500, `$lg` 1199.98,
`$md` 991.98, `$xs` 767.98.

Note Bootstrap's `.container` is only fluid **below 576px**; from 576px up it is
capped at a fixed max-width (540/720/960/1140). Full-bleed tricks that negate the
15px column gutter therefore only reach the viewport edge below 576px — `$xs`
(767.98) is the wrong breakpoint for that and will strip a card's corners while
gaining nothing. See `.token__wrap--video`.

## Gotchas when testing layout

- Elements with `data-aos="fade-left"` start at `translate3d(100px,0,0)`. Calling
  `scrollIntoView()` on one makes the browser scroll `main.main-area` **sideways**
  to reveal it, so measurements come back offset by -100px. It is an artifact of the
  test, not a layout bug — scroll vertically (`window.scrollTo(0, y)`) instead and
  check `main.scrollLeft === 0`. `main.main-area.fix` has `overflow-x: hidden`
  precisely to contain that overhang.
- Chrome's minimum **window** width is ~500px. Screenshots at narrower widths are
  captured at 500px even when the emulated **viewport** reports 390, so the image
  disagrees with `getBoundingClientRect()`. Trust the measurements; use CDP device
  emulation for real phone widths.

## Media

`assets/video/` holds page video. Re-encode before committing — the source is
usually far too heavy for a landing page:

```bash
ffmpeg -i in.mp4 -c:v libx264 -crf 27 -preset slow -profile:v high \
  -pix_fmt yuv420p -c:a aac -b:a 96k -movflags +faststart out.mp4
```

`+faststart` puts the `moov` atom first so playback starts before the file finishes
downloading. Pair with `preload="none"` and a `poster` so the page costs no video
bytes until someone clicks. `mp4` is in the immutable-cache regex in `nginx.conf`,
so a replaced video needs a new filename.
