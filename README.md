DokiDoki — Anime Explorer (Flutter)

Aplikasi katalog anime dengan UI modern berbasis Flutter, terintegrasi API Jikan v4. Jelajahi anime berdasarkan genre, trending, rilis musim ini, lakukan pencarian, lihat detail, dan simpan ke Watchlist.

Built for NusaCode Flutter Bootcamp — final project.

## ✨ Fitur Utama
### Home 
    • Hero carousel (highlight anime)
    • Explore Genres (kartu ikon berwarna, horizontal)
    • Daftar horizontal: Recommended, Trending Now, This Season, Top Movies
### Search: Pencarian judul anime 
### Detail Anime: Overview, Episodes (paging), Characters
### Watchlist: Simpan anime favorit
### Settings:
    • Theme: System / Light / Dark (preview cards)
    • Safe Mode (SFW)
    • Prefer English Titles 
### Performa:
    • Cache gambar (CachedNetworkImage)
    • State management provider

## 🧱 Arsitektur & Teknologi

Teknologi: Flutter 3+, Dart, Dio (HTTP), Provider, SharedPreferences, CachedNetworkImage, Google Fonts, url_launcher, Hive (opsional), flutter_launcher_icons.

Struktur direktori (ringkas):


    lib/
      core/
        anime_api.dart          # Client Jikan v4 (sfw param, search, genre, season, dsb.)
      models/
        anime.dart              # Model utama + parser
      providers/
        anime_provider.dart     # State home & list
        watchlist_provider.dart # State watchlist (local)
      features/
        home/                   # Home + widget horizontal list, hero carousel, genres
        search/                 # Search page
        genre/                  # Genre list page (grid)
        detail/                 # Detail page (overview/episodes/characters)
        watchlist/              # Watchlist page
        settings/               # Settings page + provider


## 📦 Prasyarat

• Flutter SDK 3.x

• Android Studio / Xcode (untuk build device)

• (Opsional) Postman/Insomnia untuk eksplorasi API

## 🔑 Integrasi API

Menggunakan Jikan v4 (public, read-only)

## 🗺️ Roadmap (Ide Pengembangan)

• Filter lanjutan (tipe, skor, tahun)

• Mode offline dasar (cache data ringkas)

• Personalisasi rekomendasi

• Export/Import Watchlist (JSON)
         
    Catatan: Rate limit Jikan dapat memicu 429 Too Many Requests. Gunakan debounce, batasi refresh, dan tunggu sesuai Retry-After jika diperlukan.
## 📫 Kontak

Author: Joy Melvin Ginting

Email : zoymelvin04@gmail.com

Repo: [https://github.com/<USERNAME>/DokiDoki](https://github.com/zoymelvin/DokiDoki)

## 🖼️ Screenshot

## Home : 
<img width="185" height="620" alt="Screenshot 2025-09-23 142511" src="https://github.com/user-attachments/assets/d11eee9f-2ad5-45cd-b04b-07b9502fd834" />

## Genre (Action) :
<img width="185" height="620" alt="Screenshot 2025-09-23 142457" src="https://github.com/user-attachments/assets/d2914e32-972a-40d9-a1a0-7b6026f84751" />

## Watchlist :
<img width="185" height="620" alt="Screenshot 2025-09-23 142528" src="https://github.com/user-attachments/assets/7b212d43-bcae-4ac2-89c7-2fd211831562" />

## Settings :
<img width="185" height="620" alt="Screenshot 2025-09-23 142609" src="https://github.com/user-attachments/assets/c3967a42-e1dc-496d-85e9-d896b85050ef" />
