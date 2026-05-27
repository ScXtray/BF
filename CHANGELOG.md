# CHANGELOG — Xtray Script

Semua perubahan yang pernah dilakukan di project ini, dari awal hingga sekarang.
Format: `[Tanggal] versi — deskripsi`

---

## [2026-05-27] v2.0.0 — Panda-Hub Logic + Cleanup

### main.luau
- Hapus entri `MemeSea.luau` & `VoxSeas.luau` dari tabel `Scripts` (file sudah dihapus dari repo)
- Perbaiki pesan "Game tidak didukung" — tidak lagi menyebut Meme Sea/Vox Seas
- Buang ~140 baris kode lama (`--[[...]]`) sisa dari PlockScripts/Testes yang tertinggal
- Bersihkan 15+ baris kosong berlebih
- URL sudah benar mengarah ke `ScXtray/BF`

### Games/BloxFruits.luau — Perbaikan Logika (UI tidak diubah sama sekali)
- **`BringEnemiesToPlayer`** — tambah `hrp.Size = Vector3.new(60,60,60)`, `PlatformStand = true`, `Sit = true`, `CanCollide = false`, `SimulationRadius = math.huge` (teknik Panda-Hub)
- **`KillAuraOnce`** — tambah `PlatformStand = true`, `Sit = true`, `hrp.CFrame = root.CFrame` agar musuh benar-benar ke posisi player sebelum di-kill
- **`TryAcceptQuest`** — ganti `"TakeQuest"` → `SetSpawnPoint` dulu lalu `"StartQuest"` + slot number (teknik Panda-Hub yang benar)
- **`TryCompleteQuest`** — tetap `"TurnInQuest"` tapi dibungkus pcall yang lebih aman
- **`IsQuestActive`** — prioritas cek `PlayerGui.Main.Quest.Visible` (akurat), fallback ke `Data.Quest.Value`
- **`IsQuestComplete`** — cek `questFrame.Visible == false`, fallback ke Data
- **Auto Farm loop** — tambah `SimulationRadius = math.huge` di setiap tick, ganti teleport abrupt → `pcall(TweenFlyTo, hrp.Position)` untuk pergerakan smooth, tick dipercepat dari 0.1 → 0.07s
- **Versi notifikasi** — diupdate dari v1.5.0 → v2.0.0
- **Header komentar** — URL diupdate ke `github.com/ScXtray/BF`

---

## [2026-05-xx] v1.5.0 — Migrasi Repo + Rewrite Games

### Migrasi Repo
- Repo lama `XtrayScript/XtrayScript` kena suspend
- Migrasi ke `ScXtray/BF`
- Update semua URL di `main.luau` ke repo baru

### Games/MemeSea.luau
- Ditulis ulang dari awal (~500 baris, redzlib UI)
- Fitur: Auto Farm, ESP, Auto Quest, Movement
- **Kemudian dihapus** dari repo atas permintaan user (2026-05-27)

### Games/VoxSeas.luau
- Ditulis dari awal (newredzv3 style)
- Fitur: Tween movement (BodyVelocity), BringMobs, ESP, Auto Farm
- PlaceId: `104067066727140`
- **Kemudian dihapus** dari repo atas permintaan user (2026-05-27)

---

## [2026-05-xx] v1.0.0 — Initial Setup

### main.luau
- Setup fetcher + URL resolver (`{Repository}`, `{Utils}`, dll.)
- Debounce anti-double-execute (`rz_execute_debounce`)
- Auto queue_on_teleport untuk persistent script setelah teleport server
- Routing berdasarkan `PlaceId` → load file game yang sesuai
- Error handler dengan `Message` instance di workspace

### Games/BloxFruits.luau
- File utama Blox Fruits (Sea 1, Sea 2, Sea 3)
- UI menggunakan redzlib (`{Repository}Library/main.luau`)
- PlaceId didukung: Sea1 (`2753915549`, `85211729168715`), Sea2 (`4442272183`, `79091703265657`), Sea3 (`7449423635`, `100117331123089`)
- Fitur: Auto Farm, Kill Aura, Auto Quest, Auto Boss, Auto Fishing, Mastery Farm, Auto Chest, Sea Event Farm, ESP, NoClip, Speed/Jump Hack, Anti-AFK, Auto Buso, dan banyak Extras

### Utils/
- `Movement.luau` — speed, jump, fly
- `FullBright.luau` — hapus ambient gelap
- `AntiReset.luau` — block karakter reset
- `BloxFruitsESP.luau` — ESP khusus BF
- `FastAttack.luau` — percepat CombatFramework
- `Module/Tween-Module.luau` — tween fly smooth (BodyVelocity)

---

## Catatan Penting

- Dua akun GitHub sebelumnya (`XtrayScript` dan akun lain) kena suspend — selalu backup token
- Push ke GitHub **hanya via GitHub REST API** (git push diblokir di Replit sandbox)
- SHA file harus diambil ulang setiap sebelum push/delete
