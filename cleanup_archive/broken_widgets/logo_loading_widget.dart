import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LogoLoadingWidget extends StatelessWidget {
  const LogoLoadingWidget({
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return Container(); // TODO: Implement widget
  }

} 
  final double? size;
  final Color? backgroundColor;
  final bool showBackground;
  final EdgeInsets? padding;

  const LogoLoadingWidget({
    
    super.key,
    this.size,
    this.backgroundColor,
    this.showBackground = false,
    this.padding,
  
  });

  @override
  Widget build(BuildContext context) {
    return Container(); // TODO: Implement widget
  }

  @override
  Widget build(BuildContext context) {
    final logoSize = size ?? 50.0;
    final defaultPadding = padding ?? const EdgeInsets.all(8.0);

    Widget logoWidget = Container(
      width: logoSize,
      height: logoSize,
      padding: defaultPadding,
      decoration: showBackground
          ? BoxDecoration(
              color: backgroundColor ?? Theme.of(context).cardColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            )
          : null,
      child: SvgPicture.asset(
        'assets/images/logo.svg',
        width: logoSize * 0.7,
        height: logoSize * 0.7,
        fit: BoxFit.contain,
      ),
    );

    return Center(child: logoWidget);
  }
}

// Small version for inline loading
class SmallLogoLoadingWidget extends StatelessWidget {
  const SmallLogoLoadingWidget({
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return Container(); // TODO: Implement widget
  }

} 
  const SmallLogoLoadingWidget({
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return Container(); // TODO: Implement widget
  }

  @override
  Widget build(BuildContext context) {
    return const LogoLoadingWidget(
      size: 24,
      padding: EdgeInsets.all(4.0),
    );
  }
}

// Medium version for cards/modals
class MediumLogoLoadingWidget extends StatelessWidget {
  const MediumLogoLoadingWidget({
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return Container(); // TODO: Implement widget
  }

} 
  const MediumLogoLoadingWidget({
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return Container(); // TODO: Implement widget
  }

  @override
  Widget build(BuildContext context) {
    return const LogoLoadingWidget(
      size: 40,
      showBackground: true,
    );
  }
}

// Large version for main loading screens
class LargeLogoLoadingWidget extends StatelessWidget {
  const LargeLogoLoadingWidget({
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return Container(); // TODO: Implement widget
  }

} 
  const LargeLogoLoadingWidget({
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return Container(); // TODO: Implement widget
  }

  @override
  Widget build(BuildContext context) {
    return const LogoLoadingWidget(
      size: 80,
      showBackground: true,
    );
  }
}