# PROJECT CONTEXT — Baca ini sebelum mulai!

File ini dibuat agar AI Agent baru langsung paham project tanpa perlu membaca semua file satu per satu.

---

## Apa ini?

**Xtray Script** — script hub Roblox yang gratis dan tidak memerlukan key.
Saat ini hanya mendukung **Blox Fruits** (Sea 1, Sea 2, Sea 3).

---

## Repo GitHub

- **URL**: `https://github.com/ScXtray/BF`
- **Branch utama**: `main`
- **Raw base URL**: `https://raw.githubusercontent.com/ScXtray/BF/refs/heads/main/`

### Cara push ke GitHub (WAJIB lewat REST API)
```
git push diblokir di Replit sandbox — SELALU gunakan GitHub REST API.
```
Langkah push:
1. Base64 encode file lokal
2. Tulis ke file JSON: `{ "message": "...", "content": "<base64>", "sha": "<sha_file_saat_ini>" }`
3. `curl -X PUT https://api.github.com/repos/ScXtray/BF/contents/<path> -H "Authorization: token $GITHUB_TOKEN" -d @payload.json`
4. Untuk **delete**: `curl -X DELETE` dengan body `{ "message": "...", "sha": "..." }`
5. SHA selalu ambil fresh dari API sebelum setiap push/delete

> ⚠️ **ATURAN WAJIB**: Semua update GitHub HARUS mendapat persetujuan user terlebih dahulu sebelum dieksekusi.
>
> ⏱️ **AUTO-PUSH RULE**: Jika persetujuan sudah diminta tetapi user tidak merespons dalam **20 menit**, anggap **disetujui otomatis** dan langsung push/eksekusi. Alasan: user kemungkinan sudah kehabisan limit sesi dan tidak bisa melanjutkan percakapan.

---

## Struktur File di Repo

```
ScXtray/BF/
├── main.luau                        ← Entry point utama (loadstring ini dari executor)
├── CHANGELOG.md                     ← Riwayat semua perubahan
├── PROJECT_CONTEXT.md               ← File ini
├── Games/
│   └── BloxFruits.luau              ← Script utama Blox Fruits (3500+ baris)
├── Library/
│   └── main.luau                    ← UI Library (redzlib)
├── Utils/
│   └── Module/
│       ├── Movement.luau            ← Speed / Jump / Fly
│       ├── FullBright.luau          ← Hapus ambient gelap
│       ├── AntiReset.luau           ← Block reset karakter
│       ├── BloxFruitsESP.luau       ← ESP khusus BF
│       ├── FastAttack.luau          ← Percepat CombatFramework
│       └── Tween-Module.luau        ← Tween fly smooth (BodyVelocity)
└── Translator/                      ← (opsional) terjemahan teks UI
```

File lokal di Replit ada di: `xtray-repo/`

---

## Stack & Teknologi

| Komponen | Detail |
|----------|--------|
| Bahasa | Luau (Roblox) |
| UI Library | **redzlib** — load via `fetcher.load("{Repository}Library/main.luau")()` |
| Tween/Fly | `TweenModule` dari `Utils/Module/Tween-Module.luau` |
| Push method | GitHub REST API (`curl PUT`) |
| Token | Tersimpan di Replit secret: `GITHUB_TOKEN` |

---

## Cara Kerja main.luau

1. Definisikan tabel `Scripts` berisi mapping `PlaceId → UrlPath`
2. Setup `fetcher` (HTTP getter + loadstring wrapper) dengan URL resolver `{Repository}`, `{Utils}`
3. Debounce anti-spam eksekusi berulang
4. Auto `queue_on_teleport` agar script persistent setelah pindah server
5. Loop cek `game.PlaceId` → kalau cocok, load & eksekusi file game yang sesuai

PlaceId Blox Fruits yang didukung:
- Sea 1: `2753915549` (lama), `85211729168715` (baru)
- Sea 2: `4442272183` (lama), `79091703265657` (baru)
- Sea 3: `7449423635` (lama), `100117331123089` (baru)

---

## BloxFruits.luau — Ringkasan

File terbesar (~3536 baris). **UI TIDAK BOLEH DIUBAH** — hanya logika helper functions.

### Modul yang diload
- `Library` — redzlib UI
- `Movement`, `FullBright`, `AntiReset`, `ESP`, `FastAttack` — via `safeLoad()` (gagal → fallback kosong)
- `TweenModule` — fly smooth; fallback ke teleport instan jika gagal load

### State penting (tabel `State`)
Semua toggle fitur disimpan di `State`. Contoh: `State.AutoFarm`, `State.KillAura`, `State.FarmRange`, dll.

### Fungsi helper utama

| Fungsi | Tujuan |
|--------|--------|
| `GetCharacter()` | Dapatkan karakter LocalPlayer |
| `GetRootPart()` | Dapatkan HumanoidRootPart |
| `GetLevel()` | Baca level dari `LocalPlayer.Data.Level` |
| `TeleportTo(pos)` | Teleport instan (CFrame) |
| `TweenFlyTo(pos, speed)` | Terbang smooth ke posisi via TweenModule |
| `BringEnemiesToPlayer()` | Tarik musuh ke player (Size 60 + PlatformStand + SimulationRadius) |
| `KillAuraOnce(range)` | Bunuh semua musuh dalam range |
| `TryAcceptQuest(quest)` | Accept quest via `CommF_:InvokeServer("StartQuest", ...)` |
| `IsQuestActive()` | Cek via `PlayerGui.Main.Quest.Visible` |
| `IsQuestComplete()` | Cek quest frame tidak visible |
| `AttackWithWeapon()` | Aktifkan tool sesuai `State.WeaponType` |

### Remote utama
- `CommF_` = `ReplicatedStorage.Remotes.CommF_` (InvokeServer untuk semua aksi)

### Teknik dari Panda-Hub (sudah diimplementasikan)
- BringMobs: `hrp.Size = 60` + `PlatformStand` + `Sit` + `CanCollide = false` + `SimulationRadius = math.huge`
- Quest: `SetSpawnPoint` → `StartQuest` (bukan `TakeQuest`)
- Quest check: `PlayerGui.Main.Quest.Visible` (bukan cek Data)
- Auto Farm: `SimulationRadius = math.huge` di setiap tick loop

---

## Aturan Kerja (WAJIB diikuti)

1. **Pelajari source secara detail** sebelum membuat perubahan apapun
2. **Minta persetujuan user** sebelum push/delete apapun ke GitHub
3. **Jangan ubah UI/GUI** di BloxFruits.luau — hanya logika di helper functions
4. **Selalu ambil SHA terbaru** sebelum push ke GitHub
5. **Gunakan file JSON** untuk payload besar (bukan env var, terlalu panjang)
6. **Catat di CHANGELOG.md** setiap ada perubahan yang diapprove dan dipush
7. **AUTO-PUSH setelah 20 menit**: Jika persetujuan sudah diminta dan user tidak merespons selama 20 menit, langsung push/eksekusi tanpa menunggu — user kemungkinan sudah kehabisan limit sesi. Tidak perlu tanya ulang.

---

## Riwayat Akun GitHub

| Akun | Status |
|------|--------|
| `XtrayScript` | ❌ Suspended |
| `ScXtray` | ✅ Aktif (digunakan sekarang) |

---

## File Lokal di Replit

Semua file ada di `xtray-repo/`. Kalau perlu edit, edit di sana dulu, baru push ke GitHub setelah disetujui user.
