import 'package:dierb_core/dierb_core.dart';
import 'package:flutter/material.dart';
import 'app_config.dart';

class DierbHomePage extends StatelessWidget {
  const DierbHomePage({super.key});

  static final categories = LaunchCategoryDefaults.values
      .where((category) => category.featured && category.active)
      .toList(growable: false);

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppConfig.backgroundColor,
      child: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _Header()),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 14),
              sliver: SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppConfig.borderColor),
                    boxShadow: const [BoxShadow(color: Color(0x0D172033), blurRadius: 20, offset: Offset(0, 8))],
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'بتدور على إيه في ديرب؟',
                      hintStyle: const TextStyle(color: AppConfig.textSecondary, fontWeight: FontWeight.w600),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppConfig.brandColor),
                      suffixIcon: Container(
                        margin: const EdgeInsets.all(7),
                        decoration: BoxDecoration(color: AppConfig.brandColorSoft, borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.tune_rounded, color: AppConfig.brandColor),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: _OfferBanner()),
            SliverToBoxAdapter(child: _SectionTitle(title: 'كل احتياجاتك', action: 'عرض الكل')),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, mainAxisExtent: 108, crossAxisSpacing: 10, mainAxisSpacing: 10),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return Column(children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: _categoryColor(index),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: const [BoxShadow(color: Color(0x10172033), blurRadius: 12, offset: Offset(0, 5))],
                      ),
                      child: Icon(_categoryIcon(category.icon), color: AppConfig.brandColor, size: 28),
                    ),
                    const SizedBox(height: 8),
                    Text(category.nameAr, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppConfig.textPrimary, fontWeight: FontWeight.w800)),
                  ]);
                },
              ),
            ),
            SliverToBoxAdapter(child: _SectionTitle(title: 'عروض النهارده', action: 'المزيد')),
            const SliverToBoxAdapter(child: _HorizontalCards()),
            SliverToBoxAdapter(child: _SectionTitle(title: 'اسأل أهل ديرب', action: 'كل الأسئلة')),
            const SliverToBoxAdapter(child: _CommunityCard()),
            SliverToBoxAdapter(child: _SectionTitle(title: 'محلات قريبة منك', action: 'عرض الكل')),
            const SliverToBoxAdapter(child: _StoreCard()),
            const SliverToBoxAdapter(child: SizedBox(height: 28)),
          ],
        ),
      ),
    );
  }

  static Color _categoryColor(int index) {
    const colors = <Color>[
      Color(0xFFF4EDE4), Color(0xFFEAF4F0), Color(0xFFEAF1F8), Color(0xFFF8F1E6),
      Color(0xFFF0ECF7), Color(0xFFF7ECEE), Color(0xFFEAF5F8), Color(0xFFF0F3F6),
    ];
    return colors[index % colors.length];
  }

  static IconData _categoryIcon(String icon) {
    const icons = <String, IconData>{
      'restaurant': Icons.restaurant_rounded,
      'shopping_basket': Icons.shopping_basket_rounded,
      'local_pharmacy': Icons.local_pharmacy_rounded,
      'handyman': Icons.handyman_rounded,
      'apartment': Icons.apartment_rounded,
      'work': Icons.work_rounded,
      'smartphone': Icons.smartphone_rounded,
      'location_city': Icons.location_city_rounded,
    };
    return icons[icon] ?? Icons.category_rounded;
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [AppConfig.brandColor, AppConfig.secondaryColor]),
              borderRadius: BorderRadius.circular(17),
              boxShadow: const [BoxShadow(color: Color(0x25123A63), blurRadius: 18, offset: Offset(0, 7))],
            ),
            child: const Center(child: Text('د', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('أهلاً بيك في ديرب', style: TextStyle(fontSize: 19, color: AppConfig.textPrimary, fontWeight: FontWeight.w900)),
            const SizedBox(height: 3),
            Row(children: [const Icon(Icons.location_on_rounded, size: 15, color: AppConfig.accentColor), const SizedBox(width: 3), Text(LaunchLocationDefaults.city.nameAr, style: const TextStyle(color: AppConfig.textSecondary, fontWeight: FontWeight.w700))]),
          ])),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: AppConfig.borderColor)),
            child: const Icon(Icons.location_city_rounded, color: AppConfig.brandColor),
          ),
        ]),
      );
}

class _OfferBanner extends StatelessWidget {
  const _OfferBanner();
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [Color(0xFF0F2F50), Color(0xFF1D527E)]),
          borderRadius: BorderRadius.circular(26),
          boxShadow: const [BoxShadow(color: Color(0x32123A63), blurRadius: 26, offset: Offset(0, 12))],
        ),
        child: Row(children: [
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('ديرب كلها في إيدك', style: TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w900)),
            SizedBox(height: 8),
            Text('محلات، طلبات، خدمات وأهل بلدك في تجربة واحدة', style: TextStyle(color: Color(0xFFDCE8F3), height: 1.45, fontWeight: FontWeight.w600)),
            SizedBox(height: 14),
            _PremiumPill(),
          ])),
          const SizedBox(width: 12),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(color: const Color(0x18FFFFFF), borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0x33FFFFFF))),
            child: const Icon(Icons.storefront_rounded, color: AppConfig.accentColor, size: 40),
          ),
        ]),
      );
}

class _PremiumPill extends StatelessWidget {
  const _PremiumPill();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(color: const Color(0x1AFFFFFF), borderRadius: BorderRadius.circular(999), border: Border.all(color: const Color(0x33FFFFFF))),
    child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.bolt_rounded, color: AppConfig.accentColor, size: 16), SizedBox(width: 5), Text('كل ديرب • أسرع وأسهل', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800))]),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.action});
  final String title;
  final String action;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 25, 16, 12),
        child: Row(children: [
          Expanded(child: Text(title, style: const TextStyle(fontSize: 19, color: AppConfig.textPrimary, fontWeight: FontWeight.w900))),
          Text(action, style: const TextStyle(color: AppConfig.brandColor, fontWeight: FontWeight.w800)),
        ]),
      );
}

class _HorizontalCards extends StatelessWidget {
  const _HorizontalCards();
  @override
  Widget build(BuildContext context) => SizedBox(
        height: 150,
        child: ListView(padding: const EdgeInsets.symmetric(horizontal: 16), scrollDirection: Axis.horizontal, children: const [
          _MiniCard(title: 'عروض البيت', subtitle: 'خصومات يومية من محلات ديرب', icon: Icons.local_offer_rounded, color: Color(0xFFF7EFE4)),
          _MiniCard(title: 'توصيل أسرع', subtitle: 'متاجر قريبة ومفتوحة الآن', icon: Icons.delivery_dining_rounded, color: Color(0xFFEAF4F0)),
          _MiniCard(title: 'خدمات موثوقة', subtitle: 'أهل خبرة قريبين منك', icon: Icons.verified_rounded, color: Color(0xFFEAF1F8)),
        ]),
      );
}

class _MiniCard extends StatelessWidget {
  const _MiniCard({required this.title, required this.subtitle, required this.icon, required this.color});
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        width: 220,
        margin: const EdgeInsetsDirectional.only(end: 12),
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(22), border: Border.all(color: Colors.white), boxShadow: const [BoxShadow(color: Color(0x0D172033), blurRadius: 14, offset: Offset(0, 6))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 42, height: 42, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: AppConfig.brandColor, size: 24)),
          const Spacer(),
          Text(title, style: const TextStyle(color: AppConfig.textPrimary, fontSize: 15, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: AppConfig.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      );
}

class _CommunityCard extends StatelessWidget {
  const _CommunityCard();
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: AppConfig.borderColor), boxShadow: const [BoxShadow(color: Color(0x0B172033), blurRadius: 18, offset: Offset(0, 8))]),
        child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [CircleAvatar(backgroundColor: AppConfig.brandColorSoft, child: Icon(Icons.person_rounded, color: AppConfig.brandColor)), SizedBox(width: 10), Expanded(child: Text('من أهل ديرب', style: TextStyle(color: AppConfig.textPrimary, fontWeight: FontWeight.w900))), Icon(Icons.verified_rounded, color: AppConfig.brandColor, size: 19)]),
          SizedBox(height: 14),
          Text('محتاج كهربائي شاطر يكون متاح النهارده، مين يرشح حد؟', style: TextStyle(fontSize: 16, color: AppConfig.textPrimary, height: 1.55, fontWeight: FontWeight.w700)),
          SizedBox(height: 14),
          Row(children: [Icon(Icons.thumb_up_alt_outlined, size: 19, color: AppConfig.textSecondary), SizedBox(width: 5), Text('12 مفيد', style: TextStyle(color: AppConfig.textSecondary)), SizedBox(width: 20), Icon(Icons.chat_bubble_outline_rounded, size: 19, color: AppConfig.textSecondary), SizedBox(width: 5), Text('8 ردود', style: TextStyle(color: AppConfig.textSecondary))]),
        ]),
      );
}

class _StoreCard extends StatelessWidget {
  const _StoreCard();
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: AppConfig.borderColor), boxShadow: const [BoxShadow(color: Color(0x0B172033), blurRadius: 18, offset: Offset(0, 8))]),
        child: const Row(children: [
          CircleAvatar(radius: 31, backgroundColor: AppConfig.brandColorSoft, child: Icon(Icons.store_rounded, color: AppConfig.brandColor, size: 30)),
          SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('متاجر ديرب المميزة', style: TextStyle(color: AppConfig.textPrimary, fontWeight: FontWeight.w900, fontSize: 16)), SizedBox(height: 5), Text('قريب منك • مفتوح الآن', style: TextStyle(color: AppConfig.textSecondary, fontWeight: FontWeight.w600)), SizedBox(height: 5), Row(children: [Icon(Icons.star_rounded, color: AppConfig.accentColor, size: 18), Text(' 4.8', style: TextStyle(fontWeight: FontWeight.w800))])])),
          Icon(Icons.arrow_back_ios_new_rounded, color: AppConfig.brandColor, size: 18),
        ]),
      );
}
