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
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _Header()),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            sliver: SliverToBoxAdapter(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'بتدور على إيه في ديرب؟',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: const Icon(Icons.tune_rounded),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: _OfferBanner()),
          SliverToBoxAdapter(child: _SectionTitle(title: 'كل احتياجاتك', action: 'عرض الكل')),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisExtent: 104,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return Column(
                  children: [
                    Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(color: _categoryColor(index), borderRadius: BorderRadius.circular(20)),
                      child: Icon(_categoryIcon(category.icon), color: const Color(0xFF1F2937)),
                    ),
                    const SizedBox(height: 7),
                    Text(category.nameAr, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  ],
                );
              },
            ),
          ),
          SliverToBoxAdapter(child: _SectionTitle(title: 'عروض النهارده', action: 'المزيد')),
          const SliverToBoxAdapter(child: _HorizontalCards()),
          SliverToBoxAdapter(child: _SectionTitle(title: 'اسأل أهل ديرب', action: 'كل الأسئلة')),
          const SliverToBoxAdapter(child: _CommunityCard()),
          SliverToBoxAdapter(child: _SectionTitle(title: 'محلات قريبة منك', action: 'عرض الخريطة')),
          const SliverToBoxAdapter(child: _StoreCard()),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  static Color _categoryColor(int index) {
    const colors = <Color>[
      Color(0xFFFFE8D6), Color(0xFFE0F2E9), Color(0xFFE6EEFF), Color(0xFFFFF2C7),
      Color(0xFFEDE4FF), Color(0xFFFFE5E9), Color(0xFFE1F5FE), Color(0xFFE8ECEF),
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
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: AppConfig.brandColor, borderRadius: BorderRadius.circular(16)),
              child: const Center(child: Text('د', style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w900))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('أهلاً بيك في ديرب', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                Row(children: [const Icon(Icons.location_on_rounded, size: 15, color: AppConfig.brandColor), const SizedBox(width: 4), Text(LaunchLocationDefaults.city.nameAr)]),
              ]),
            ),
            IconButton.filledTonal(onPressed: () {}, icon: const Icon(Icons.notifications_none_rounded)),
          ],
        ),
      );
}

class _OfferBanner extends StatelessWidget {
  const _OfferBanner();
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF14532D), Color(0xFF22A060)]),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('ديرب كلها في إيدك', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
            SizedBox(height: 7),
            Text('طلبات، محلات، خدمات وأهل بلدك في مكان واحد', style: TextStyle(color: Color(0xFFE4F7EC), height: 1.4)),
          ])),
          SizedBox(width: 12),
          Icon(Icons.storefront_rounded, color: Color(0xFFFFD166), size: 64),
        ]),
      );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.action});
  final String title;
  final String action;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
        child: Row(children: [
          Expanded(child: Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900))),
          Text(action, style: const TextStyle(color: AppConfig.brandColor, fontWeight: FontWeight.w700)),
        ]),
      );
}

class _HorizontalCards extends StatelessWidget {
  const _HorizontalCards();
  @override
  Widget build(BuildContext context) => SizedBox(
        height: 145,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          children: const [
            _MiniCard(title: 'خصم على طلبات البيت', subtitle: 'عروض محلات منطقتك', icon: Icons.local_offer_rounded, color: Color(0xFFFFE4D6)),
            _MiniCard(title: 'توصيل أسرع', subtitle: 'متاجر قريبة ومفتوحة', icon: Icons.delivery_dining_rounded, color: Color(0xFFDDF6E8)),
            _MiniCard(title: 'خدمات موثوقة', subtitle: 'اختار صنايعي قريب', icon: Icons.verified_rounded, color: Color(0xFFE4EAFF)),
          ],
        ),
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
        width: 210,
        margin: const EdgeInsetsDirectional.only(end: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(22)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 32), const Spacer(), Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 4), Text(subtitle, style: const TextStyle(fontSize: 12)),
        ]),
      );
}

class _CommunityCard extends StatelessWidget {
  const _CommunityCard();
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
        child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [CircleAvatar(child: Icon(Icons.person_rounded)), SizedBox(width: 10), Expanded(child: Text('محمود • ديرب نجم', style: TextStyle(fontWeight: FontWeight.w800))), Icon(Icons.verified_rounded, color: AppConfig.brandColor, size: 19)]),
          SizedBox(height: 14), Text('محتاج كهربائي شاطر يكون متاح النهارده، مين يرشح حد؟', style: TextStyle(fontSize: 16, height: 1.55, fontWeight: FontWeight.w700)),
          SizedBox(height: 14), Row(children: [Icon(Icons.thumb_up_alt_outlined, size: 19), SizedBox(width: 5), Text('12 مفيد'), SizedBox(width: 20), Icon(Icons.chat_bubble_outline_rounded, size: 19), SizedBox(width: 5), Text('8 ردود')]),
        ]),
      );
}

class _StoreCard extends StatelessWidget {
  const _StoreCard();
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
        child: const Row(children: [
          CircleAvatar(radius: 30, backgroundColor: Color(0xFFE0F2E9), child: Icon(Icons.store_rounded, color: AppConfig.brandColor, size: 30)),
          SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('متاجر ديرب المميزة', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)), SizedBox(height: 5), Text('قريب منك • مفتوح الآن'), SizedBox(height: 5), Row(children: [Icon(Icons.star_rounded, color: AppConfig.accentColor, size: 18), Text(' 4.8')])])),
          Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        ]),
      );
}
