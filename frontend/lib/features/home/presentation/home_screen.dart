import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/veyl_logo.dart';
import '../../../core/widgets/ambient_background.dart';
import '../../../core/widgets/premium_button.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: AmbientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 48.0),
            child: Column(
              children: [
                // Top branding gap
                const Spacer(flex: 2),

                // Interactive Animated Veyl Logo
                const VeylLogoWidget(size: 140.0),
                const SizedBox(height: 24),

                // VEYL Title
                Text(
                  'VEYL',
                  style: theme.textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 4.0,
                    color: isDark ? Colors.white : theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),

                // Tagline / Subtitle
                Text(
                  'Privacy in every connection.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: isDark ? Colors.white70 : Colors.grey[600],
                    letterSpacing: -0.2,
                  ),
                ),

                const Spacer(flex: 3),

                // Sleek, minimal line spacer
                Container(
                  width: 48,
                  height: 1,
                  color: theme.dividerColor.withOpacity(0.5),
                ),
                const SizedBox(height: 32),

                // Spring-animated "Continue" Button
                PremiumButton(
                  onPressed: () => context.go('/chats'),
                  backgroundColor: isDark ? Colors.white : theme.colorScheme.primary,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  child: const Text('Continue'),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
