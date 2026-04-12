1. Struktur Folder & Pemisahan File : transaction_store_page.dart(Halaman utama) dan transaction_store_card(Komponen item list) 
2. Fitur Utama yang Harus Ada
    Filter Tanggal: User pasti ingin melihat transaksi kemarin atau bulan lalu. Gunakan DateRangePicker.
    Status Badge: Berikan warna berbeda untuk tiap status (misal: Paid = Hijau, Pending = Kuning, Batal = Merah).
    Search Bar: Untuk mencari berdasarkan nomor invoice atau nama pelanggan.
    Summary Mini Card: Menampilkan total omzet hari ini di bagian atas list.(untuk ini saya sudah ada api nya tapi kita bahas lain waktu) !
3. Infinite Scroll: Gunakan ScrollController untuk memuat data transaksi lebih banyak saat user scroll ke bawah (Pagination).
4. State Management: Karena data transaksi di POS sering berubah, pastikan kamu menggunakan Provider, Bloc, atau GetX agar data sinkron dengan database lokal/  cloud.
5. Empty State: Jangan lupa buat UI untuk kondisi saat transaksi belum ada (misal gambar ilustrasi keranjang kosong).

<!--  -->