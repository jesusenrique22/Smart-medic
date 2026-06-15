import 'package:flutter/material.dart';
import '../../navigation/app_navigation.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../promo/promo_carousel.dart';
import '../promo/promo_models.dart';
import '../responsive_scaffold.dart';
import 'experience_header.dart';
import 'fade_slide_in.dart';

/// Shell reutilizable para marketplaces y pantallas de descubrimiento.
class ExperienceMarketplaceShell extends StatelessWidget {
  final String title;
  final String subtitle;
  final String badge;
  final IconData icon;
  final List<Color> gradient;
  final List<PromoOffer> promos;
  final List<Widget> children;
  final bool showBack;
  final Widget? floatingActionButton;

  const ExperienceMarketplaceShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.icon,
    required this.gradient,
    this.promos = const [],
    required this.children,
    this.showBack = true,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      hideAppBar: true,
      backgroundColor: AppColors.background,
      floatingActionButton: floatingActionButton,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {},
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: Stack(
                children: [
                  ExperienceHeader(
                    title: title,
                    subtitle: subtitle,
                    badge: badge,
                    icon: icon,
                    gradient: gradient,
                    actions: showBack
                        ? [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: IconButton(
                                onPressed: () =>
                                    AppNavigation.safeBack(context),
                                icon: const Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ]
                        : null,
                  ),
                ],
              ),
            ),
            if (promos.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.lg),
                  child: PromoCarousel(
                    offers: promos,
                    onOfferTap: (offer) {
                      if (offer.route != null) {
                        Navigator.pushNamed(context, offer.route!);
                      }
                    },
                  ),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => FadeSlideIn(
                    index: index,
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: index < children.length - 1
                            ? AppSpacing.md
                            : 80,
                      ),
                      child: children[index],
                    ),
                  ),
                  childCount: children.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
