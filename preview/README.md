# Browser preview

`joruri-bd-preview.html` is a clickable preview of the app (same design, Bangla/English text,
emergency numbers, guides and demo data as the Flutter app). Open it in a browser over https
(or the published claude.ai link) so location works.

It does not replace the app: by default no real SMS or call is made. Settings → "Use my phone
for real" opens your real SMS app and dialer on a phone. The real emergency engine (SMS, calls,
GPS, flashlight, compass, permissions) is in `apps/mobile`.
