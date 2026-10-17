# Prompt Mockup UI — Pencil (pen.dev)

Cara pakai: kirim **Prompt 1** dulu (konteks + design system + layar inti). Setelah hasilnya oke,
lanjutkan **Prompt 2**, **Prompt 3**, dan seterusnya di file `.pen` yang sama supaya semua layar
konsisten memakai komponen yang sudah dibuat.

---

## Prompt 1 — Konteks, Design System, dan Komponen Dasar

```
Buatkan mockup UI aplikasi mobile pemutar musik bernama "Nada" (nama sementara) untuk Flutter.
Aplikasi ini untuk pemakaian pribadi + beberapa teman: user mencari lagu, lalu lagu diputar
streaming. Tidak ada iklan, tidak ada paket premium, tidak ada fitur sosial yang rumit.

JANGAN meniru branding Spotify/YouTube Music (tidak pakai logo, warna hijau khas, atau nama mereka).
Buat identitas visual sendiri yang modern, bersih, dan nyaman dipakai lama di malam hari.

Target device: smartphone, frame 390 x 844 (iPhone 14 / Android setara), safe area atas & bawah.
Gaya: dark mode sebagai tema utama, mengikuti pola Material 3 supaya mudah diimplementasikan di Flutter.
Bahasa UI: Bahasa Indonesia.

DESIGN SYSTEM (buat sebagai variabel/token dan halaman tersendiri):
- Warna:
  - background      #0E0E12
  - surface         #18181F
  - surface-raised  #22222B
  - border          #2E2E3A
  - text-primary    #F5F5F7
  - text-secondary  #A0A0AE
  - text-muted      #6B6B78
  - primary/accent  #FF6B4A (coral hangat)
  - primary-soft    #FF6B4A dengan opacity 16% (untuk chip/background aktif)
  - success #3DD68C, error #FF5470
- Tipografi: font "Plus Jakarta Sans".
  - Display 28/34 bold, Title 20/26 bold, Subtitle 16/22 semibold,
    Body 14/20 regular, Caption 12/16 medium.
- Radius: 8 (kecil), 12 (card), 20 (sheet), 999 (pill/tombol bulat).
- Spacing: kelipatan 4 (4, 8, 12, 16, 24, 32). Padding samping layar 16.
- Ikon: gaya outline yang konsisten (mis. Lucide / Material Symbols Rounded), ukuran 24.

KOMPONEN (buat sebagai komponen reusable):
1. TrackTile: cover persegi 48x48 radius 8, judul (1 baris, ellipsis), artis + durasi (caption,
   text-secondary), tombol "more" (titik tiga) di kanan. Varian: normal, sedang diputar
   (judul berwarna accent + ikon equalizer kecil), disabled.
2. PlaylistCard: cover 150x150 radius 12, nama playlist, jumlah lagu.
3. MiniPlayer: bar mengambang di atas bottom nav, tinggi 64, surface-raised, radius 12,
   cover 44x44, judul + artis, tombol play/pause dan next, progress bar tipis 2px di bagian bawah.
4. BottomNav: 3 tab — Beranda, Cari, Koleksi. Ikon + label, tab aktif berwarna accent.
5. SearchBar: pill, ikon search di kiri, placeholder "Cari lagu atau artis", tombol clear.
6. Button: Primary (fill accent), Secondary (outline border), Ghost (teks saja), Icon button bulat.
7. Chip filter: default & aktif.
8. BottomSheet: handle di atas, radius atas 20.
9. Skeleton loading untuk TrackTile & PlaylistCard.
10. Toast/Snackbar.

Setelah design system & komponen, buat 2 layar pertama:

LAYAR A — Beranda
- Header: sapaan sesuai waktu ("Selamat malam, Petra") + avatar bulat kecil di kanan (ke Profil).
- Grid 2 kolom "Baru diputar" (6 item, tile horizontal kecil: cover + judul).
- Section "Pilihan cepat untukmu" (list TrackTile 4 item, rekomendasi dari lagu terakhir).
- Section "Playlist kamu" (scroll horizontal PlaylistCard).
- MiniPlayer + BottomNav di bawah.

LAYAR B — Cari
- SearchBar di atas.
- Saat kosong: "Pencarian terakhir" (list dengan ikon jam + tombol x untuk hapus) dan
  chip genre/mood sebagai saran cepat (Pop Indonesia, Lo-fi, Galau, Workout, K-Pop, Jazz).
- Buat juga varian layar B2 "Hasil pencarian" untuk query "tulus": chip filter (Lagu, Video),
  hasil teratas sebagai card besar, lalu daftar TrackTile.
- Buat varian B3 "Loading" (skeleton) dan B4 "Tidak ditemukan" (ilustrasi sederhana + teks
  "Lagu tidak ditemukan. Coba kata kunci lain.").

Gunakan data contoh lagu Indonesia yang realistis untuk isi (judul & artis), dan cover
pakai placeholder gradient warna-warni yang berbeda-beda.
```

---

## Prompt 1.5 — Revisi Hasil Prompt 1 (kirim sebelum Prompt 2)

```
Revisi file ini sebelum lanjut ke layar berikutnya:

1. GANTI WARNA AKSEN ke merah supaya serasi dengan logo merah-putih:
   - variabel accent      → #E11D2E
   - variabel accent-soft → #E11D2E dengan opacity 16%
   - variabel error       → #FF7A85 (supaya tetap bisa dibedakan dari aksen)
   Pastikan semua elemen yang memakai aksen ikut berubah (tombol, tab aktif BottomNav,
   chip aktif, progress MiniPlayer, tombol play di "Hasil teratas", swatch di halaman Design System).
   Teks di atas tombol merah tetap putih.

2. KONSISTENSI MINIPLAYER: di layar Beranda ada MiniPlayer di atas BottomNav, tapi di layar
   B (Cari Kosong), B2, B3, dan B4 tidak ada. Tambahkan instance MiniPlayer yang sama di atas
   BottomNav pada keempat layar itu, dengan lagu "Hati-Hati di Jalan" yang sama.

3. HASIL TERATAS di B2: karena hasilnya artis ("Tulus — Artis"), ubah cover persegi
   menjadi foto avatar BULAT (placeholder gradient bulat), sehingga beda dengan cover lagu.

4. TAMBAH LAYAR A2 — Beranda (user baru / belum pernah memutar lagu):
   - Header sapaan sama seperti Beranda.
   - Ganti section "Baru diputar" dan "Pilihan cepat untukmu" dengan empty state:
     ikon musik besar di dalam lingkaran surface, judul "Mulai dengerin lagu pertamamu",
     teks "Cari lagu favoritmu dan kami akan kasih rekomendasi di sini.",
     tombol Primary "Cari lagu" (mengarah ke tab Cari).
   - Di bawahnya chip genre/mood yang sama seperti di layar Cari sebagai saran cepat.
   - Tanpa MiniPlayer (belum ada lagu yang diputar), BottomNav tetap ada.
```

---

## Prompt 2 — Player

```
Lanjutkan di file yang sama, pakai design system & komponen yang sudah ada.

Catatan konsistensi: lagu "Hati-Hati di Jalan — Tulus" saat ini punya warna cover yang
berbeda-beda di tiap layar (pink-ungu di Beranda, oranye di MiniPlayer layar Cari, biru di
daftar hasil B2). Samakan semuanya memakai satu gradient cover yang sama, dan pakai cover itu
juga sebagai lagu yang sedang diputar di layar-layar Player di bawah.

LAYAR C — Now Playing (full screen, dibuka dari MiniPlayer)
- Background: gradient halus diambil dari warna dominan cover, memudar ke #0E0E12.
- Atas: tombol chevron-down (tutup), teks kecil "Diputar dari: Hasil pencarian", tombol more.
- Cover besar persegi ±326x326 radius 16 dengan shadow lembut.
- Judul lagu (Title, bisa marquee) + artis, tombol like (hati) di kanan.
- Seek bar (thumb bulat accent) + waktu berjalan & total durasi.
- Kontrol: shuffle, previous, PLAY/PAUSE (bulat besar 72 fill accent), next, repeat
  (tunjukkan state repeat aktif).
- Baris bawah: ikon antrean (queue), ikon lirik, ikon tambah ke playlist.
- Buat juga state "Buffering" (spinner di tombol play) dan state error
  ("Gagal memutar lagu" + tombol "Coba lagi").

LAYAR D — Lirik
- Lirik tersinkron: baris aktif besar & putih, baris lain text-muted, auto-scroll.
- Mini kontrol play/pause + seek bar di bawah.
- State "Lirik tidak tersedia".

LAYAR E — Antrean (bottom sheet tinggi / layar penuh)
- "Sedang diputar" (1 TrackTile disorot).
- "Berikutnya" — daftar TrackTile dengan drag handle di kanan untuk mengurutkan,
  swipe untuk hapus (tunjukkan 1 item dalam kondisi di-swipe dengan latar merah).
- Toggle "Autoplay lagu serupa" di bagian bawah.
```

---

## Prompt 2.5 — Revisi Hasil Prompt 2 (kirim sebelum Prompt 3)

```
Revisi layar Player sebelum lanjut:

1. ANTREAN (E), item "Rumah ke Rumah" yang di-swipe: sekarang seluruh baris berwarna pink
   dan teks judul/artisnya hampir tidak terbaca. Perbaiki jadi pola swipe-to-delete yang benar:
   - Lapisan belakang: kotak merah ($error) selebar baris, ikon tempat sampah putih di sisi KANAN.
   - Lapisan depan: TrackTile normal (background $surface-raised, teks normal) yang digeser
     ke kiri sekitar 80px, sehingga area merah + ikon sampah terlihat di kanan.

2. TINGGI LAYAR: C, C2, C3, D, dan D2 adalah layar penuh, jadi samakan tingginya menjadi 844
   (sekarang 760 dan 654). Tambahkan ruang safe area bawah ±34px di bawah baris ikon
   (antrean/lirik/tambah ke playlist) dan di bawah kontrol pada layar Lirik.

3. C3 (Error): jangan hilangkan kontrol. Tetap tampilkan seek bar (nonaktif, opacity 40%)
   dan tombol previous / next yang aktif supaya user bisa langsung lompat ke lagu lain.
   Pesan "Gagal memutar lagu" + tombol "Coba lagi" diletakkan di antara info lagu dan kontrol.

4. LIRIK (D & D2): di header, ganti teks "Lirik" dengan judul lagu (Subtitle) + nama artis
   (Caption, text-secondary) yang ditata di tengah, supaya user tahu lirik lagu apa yang tampil.
```

---

## Prompt 3 — Koleksi & Playlist

```
Lanjutkan di file yang sama, pakai design system & komponen yang sudah ada.

LAYAR F — Koleksi
- Judul "Koleksi" + tombol "+" (buat playlist).
- Chip filter: Playlist, Disukai, Riwayat.
- Item khusus di paling atas: "Lagu yang disukai" (cover gradient accent + ikon hati, jumlah lagu).
- Daftar playlist (list: cover 56x56, nama, "Playlist • 24 lagu").
- Varian empty state: "Belum ada playlist" + tombol Primary "Buat playlist".

LAYAR G — Detail Playlist
- Header: cover besar (kolase 4 cover lagu), nama playlist, "24 lagu • 1 jam 32 mnt".
- Tombol: Play (bulat besar accent), Shuffle, more (ubah nama, hapus).
- Daftar TrackTile bernomor; satu lagu dalam state "sedang diputar".

LAYAR H — Riwayat
- Dikelompokkan per hari ("Hari ini", "Kemarin", "12 Okt 2026") dengan TrackTile.

BOTTOM SHEET:
- S1 "Opsi lagu" (dari tombol more TrackTile): cover + judul di atas, lalu menu:
  Putar berikutnya, Tambah ke antrean, Tambah ke playlist, Suka/Hapus dari disukai,
  Lihat lirik, Bagikan.
- S2 "Tambah ke playlist": tombol "Playlist baru" di atas, daftar playlist dengan checkbox.
- S3 "Buat playlist": input nama playlist + tombol "Buat".
```

---

## Prompt 4 — Autentikasi & Profil

```
Lanjutkan di file yang sama, pakai design system & komponen yang sudah ada.

LAYAR I — Splash: logo "Nada" di tengah, background #0E0E12. Logo berupa ikon lingkaran putih
dengan tiga lengkung gelombang suara memancar ke kanan di atas rounded-square merah #E11D2E,
diikuti tulisan "Nada" (Plus Jakarta Sans Bold, putih). Buat frame logo-nya sebagai komponen
"Logo" supaya nanti gampang diganti dengan file logo asli dari Gemini.

LAYAR J — Masuk
- Logo kecil + judul "Masuk", subjudul "Dengerin musik tanpa langganan".
- Input username, input password (ikon tampilkan/sembunyikan).
- Tombol Primary "Masuk", link "Punya kode undangan? Daftar".
- State error: "Username atau password salah" di bawah input.

LAYAR K — Daftar (khusus yang punya kode undangan)
- Input kode undangan (huruf kapital, mis. "NADA-7XK2"), username, password, konfirmasi password.
- Tombol Primary "Daftar". State error "Kode undangan tidak valid atau sudah dipakai".

LAYAR L — Profil & Pengaturan
- Avatar + username.
- Section "Pemutaran": Kualitas audio (Rendah / Normal / Tinggi), Autoplay lagu serupa (toggle).
- Section "Undang teman": tombol "Buat kode undangan" + kode yang dihasilkan dengan tombol salin.
- Section "Penyimpanan": Hapus cache (dengan ukuran, mis. "120 MB").
- Section "Tentang": versi aplikasi.
- Tombol Ghost merah "Keluar".

STATE GLOBAL:
- Banner offline di atas layar: "Kamu sedang offline".
- Toast sukses: "Ditambahkan ke playlist Galau Malam".
```

---

## Prompt 5 — Revisi Akhir (konsistensi)

```
Revisi akhir untuk konsistensi antar layar:

1. MINIPLAYER: tambahkan instance MiniPlayer ("Hati-Hati di Jalan — Tulus", cover yang sama)
   tepat di atas BottomNav pada layar F (Koleksi), H (Riwayat), dan L (Profil).
   Untuk layar G (Detail Playlist), tambahkan MiniPlayer + BottomNav (tab Koleksi aktif)
   di bagian bawah, dan beri padding bawah pada daftar lagu supaya tidak tertutup.
   F2 (Koleksi kosong) boleh tanpa MiniPlayer.

2. PROFIL (L): layar ini dibuka dari avatar di Beranda, tapi sekarang tidak ada cara kembali.
   Tambahkan header: tombol back (chevron-left) di kiri + judul "Profil" di tengah.
   Hilangkan BottomNav di layar ini (halaman pengaturan tidak perlu tab bar),
   dan pindahkan MiniPlayer ke paling bawah di atas safe area.

3. RIWAYAT (H): karena "Riwayat" adalah chip filter di layar Koleksi, ubah layar H menjadi
   varian layar Koleksi: judul "Koleksi" + tombol "+", baris chip dengan chip "Riwayat" aktif,
   lalu daftar riwayat per hari di bawahnya. Hapus tombol back.
   Buat juga varian F3 dengan chip "Disukai" aktif yang menampilkan daftar TrackTile
   lagu yang disukai (ikon hati merah kecil di setiap baris menggantikan tombol more).
```

---

## Checklist hasil akhir

Status dicek 17 Okt 2026 dari `Pendev/MyMusicMockup.pen`: Semua prompt (1–5) selesai. Mockup final: 28 layar.

- [x] Halaman design system (warna, tipografi, radius, spacing)
- [x] Komponen: TrackTile, PlaylistCard, MiniPlayer, BottomNav, SearchBar, Button, Chip, BottomSheet, Skeleton, Toast
- [x] Beranda, Cari (kosong / hasil / loading / tidak ditemukan)
- [x] Revisi Prompt 1.5: aksen merah, MiniPlayer di layar Cari, avatar artis bulat, Beranda empty state
- [x] Now Playing (normal / buffering / error), Lirik, Antrean
- [x] Revisi Prompt 2.5: swipe-to-delete, tinggi layar 844, kontrol di state error, header lirik
- [x] Koleksi (isi / kosong), Detail Playlist, Riwayat, 3 bottom sheet
- [x] Splash, Masuk, Daftar, Profil & Pengaturan, state offline & toast
- [x] Revisi Prompt 5: MiniPlayer di Koleksi/Riwayat/Detail/Profil, header Profil, Riwayat & Disukai sebagai varian Koleksi
