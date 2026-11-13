import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:squiggle_flutter/preferences/widgets/preference_row.dart';
import 'package:squiggle_flutter/preferences/widgets/preferences_section.dart';

/// The app's name and version, closing out the preferences dialog.
class AboutSection extends StatefulWidget {
  const AboutSection({super.key});

  @override
  State<AboutSection> createState() => _AboutSectionState();
}

class _AboutSectionState extends State<AboutSection> {
  final _packageInfo = PackageInfo.fromPlatform();

  @override
  Widget build(BuildContext context) {
    return PreferencesSection(
      title: 'About',
      children: [
        FutureBuilder(
          future: _packageInfo,
          builder: (context, snapshot) => PreferenceRow(
            icon: Icons.gesture_rounded,
            title: 'Squiggle',
            description: switch (snapshot.data) {
              final info? => 'Version ${info.version}+${info.buildNumber}',
              null => null,
            },
          ),
        ),
      ],
    );
  }
}
