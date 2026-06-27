import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../widgets/shared_widgets.dart';
import 'home_screen.dart' show AppBottomNav;

class ProfileScreen extends StatelessWidget {
  final Map<Department, int> learnedCounts;
  final int gold;
  final int streak;
  final Function(int) onTabSelect;

  const ProfileScreen({
    super.key,
    required this.learnedCounts,
    required this.gold,
    required this.streak,
    required this.onTabSelect,
  });

  int get _totalLearned => learnedCounts.values.fold(0, (a, b) => a + b);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildStats(),
              const SizedBox(height: 28),
              _buildPremiumSection(context),
              const SizedBox(height: 28),
              _buildLegalSection(context),
              const SizedBox(height: 28),
              _buildDiger(context),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNav(currentIndex: 4, onTap: onTabSelect),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.bg3,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.fen.withValues(alpha: 0.4), width: 2),
          ),
          child: const Center(child: Text('🎮', style: TextStyle(fontSize: 28))),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Oyuncu', style: AppTextStyles.display(20, weight: FontWeight.w700)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.sosyal.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.sosyal.withValues(alpha: 0.35)),
              ),
              child: Text('Ücretsiz Plan', style: AppTextStyles.mono(11, color: AppColors.sosyal)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStats() {
    return Row(
      children: [
        _StatCard(label: 'Öğrenilen', value: _totalLearned.toString(), emoji: '📚'),
        const SizedBox(width: 10),
        _StatCard(label: 'Altın', value: gold.toString(), emoji: '🪙'),
        const SizedBox(width: 10),
        _StatCard(label: 'Seri', value: streak.toString(), emoji: '🔥'),
      ],
    );
  }

  Widget _buildPremiumSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('PREMIUM ÜYELİK', style: AppTextStyles.label(11)),
        const SizedBox(height: 6),
        Text('Tüm özelliklere erişmek için bir plan seç.',
            style: AppTextStyles.body(12, color: AppColors.muted)),
        const SizedBox(height: 14),
        _PremiumCard(
          title: 'Aylık',
          price: '₺29',
          period: '/ay',
          features: const ['Sınırsız quiz', 'Gelişmiş istatistik', 'Reklamsız'],
          isHighlighted: false,
          onTap: () => _showPurchaseDialog(context, 'Aylık Plan', '₺29/ay'),
        ),
        const SizedBox(height: 10),
        _PremiumCard(
          title: 'Yıllık',
          price: '₺199',
          period: '/yıl',
          features: const ['Sınırsız quiz', 'Gelişmiş istatistik', 'Reklamsız', '%43 tasarruf'],
          isHighlighted: true,
          badge: 'EN POPÜLER',
          onTap: () => _showPurchaseDialog(context, 'Yıllık Plan', '₺199/yıl'),
        ),
        const SizedBox(height: 10),
        _PremiumCard(
          title: 'Ömür Boyu',
          price: '₺499',
          period: '',
          features: const ['Sınırsız quiz', 'Gelişmiş istatistik', 'Reklamsız', 'Tek seferlik ödeme'],
          isHighlighted: false,
          onTap: () => _showPurchaseDialog(context, 'Ömür Boyu Plan', '₺499'),
        ),
      ],
    );
  }

  void _showPurchaseDialog(BuildContext context, String plan, String price) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bg2,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBR),
        title: Text(plan, style: AppTextStyles.display(16, weight: FontWeight.w700)),
        content: Text(
          '$price planını satın almak istiyor musun?\n\nÖdeme sistemi yakında aktif olacak.',
          style: AppTextStyles.body(13, color: AppColors.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('İptal', style: AppTextStyles.body(14, color: AppColors.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Tamam', style: AppTextStyles.body(14, color: AppColors.fen, weight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('YASAL METİNLER', style: AppTextStyles.label(11)),
        const SizedBox(height: 12),
        SurfaceCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _LegalItem(
                icon: Icons.privacy_tip_outlined,
                title: 'Gizlilik Politikası',
                onTap: () => _showLegal(context, 'Gizlilik Politikası', _privacyText),
              ),
              const Divider(height: 1, color: AppColors.border),
              _LegalItem(
                icon: Icons.description_outlined,
                title: 'Kullanım Şartları',
                onTap: () => _showLegal(context, 'Kullanım Şartları', _termsText),
              ),
              const Divider(height: 1, color: AppColors.border),
              _LegalItem(
                icon: Icons.assignment_outlined,
                title: 'KVKK Aydınlatma Metni',
                onTap: () => _showLegal(context, 'KVKK Aydınlatma Metni', _kvkkText),
              ),
              const Divider(height: 1, color: AppColors.border),
              _LegalItem(
                icon: Icons.check_circle_outline,
                title: 'Açık Rıza Metni',
                onTap: () => _showLegal(context, 'Açık Rıza Metni', _rizetText),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showLegal(BuildContext context, String title, String content) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bg2,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (_, controller) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border2,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(title, style: AppTextStyles.display(18, weight: FontWeight.w700)),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  controller: controller,
                  child: Text(content, style: AppTextStyles.body(13, color: AppColors.muted).copyWith(height: 1.6)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDiger(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('DİĞER', style: AppTextStyles.label(11)),
        const SizedBox(height: 12),
        SurfaceCard(
          padding: EdgeInsets.zero,
          child: _LegalItem(
            icon: Icons.delete_outline,
            title: 'İlerlemeyi Sıfırla',
            titleColor: AppColors.danger,
            onTap: () => _showResetDialog(context),
          ),
        ),
      ],
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bg2,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBR),
        title: Text('İlerlemeyi Sıfırla',
            style: AppTextStyles.display(16, weight: FontWeight.w700, color: AppColors.danger)),
        content: Text(
          'Tüm kelime ilerlemen, harita durumun ve istatistiklerin silinecek. Bu işlem geri alınamaz.',
          style: AppTextStyles.body(13, color: AppColors.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('İptal', style: AppTextStyles.body(14, color: AppColors.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Sıfırla', style: AppTextStyles.body(14, color: AppColors.danger, weight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  static const _privacyText = '''Game of YÖKDİL uygulaması kullanıcı gizliliğine önem verir.

Toplanan Veriler
• Uygulama içi ilerleme verileri (quiz sonuçları, kelime öğrenme durumu)
• Cihaz kimliği (anonim kullanım istatistikleri için)
• Premium üyelik satın alındığında ödeme doğrulama verisi

Verilerin Kullanımı
Toplanan veriler yalnızca uygulamanın işlevselliğini sağlamak amacıyla kullanılır. Üçüncü şahıslarla paylaşılmaz; pazarlama, profilleme veya reklam amaçlı kullanılmaz.

Verilerin Saklanması
Veriler öncelikle cihazınızda yerel olarak saklanır. Firebase entegrasyonu aktif edildiğinde veriler SSL/TLS şifreli bağlantı üzerinden güvenli şekilde cloud ortamında tutulur.

Veri Silme
Ayarlar > İlerlemeyi Sıfırla seçeneğiyle yerel verilerinizi silebilirsiniz. Cloud verilerinin silinmesi için iletişime geçin.

İletişim: mcihan.toker@std.hku.edu.tr''';

  static const _termsText = '''Game of YÖKDİL Kullanım Şartları

1. Kabul
Uygulamayı indirerek veya kullanarak bu şartları kabul etmiş sayılırsınız.

2. Kullanım Amacı
Uygulama kişisel eğitim amaçlı tasarlanmıştır. Ticari amaçlı kullanım, içeriklerin kopyalanması veya dağıtılması yasaktır.

3. Premium Üyelik
Premium planlar abonelik veya tek seferlik ödeme modeliyle sunulur. Satın alımlar App Store / Google Play üzerinden gerçekleşir. İade koşulları ilgili mağazanın politikasına tabidir.

4. İçerik
Soru ve kelimeler eğitim amaçlı hazırlanmıştır. YÖKDİL sınavında başarı garanti edilmez.

5. Sorumluluk Sınırı
Uygulama "olduğu gibi" sunulmaktadır. Hizmet kesintilerinden, veri kayıplarından veya cihaz uyumsuzluklarından doğan zararlardan sorumluluk kabul edilmez.

6. Değişiklikler
Bu şartlar önceden bildirim yapılmaksızın güncellenebilir. Güncel şartlar uygulama içinde yayımlanır.

İletişim: mcihan.toker@std.hku.edu.tr''';

  static const _kvkkText = '''KİŞİSEL VERİLERİN KORUNMASI KANUNU (KVKK)
Aydınlatma Metni — 6698 sayılı Kanun Madde 10

Veri Sorumlusu
Game of YÖKDİL (mcihan.toker@std.hku.edu.tr)

İşlenen Kişisel Veriler
• Uygulama kullanım verileri (anonim)
• Premium üyelik satın alımında ödeme kimlik doğrulama verisi
• İletişim talebi durumunda e-posta adresi

İşleme Amaçları
• Hizmetin sunulması ve sürdürülmesi
• Kullanıcı deneyiminin iyileştirilmesi
• Yasal yükümlülüklerin yerine getirilmesi

Hukuki Dayanak
• Madde 5/2(c) — sözleşmenin kurulması ve ifası
• Madde 5/2(f) — meşru menfaat

Aktarım
Kişisel veriler üçüncü ülkelere ya da üçüncü kişilere aktarılmaz. Firebase kullanılması durumunda veri işleme sözleşmesi mevcuttur.

KVKK Madde 11 Kapsamındaki Haklarınız
• Kişisel verilerinizin işlenip işlenmediğini öğrenme
• İşleniyorsa buna ilişkin bilgi talep etme
• Verilerin düzeltilmesini isteme
• Silinmesini ya da yok edilmesini talep etme
• İşlemeye itiraz etme
• Zararın giderilmesini talep etme

Başvuru: mcihan.toker@std.hku.edu.tr''';

  static const _rizetText = '''AÇIK RIZA METNİ

Game of YÖKDİL uygulamasını kullanmaya devam ederek aşağıdaki konularda özgür iradenizle açık rıza vermiş sayılırsınız:

1. Kullanım İstatistikleri
Anonim kullanım verilerinizin uygulama kalitesini artırmak amacıyla işlenmesine rıza gösteriyorsunuz.

2. Yerel Veri Saklama
Kelime ilerlemeniz, harita durumunuz ve oyun istatistiklerinizin cihazınızda saklanmasına izin veriyorsunuz.

3. Cloud Senkronizasyon (Opsiyonel)
Firebase entegrasyonu aktif edildiğinde verilerinizin şifreli şekilde bulut ortamında saklanmasına onay veriyorsunuz.

4. Premium Satın Alım
Premium plan satın almanız halinde ödeme doğrulama verisinin App Store / Google Play aracılığıyla işlenmesine rıza gösteriyorsunuz.

Rızanızı Geri Alma
İstediğiniz zaman mcihan.toker@std.hku.edu.tr adresine yazarak rızanızı geri alabilirsiniz. Rızanızı geri almanız geçmişte gerçekleştirilen işlemlerin hukuki geçerliliğini etkilemez.

Bu metni kabul etmek istemiyorsanız uygulamayı kullanmayı bırakabilirsiniz.''';
}

// ─── Stat Kartı ───────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String emoji;

  const _StatCard({required this.label, required this.value, required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.bg3,
          borderRadius: AppRadius.mdBR,
          border: Border.all(color: AppColors.border2),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 6),
            Text(value, style: AppTextStyles.mono(16, weight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(label, style: AppTextStyles.body(10, color: AppColors.muted)),
          ],
        ),
      ),
    );
  }
}

// ─── Premium Plan Kartı ───────────────────────────────────────────────────────
class _PremiumCard extends StatelessWidget {
  final String title;
  final String price;
  final String period;
  final List<String> features;
  final bool isHighlighted;
  final String? badge;
  final VoidCallback onTap;

  const _PremiumCard({
    required this.title,
    required this.price,
    required this.period,
    required this.features,
    required this.isHighlighted,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isHighlighted ? AppColors.sosyal : AppColors.border2;
    final bgColor = isHighlighted
        ? AppColors.sosyal.withValues(alpha: 0.06)
        : AppColors.bg3;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: AppRadius.lgBR,
          border: Border.all(color: borderColor, width: isHighlighted ? 1.5 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(title, style: AppTextStyles.display(15, weight: FontWeight.w600)),
                const Spacer(),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.sosyal.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(badge!, style: AppTextStyles.mono(10, color: AppColors.sosyal, weight: FontWeight.w700)),
                  ),
                if (badge == null)
                  RichText(
                    text: TextSpan(children: [
                      TextSpan(text: price, style: AppTextStyles.display(18, weight: FontWeight.w700)),
                      TextSpan(text: period, style: AppTextStyles.body(12, color: AppColors.muted)),
                    ]),
                  ),
              ],
            ),
            if (badge != null) ...[
              const SizedBox(height: 4),
              RichText(
                text: TextSpan(children: [
                  TextSpan(text: price, style: AppTextStyles.display(20, weight: FontWeight.w700, color: AppColors.sosyal)),
                  TextSpan(text: period, style: AppTextStyles.body(12, color: AppColors.muted)),
                ]),
              ),
            ],
            const SizedBox(height: 10),
            ...features.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(Icons.check_rounded, size: 14,
                      color: isHighlighted ? AppColors.sosyal : AppColors.fen),
                  const SizedBox(width: 6),
                  Text(f, style: AppTextStyles.body(12, color: AppColors.dim)),
                ],
              ),
            )),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isHighlighted ? AppColors.sosyal : AppColors.bg2,
                  foregroundColor: isHighlighted ? Colors.black : AppColors.text,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.smBR),
                ),
                child: Text('Satın Al', style: AppTextStyles.display(13, weight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Yasal Metin Satırı ───────────────────────────────────────────────────────
class _LegalItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color? titleColor;
  final VoidCallback onTap;

  const _LegalItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = titleColor ?? AppColors.text;
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.mdBR,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 18, color: titleColor ?? AppColors.muted),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: AppTextStyles.body(14, color: color))),
            Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.dim),
          ],
        ),
      ),
    );
  }
}
