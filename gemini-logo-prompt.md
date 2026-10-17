# Prompt Logo & Icon "Nada" — Gemini AI

Konsep terpilih: **lingkaran + gelombang suara memancar** (merah × putih).

Cara pakai:
1. Kirim **Prompt 1** di chat baru. Generate 2–3 kali kalau perlu, pilih yang paling bagus.
2. Di chat yang sama, lanjutkan dengan Prompt 2, 3, dan 4 supaya bentuknya tetap konsisten.
3. Kalau ada yang kurang pas, pakai prompt revisi di bagian bawah.

Palet: merah `#E11D2E`, merah gelap `#A50F1E`, putih `#FFFFFF`.

---

## Prompt 1 — App Icon

```
Create a premium, modern app icon for a music streaming app named "Nada".

Symbol: a solid white circle on the left-center, like the center of a speaker or a vinyl record,
with three white curved sound-wave arcs radiating to the right, each arc progressively larger,
thinner spacing between them, perfectly concentric with the circle. The arcs have rounded caps
and consistent stroke weight, slightly thinner than the circle's radius. The whole symbol
(circle + arcs) is optically centered on the canvas, not mathematically, so it feels balanced.

Background: rich red rounded-square app icon. Base color #E11D2E with a very subtle
diagonal gradient to #A50F1E in the bottom-right corner, giving gentle depth while staying flat.

Colors: strictly red and white only. No other colors.
Style: flat vector, minimalist, geometric precision, crisp edges, bold and confident,
friendly and warm. In the visual quality of top App Store and Google Play icons.
Avoid: text, letters, musical notes, headphones, 3D, bevels, glossy reflections,
drop shadows, outlines, noise, textures, extra decorations.

Format: square 1024x1024. Keep the symbol within the central 60% of the canvas
with generous padding, so it works in circle, squircle, and rounded-square masks and stays
instantly recognizable even at 48x48 px.
```

## Prompt 2 — Logo Lengkap (Ikon + Wordmark)

```
Now create the full horizontal brand logo using exactly the same symbol you just designed
(same circle, same three arcs, same proportions).

Layout: symbol on the left, wordmark on the right, vertically centered, with spacing between them
equal to about half the symbol's height.
Wordmark: the word "Nada" spelled exactly N-a-d-a, title case, in a clean geometric
sans-serif typeface similar to Plus Jakarta Sans or Poppins, bold weight, slightly tight
letter spacing. The height of the lowercase letters should align visually with the circle in the symbol.

Produce two versions stacked vertically on one canvas:
1) Red symbol (#E11D2E) and red wordmark on a pure white background.
2) White symbol and white wordmark on a solid red (#E11D2E) background.

Flat vector, crisp, no shadows, no 3D, no tagline, no extra elements.
```

## Prompt 3 — Simbol Polos (untuk Android Adaptive Icon & Splash Screen)

```
Using exactly the same symbol (circle + three sound-wave arcs), create the symbol alone
in pure white, with no background shape, placed on a plain flat red (#E11D2E) background
that fills the entire square canvas edge to edge.
Square 1024x1024. Scale the symbol down so it fits comfortably inside the central 50%
of the canvas (Android adaptive icon safe zone).
Keep identical shapes and proportions. Flat vector, no text, no shadows.
```

## Prompt 4 — Versi Monokrom

```
Create a monochrome version of the same symbol (circle + three arcs):
solid black symbol on a pure white background, square 1024x1024,
symbol centered within the central 50% of the canvas.
Identical shapes and proportions, flat vector, no text, no gradients, no shadows.
This will be used for notification icons and themed icons.
```

---

## Prompt Revisi (pakai kalau hasilnya kurang pas)

| Masalah | Kirim ini |
|---|---|
| Terlalu ramai / detail | `Make it simpler and bolder. Fewer details, thicker shapes, more negative space.` |
| Gelombang tidak rapi | `Make the three arcs perfectly concentric with the circle, evenly spaced, with identical stroke weight and rounded caps.` |
| Simbol terlalu besar | `Scale the symbol down so it sits within the central 55% of the canvas with more padding.` |
| Ada efek 3D/bayangan | `Remove all shadows, glow, bevel and 3D effects. Completely flat vector.` |
| Warna melenceng | `Use only exact colors: red #E11D2E, dark red #A50F1E for the subtle gradient, and pure white #FFFFFF.` |
| Tulisan "Nada" salah eja | Pakai logo tanpa teks, tulis "Nada" manual di Pencil/Canva dengan font Plus Jakarta Sans Bold. |

---

## Checklist File untuk Flutter

- [ ] `icon-1024.png`: hasil Prompt 1 (iOS & ikon utama)
- [ ] `icon-foreground.png`: simbol putih **transparan** dari Prompt 3 (Android adaptive foreground, background-nya diset `#E11D2E` di Flutter)
- [ ] `icon-monochrome.png`: hasil Prompt 4 (notifikasi & themed icon Android 13+)
- [ ] `logo-light.png` & `logo-dark.png`: hasil Prompt 2 (splash & halaman login)

> Gemini jarang menghasilkan background transparan. Hapus background-nya pakai remove.bg atau
> Canva (gratis). Atau, karena bentuknya geometris sederhana, saya bisa membuat ulang simbol ini
> sebagai **SVG** yang presisi sehingga tajam di semua ukuran.
