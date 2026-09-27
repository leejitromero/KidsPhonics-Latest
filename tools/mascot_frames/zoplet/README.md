# Zoplet walking frames

Original transparent PNG artwork supplied by the user, in walking order:
`1.png`, `2.png`, `3.png`, `4.png`.

The app uses `assets/images/mascot_zoplet.gif`: a 512 × 512 animation,
180 milliseconds per frame, looping forever. Each frame clears the previous
frame to preserve transparency without trails. The GIF uses 255 artwork
colors and one transparent palette entry.

`assets/images/mascot_zoplet.png` is the first frame at 512 × 512 for reduced
motion and inactive routes. Original frames stay outside the asset bundle
to avoid shipping duplicate full-resolution artwork.

Zoplet represents Progress on the Home card and Progress welcome panel.
