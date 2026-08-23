# HƯỚNG DẪN CHI TIẾT DỰNG LẠI GAME 2D "AIR FORCE 1943" TRÊN UNITY

> **Mục đích:** Tài liệu hướng dẫn từng bước chi tiết dành cho Bạn và AI Assistants (ChatGPT, Claude, Antigravity, GitHub Copilot) để lập trình dựng lại game bắn máy bay 2D cuộn màn hình dọc từ tài nguyên đã trích xuất.

---

## I. TỔNG QUAN DỰ ÁN

* **Thể loại:** 2D Top-Down Vertical Scrolling Shooter (Bắn máy bay cuộn dọc).
* **Công cụ:** Unity 2D (Phiên bản 2021/2022/6 xịn nhất).
* **Tài nguyên sẵn có trong thư mục:**
  * 📁 `extracted_assets/Textures`: Sprites máy bay, đạn, nổ, UI, background.
  * 📁 `extracted_assets/Audio`: Tiếng súng, tiếng nổ, tiếng động cơ, nhạc nền.
  * 📁 `extracted_assets/Fonts`: Font chữ arcade retro.

---

## II. CẤU TRÚC THƯ MỤC UNITY KHUYÊN DÙNG

```text
Assets/
├── Audio/
│   ├── BGM/
│   └── SFX/
├── Prefabs/
│   ├── Bullets/
│   ├── Enemies/
│   ├── FX/
│   └── PowerUps/
├── Scenes/
│   ├── MainMenu.unity
│   └── MainGame.unity
├── Scripts/
│   ├── Core/           (GameManager, AudioManager, ObjectPool)
│   ├── Player/         (PlayerController, PlayerShooter)
│   ├── Enemy/          (EnemyController, WaveSpawner, BossController)
│   ├── Combat/         (Health, DamageDealer, Bullet)
│   └── UI/             (UIManager, ScoreManager)
└── Sprites/
    ├── Player/
    ├── Enemies/
    ├── Bullets/
    ├── Backgrounds/
    └── UI/
```

---

## III. HƯỚNG DẪN CHI TIẾT TỪNG BƯỚC THỰC HIỆN

### BƯỚC 1: CÀI ĐẶT THIẾT LẬP BAN ĐẦU (PROJECT SETUP)
1. **Tạo Project:** Chọn template **Unity 2D (Built-in)** hoặc **2D URP**.
2. **Tỉ lệ màn hình (Aspect Ratio):**
   * Trong cửa sổ `Game` View -> Thêm tỉ lệ màn hình dọc: **9:16** (1080x1920) hoặc **3:4** (600x800).
3. **Phân lớp hiển thị (Sorting Layers):**
   * `Background` (dưới cùng)
   * `Debris` (mảnh vỡ, khói)
   * `Enemies` (máy bay địch)
   * `Player` (máy bay ta)
   * `Bullets` (đạn)
   * `Effects` (hiệu ứng nổ)
   * `UI` (trên cùng)

---

### BƯỚC 2: TẠO MÁY BAY NGƯỜI CHƠI (PLAYER CONTROLLER)
1. Kéo Sprite máy bay từ `extracted_assets/Textures` vào Scene.
2. Thêm component `SpriteRenderer`, `BoxCollider2D` (Tick `Is Trigger`), `Rigidbody2D` (Body Type: `Kinematic`).
3. **Màu sắc (Sprite Tinting):** Chọn màu sắc cho máy bay ở ô `Color` của `SpriteRenderer`.

#### 📝 Code mẫu: `PlayerController.cs`
```csharp
using UnityEngine;

public class PlayerController : MonoBehaviour
{
    [Header("Movement")]
    public float moveSpeed = 8f;
    public Vector2 padding = new Vector2(0.5f, 0.5f);

    private Vector2 minBounds;
    private Vector2 maxBounds;
    private SpriteRenderer spriteRenderer;

    void Start()
    {
        spriteRenderer = GetComponent<SpriteRenderer>();
        InitBounds();
    }

    void Update()
    {
        Move();
    }

    void InitBounds()
    {
        Camera mainCamera = Camera.main;
        minBounds = mainCamera.ViewportToWorldPoint(new Vector2(0, 0)) + (Vector3)padding;
        maxBounds = mainCamera.ViewportToWorldPoint(new Vector2(1, 1)) - (Vector3)padding;
    }

    void Move()
    {
        float deltaX = Input.GetAxis("Horizontal") * moveSpeed * Time.deltaTime;
        float deltaY = Input.GetAxis("Vertical") * moveSpeed * Time.deltaTime;

        Vector2 newPos = new Vector2();
        newPos.x = Mathf.Clamp(transform.position.x + deltaX, minBounds.x, maxBounds.x);
        newPos.y = Mathf.Clamp(transform.position.y + deltaY, minBounds.y, maxBounds.y);

        transform.position = newPos;
    }

    public void SetPlayerColor(Color color)
    {
        if (spriteRenderer != null) spriteRenderer.color = color;
    }
}
```

---

### BƯỚC 3: HỆ THỐNG BAN ĐẠN (SHOOTING & BULLETS)
1. **Tạo Bullet Prefab:**
   * Gán Sprite viên đạn.
   * Thêm `Rigidbody2D` (Kinematic) + `BoxCollider2D` (Is Trigger).
   * Gán Tag: `"PlayerBullet"` hoặc `"EnemyBullet"`.

#### 📝 Code mẫu: `Bullet.cs`
```csharp
using UnityEngine;

public class Bullet : MonoBehaviour
{
    public float speed = 12f;
    public Vector2 direction = Vector2.up;
    public float lifetime = 3f;

    void OnEnable()
    {
        CancelInvoke();
        Invoke(nameof(Deactivate), lifetime);
    }

    void Update()
    {
        transform.Translate(direction * speed * Time.deltaTime);
    }

    void Deactivate()
    {
        gameObject.SetActive(false);
    }
}
```

#### 📝 Code mẫu: `PlayerShooter.cs`
```csharp
using UnityEngine;

public class PlayerShooter : MonoBehaviour
{
    public GameObject bulletPrefab;
    public Transform firePoint;
    public float fireRate = 0.15f;
    private float nextFireTime = 0f;

    void Update()
    {
        if (Input.GetButton("Fire1") && Time.time >= nextFireTime)
        {
            Shoot();
            nextFireTime = Time.time + fireRate;
        }
    }

    void Shoot()
    {
        if (bulletPrefab != null && firePoint != null)
        {
            Instantiate(bulletPrefab, firePoint.position, Quaternion.identity);
            // Phát âm thanh bắn đạn
            if (AudioManager.Instance != null)
            {
                AudioManager.Instance.PlaySFX("Shoot");
            }
        }
    }
}
```

---

### BƯỚC 4: NỀN CUỘN BẦU TRỜI/BIỂN (SCROLLING BACKGROUND)
1. Tạo 1 Quad 3D hoặc 2D Sprite lớn bao phủ toàn bộ Camera.
2. Gán Texture Nền (Background Texture) chọn Mode `Wrap Mode: Repeat`.

#### 📝 Code mẫu: `ScrollingBackground.cs`
```csharp
using UnityEngine;

public class ScrollingBackground : MonoBehaviour
{
    public float scrollSpeed = 0.5f;
    private Renderer quadRenderer;

    void Start()
    {
        quadRenderer = GetComponent<Renderer>();
    }

    void Update()
    {
        Vector2 offset = new Vector2(0, Time.time * scrollSpeed);
        quadRenderer.material.mainTextureOffset = offset;
    }
}
```

---

### BƯỚC 5: HỆ THỐNG KẺ ĐỊCH VÀ XUẤT HIỆN THEO ĐỢT (ENEMY & WAVE SPAWNER)
1. **Enemy Controller:** Di chuyển xuống dưới, lượn sóng ziczac, tự động bắn đạn.

#### 📝 Code mẫu: `EnemyController.cs`
```csharp
using UnityEngine;

public class EnemyController : MonoBehaviour
{
    public float speed = 3f;
    public float scoreValue = 100;
    public GameObject bulletPrefab;
    public float fireInterval = 2f;

    void Start()
    {
        InvokeRepeating(nameof(Shoot), 1f, fireInterval);
    }

    void Update()
    {
        transform.Translate(Vector3.down * speed * Time.deltaTime);

        // Hủy kẻ địch khi ra khỏi màn hình
        if (transform.position.y < -7f)
        {
            Destroy(gameObject);
        }
    }

    void Shoot()
    {
        if (bulletPrefab != null)
        {
            GameObject b = Instantiate(bulletPrefab, transform.position, Quaternion.identity);
            Bullet bulletComp = b.GetComponent<Bullet>();
            if (bulletComp != null) bulletComp.direction = Vector2.down;
        }
    }
}
```

---

### BƯỚC 6: HỆ THỐNG MÁU & VA CHẠM (HEALTH & COLLISION)

#### 📝 Code mẫu: `Health.cs`
```csharp
using UnityEngine;

public class Health : MonoBehaviour
{
    public float maxHealth = 100f;
    public float currentHealth;
    public GameObject explosionFX;
    public bool isPlayer = false;

    void Start()
    {
        currentHealth = maxHealth;
    }

    public void TakeDamage(float amount)
    {
        currentHealth -= amount;
        if (currentHealth <= 0)
        {
            Die();
        }
    }

    void Die()
    {
        if (explosionFX != null)
        {
            Instantiate(explosionFX, transform.position, Quaternion.identity);
        }
        if (AudioManager.Instance != null)
        {
            AudioManager.Instance.PlaySFX("Explosion");
        }

        if (isPlayer)
        {
            // Game Over Logic
            GameManager.Instance.GameOver();
        }
        else
        {
            GameManager.Instance.AddScore(100);
        }

        Destroy(gameObject);
    }

    private void OnTriggerEnter2D(Collider2D other)
    {
        if (other.CompareTag("Bullet"))
        {
            TakeDamage(20);
            other.gameObject.SetActive(false);
        }
    }
}
```

---

### BƯỚC 7: QUẢN LÝ ÂM THANH (AUDIO MANAGER)

#### 📝 Code mẫu: `AudioManager.cs`
```csharp
using UnityEngine;
using System.Collections.Generic;

public class AudioManager : MonoBehaviour
{
    public static AudioManager Instance;

    public AudioSource bgmSource;
    public AudioSource sfxSource;

    [System.Serializable]
    public struct Sound
    {
        public string name;
        public AudioClip clip;
    }

    public List<Sound> sounds;
    private Dictionary<string, AudioClip> soundDict;

    void Awake()
    {
        if (Instance == null) Instance = this;
        else Destroy(gameObject);

        soundDict = new Dictionary<string, AudioClip>();
        foreach (var s in sounds)
        {
            soundDict[s.name] = s.clip;
        }
    }

    public void PlaySFX(string name)
    {
        if (soundDict.ContainsKey(name))
        {
            sfxSource.PlayOneShot(soundDict[name]);
        }
    }

    public void PlayBGM(string name)
    {
        if (soundDict.ContainsKey(name))
        {
            bgmSource.clip = soundDict[name];
            bgmSource.Play();
        }
    }
}
```

---

## IV. MẪU PROMPT CHUẨN ĐỂ COPY CHO AI (CHATGPT / CLAUDE / ANTIGRAVITY)

Khi bạn muốn bảo AI làm tiếp bất kỳ tính năng nào, hãy copy 1 trong các câu Prompt dưới đây:

### 🤖 PROMPT 1: Tạo Spawner kẻ địch theo wave nhiều loại máy bay
> *"Tôi đang làm game 2D Air Force 1943 trong Unity C#. Hãy viết cho tôi script `WaveSpawner.cs` quản lý sinh ra kẻ địch theo từng đợt (waves). Hỗ trợ danh sách các loại máy bay địch (Medium01, Large02...), quy định số lượng máy bay mỗi wave, khoảng thời gian spawn giữa các máy bay, và vị trí spawn ngẫu nhiên trên đỉnh màn hình."*

### 🤖 PROMPT 2: Tạo vật phẩm nâng cấp đạn (Power-up System)
> *"Hãy viết script Unity C# `PowerUp.cs` và cập nhật `PlayerShooter.cs` cho game bắn máy bay 2D. Khi kẻ địch bị tiêu diệt, có tỉ lệ rơi ra Item Power-up (nâng cấp đạn từ 1 nòng -> 2 nòng -> 3 nòng chéo -> đạn laser). Khi máy bay ta va chạm vật phẩm thì đạn được nâng cấp level và phát âm thanh ăn vật phẩm."*

### 🤖 PROMPT 3: Lập trình Boss cuối màn (Boss Multi-Phase AI)
> *"Hãy viết script `BossController.cs` cho Trùm cuối màn game 2D Unity. Boss có 3 giai đoạn máu (Phase 1: bắn đạn tỏa tròn, Phase 2: di chuyển ngang và bắn đạn chùm, Phase 3: xả đạn nhanh và di chuyển lại gần player). Hiển thị thanh máu Boss dạng UI slider."*

---

## V. TỔNG KẾT QUY TRÌNH THỰC HIỆN DỰ ÁN

1. **Bước 1:** Tạo Unity Project 2D -> Import các ảnh từ `extracted_assets/Textures` & `Audio`.
2. **Bước 2:** Đổi màu Sprite `SpriteRenderer.color` cho máy bay ta (Xanh), máy bay địch (Đỏ/Vàng).
3. **Bước 3:** Tạo Script `PlayerController.cs` & `PlayerShooter.cs` cho di chuyển và bắn đạn.
4. **Bước 4:** Tạo Prefabs Kẻ địch + Script `EnemyController.cs` & `WaveSpawner.cs`.
5. **Bước 5:** Tạo `ScrollingBackground.cs` làm nền bầu trời di chuyển.
6. **Bước 6:** Thêm `Health.cs` & `GameManager.cs` để tính điểm, hiển thị UI máu, Score, Game Over.
