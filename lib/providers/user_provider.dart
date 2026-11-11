import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

/// UserProvider kini menggunakan ChangeNotifier (Latihan 4),
/// menggantikan InheritedWidget manual pada UserProvider/UserProviderWrapper
/// di panduan praktik utama.
class UserProvider extends ChangeNotifier {
  User _user = User(name: '', email: '');
  bool _isLoading = true;

  // Latihan 1: state tema (dark mode)
  ThemeMode _themeMode = ThemeMode.light;

  // Latihan 2: counter kunjungan
  int _visitCount = 0;

  // Latihan 3: daftar favorit
  List<String> _favorites = [];

  User get user => _user;
  bool get isLoading => _isLoading;
  ThemeMode get themeMode => _themeMode;
  int get visitCount => _visitCount;
  List<String> get favorites => List.unmodifiable(_favorites);

  UserProvider() {
    _loadUser();
  }

  // Memuat semua data dari SharedPreferences saat aplikasi dibuka
  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();

    final name = prefs.getString('user_name') ?? '';
    final email = prefs.getString('user_email') ?? '';
    final isLoggedIn = prefs.getBool('is_logged_in') ?? false;

    // Latihan 1c: muat preferensi tema saat aplikasi dibuka
    final isDarkMode = prefs.getBool('is_dark_mode') ?? false;

    // Latihan 2b: increment counter setiap kali aplikasi dibuka
    final visitCount = (prefs.getInt('visit_count') ?? 0) + 1;
    await prefs.setInt('visit_count', visitCount);

    // Latihan 3: muat daftar favorit
    final favorites = prefs.getStringList('favorites') ?? [];

    _user = User(name: name, email: email, isLoggedIn: isLoggedIn);
    _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    _visitCount = visitCount;
    _favorites = favorites;
    _isLoading = false;
    notifyListeners();
  }

  // Menyimpan data user ke SharedPreferences
  Future<void> updateUser(User newUser) async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', newUser.name);
    await prefs.setString('user_email', newUser.email);
    await prefs.setBool('is_logged_in', newUser.isLoggedIn);

    _user = newUser;
    _isLoading = false;
    notifyListeners();
  }

  // Logout: hapus data user (kecuali email)
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_name');
    await prefs.setBool('is_logged_in', false);

    _user = _user.copyWith(name: '', isLoggedIn: false);
    notifyListeners();
  }

  // --- Latihan 1: Preferensi Tema (Dark Mode) ---
  Future<void> toggleTheme() async {
    final newIsDark = _themeMode == ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', newIsDark);

    _themeMode = newIsDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  // --- Latihan 3: Daftar Favorit ---
  Future<void> addFavorite(String item) async {
    final value = item.trim();
    if (value.isEmpty || _favorites.contains(value)) return;

    _favorites.add(value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorites', _favorites);
    notifyListeners();
  }

  Future<void> removeFavorite(String item) async {
    _favorites.remove(item);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorites', _favorites);
    notifyListeners();
  }

  // --- Latihan 5a: Cek apakah email sudah digunakan (simulasi) ---
  // Simulasi sederhana: hanya ada satu "akun" yang tersimpan di SharedPreferences.
  // Email dianggap sudah dipakai jika cocok dengan email tersimpan, KECUALI
  // user yang sedang LOGIN sedang mengedit profilnya sendiri dengan email yang sama.
  //
  // PENTING: syaratnya harus _user.isLoggedIn, bukan sekadar "email di memori sama
  // dengan email tersimpan". Soalnya _loadUser() selalu memuat user_email yang
  // tersimpan ke _user.email walau status login-nya false (guest). Kalau syarat
  // isLoggedIn tidak dicek, _user.email akan SELALU sama dengan savedEmail, dan
  // pengecekan ini jadi selalu lolos (bug: tidak pernah terdeteksi "sudah dipakai").
  Future<bool> isEmailTaken(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('user_email') ?? '';
    final value = email.trim();

    if (savedEmail.isEmpty) return false;
    if (_user.isLoggedIn && savedEmail == _user.email) {
      return false; // email milik sendiri, sedang login
    }
    return savedEmail == value;
  }
}