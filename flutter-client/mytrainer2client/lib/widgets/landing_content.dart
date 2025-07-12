import 'package:flutter/material.dart';
import 'package:mytrainer2client/l10n/app_localizations.dart';

class LandingContent extends StatelessWidget {
  /// Called when the user taps the Sign In / Sign Up button.
  final VoidCallback onSignIn;

  const LandingContent({super.key, required this.onSignIn});

  @override
  Widget build(BuildContext context) {
    // grab the localized strings
    final loc = AppLocalizations.of(context)!;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Brand Title
          Text(
            loc.brandTitle,
            key: const Key('brand-title'),
            semanticsLabel: 'Brand Title',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 60,
                  color: Colors.black,
                ),
          ),

          const SizedBox(height: 16),

          // Tagline
          Text(
            loc.tagline,
            key: const Key('tagline'),
            semanticsLabel: 'Tagline',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.black54,
                ),
          ),

          const SizedBox(height: 24),

          // Description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              loc.description,
              key: const Key('description'),
              semanticsLabel: 'Description',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.black87,
                  ),
            ),
          ),

          const SizedBox(height: 32),

          // Buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                label: 'Sign In Button',
                child: ElevatedButton(
                  onPressed: onSignIn,
                  key: const Key('sign-in-button'),
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.black),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Text(
                      loc.signInButton,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Semantics(
                label: 'Learn More Button',
                child: OutlinedButton(
                  onPressed: null,
                  key: const Key('learn-more-button'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Text(
                      loc.learnMoreButton,
                      style: const TextStyle(color: Colors.black),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
