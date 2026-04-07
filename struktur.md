lib/
├── core/                # Sesuatu yang dipakai di seluruh aplikasi
│   ├── constants/       # Warna BRI, ukuran font, API Keys
│   ├── error/           # Handling error/failure
│   ├── network/         # Konfigurasi Dio / HTTP Client
│   ├── theme/           # Tema Biru BRI & Styling
│   └── utils/           # Helper fungsi (format Rupiah, date picker)
│
├── data/                # Sumber Data (Pusat Data)
│   ├── models/          # Konversi JSON ke Object (ProductModel)
│   ├── repositories/    # Implementasi ambil data dari API/Lokal
│   └── sources/         # Remote (API) & Local (SQLite/Hive) source
│
├── domain/              # Logika Bisnis (Otak Aplikasi)
│   ├── entities/        # Object murni (Product, Transaction)
│   └── repositories/    # Kontrak/Interface data
│
├── presentation/        # Tampilan (UI)
│   ├── bloc/            # State Management (Cubit/Bloc/Provider)
│   ├── pages/           # Layar utama (LoginPage, DashboardPage)
│   └── widgets/         # Komponen kecil (CustomButton, ProductCard)
│
└── main.dart            # Titik awal aplikasi

{"email": "owners1@ge.com", "password": "owners1"} IP LEPTOPS : 192.168.100.164 2404:

gagal memproses type string is not subtype of type int of index