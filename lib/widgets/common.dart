import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config.dart';
import '../screens/in_app_browser_screen.dart';
import '../theme.dart';
import '../utils/format.dart';

class NetImage extends StatelessWidget {
  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;
  const NetImage(this.url, {super.key, this.fit = BoxFit.cover, this.width, this.height});

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return _placeholder();
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      width: width,
      height: height,
      fadeInDuration: const Duration(milliseconds: 200),
      placeholder: (_, __) => _placeholder(),
      errorWidget: (_, __, ___) => _placeholder(icon: Icons.image_not_supported_outlined),
    );
  }

  Widget _placeholder({IconData icon = Icons.image_outlined}) => Container(
        width: width,
        height: height,
        color: const Color(0xFFF0F2F5),
        alignment: Alignment.center,
        child: Icon(icon, color: const Color(0xFFB8BEC8)),
      );
}

class BrandLogo extends StatelessWidget {
  final double size;
  final bool showText;
  const BrandLogo({super.key, this.size = 34, this.showText = true});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipOval(child: NetImage(AppConfig.logoUrl, width: size, height: size)),
        if (showText) ...[
          const SizedBox(width: 8),
          const Text.rich(
            TextSpan(children: [
              TextSpan(text: 'Brothers', style: TextStyle(color: AppColors.navy)),
              TextSpan(text: ' Teknoloji', style: TextStyle(color: AppColors.blue)),
            ]),
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, letterSpacing: -0.3),
          ),
        ],
      ],
    );
  }
}

class PriceView extends StatelessWidget {
  final double price;
  final double? oldPrice;
  final double size;
  const PriceView({super.key, required this.price, this.oldPrice, this.size = 16});

  @override
  Widget build(BuildContext context) {
    final showOld = oldPrice != null && oldPrice! > price;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showOld)
          Text(
            formatPrice(oldPrice!),
            style: TextStyle(
              fontSize: size * 0.72,
              color: AppColors.muted,
              decoration: TextDecoration.lineThrough,
            ),
          ),
        Text(
          formatPrice(price),
          style: TextStyle(fontSize: size, fontWeight: FontWeight.w800, color: AppColors.navy),
        ),
      ],
    );
  }
}

class RatingView extends StatelessWidget {
  final double rating;
  final int count;
  final double size;
  const RatingView({super.key, required this.rating, required this.count, this.size = 13});

  @override
  Widget build(BuildContext context) {
    if (rating <= 0) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star_rounded, size: size + 3, color: AppColors.star),
        const SizedBox(width: 2),
        Text(rating.toStringAsFixed(1), style: TextStyle(fontSize: size, fontWeight: FontWeight.w700)),
        if (count > 0) Text(' ($count)', style: TextStyle(fontSize: size, color: AppColors.muted)),
      ],
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  const SectionHeader({super.key, required this.title, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 8, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.navy)),
          ),
          if (action != null)
            TextButton(
              onPressed: onAction,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(action!, style: const TextStyle(color: AppColors.blue, fontWeight: FontWeight.w600)),
                const Icon(Icons.chevron_right, color: AppColors.blue, size: 18),
              ]),
            ),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: const BoxDecoration(color: AppColors.greenSoft, shape: BoxShape.circle),
              child: Icon(icon, size: 40, color: AppColors.green),
            ),
            const SizedBox(height: 18),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.navy)),
            const SizedBox(height: 6),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted, height: 1.4)),
            if (actionLabel != null) ...[
              const SizedBox(height: 20),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

class QuantityStepper extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final int max;
  const QuantityStepper({super.key, required this.value, required this.onChanged, this.max = 99});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _btn(Icons.remove, () => onChanged(value - 1)),
          SizedBox(
            width: 30,
            child: Text('$value', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          _btn(Icons.add, value >= max ? null : () => onChanged(value + 1)),
        ],
      ),
    );
  }

  Widget _btn(IconData icon, VoidCallback? onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(padding: const EdgeInsets.all(7), child: Icon(icon, size: 18)),
      );
}

/// Bağlantı açar: site sayfaları ve web adresleri uygulama içinde,
/// telefon / e-posta / WhatsApp / harita bağlantıları ilgili uygulamada açılır.
Future<void> openExternal(BuildContext context, String url, {String? title}) async {
  final uri = Uri.parse(url.startsWith('/') ? '${AppConfig.siteUrl}$url' : url);
  final isWeb = uri.scheme == 'http' || uri.scheme == 'https';
  if (isWeb && !InAppBrowserScreen.isAppLinkUri(uri)) {
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(builder: (_) => InAppBrowserScreen(url: uri.toString(), title: title)),
    );
    return;
  }
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bağlantı açılamadı.')));
  }
}

void showMessage(BuildContext context, String text, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(text),
      behavior: SnackBarBehavior.floating,
      backgroundColor: error ? AppColors.danger : AppColors.navy,
    ));
}
