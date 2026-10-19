class JerseyTeamPreset {
  const JerseyTeamPreset({
    required this.teamName,
    required this.gameCode,
    this.badgeEmoji,
  });

  final String teamName;
  final String gameCode;
  final String? badgeEmoji;

  String get displayName =>
      badgeEmoji != null ? '$badgeEmoji $teamName' : teamName;
}

class JerseyCategoryPreset {
  const JerseyCategoryPreset({
    required this.id,
    required this.name,
    required this.icon,
    required this.teams,
  });

  final String id;
  final String name;
  final String icon;
  final List<JerseyTeamPreset> teams;

  String get displayName => '$icon $name';
}

/// Official game jersey file naming presets.
/// The game engine requires exact file names in the jersey directory
/// to recognize and display custom user-made jerseys.
class JerseyPresetService {
  static const List<JerseyCategoryPreset> categories = [
    // ── 1. INTERNATIONAL ──────────────────────────────────────
    JerseyCategoryPreset(
      id: 'international',
      name: 'International',
      icon: '🌍',
      teams: [
        JerseyTeamPreset(teamName: 'Pakistan', gameCode: 'pak24', badgeEmoji: '🇵🇰'),
        JerseyTeamPreset(teamName: 'India', gameCode: 'ind24', badgeEmoji: '🇮🇳'),
        JerseyTeamPreset(teamName: 'Australia', gameCode: 'aus24', badgeEmoji: '🇦🇺'),
        JerseyTeamPreset(teamName: 'England', gameCode: 'eng24', badgeEmoji: '🏴󠁧󠁢󠁥󠁮󠁧󠁿'),
        JerseyTeamPreset(teamName: 'South Africa', gameCode: 'africa24', badgeEmoji: '🇿🇦'),
        JerseyTeamPreset(teamName: 'New Zealand', gameCode: 'nzl24', badgeEmoji: '🇳🇿'),
        JerseyTeamPreset(teamName: 'West Indies', gameCode: 'wind24', badgeEmoji: '🌴'),
        JerseyTeamPreset(teamName: 'Sri Lanka', gameCode: 'lanka24', badgeEmoji: '🇱🇰'),
        JerseyTeamPreset(teamName: 'Bangladesh', gameCode: 'bang24', badgeEmoji: '🇧🇩'),
        JerseyTeamPreset(teamName: 'Afghanistan', gameCode: 'afg24', badgeEmoji: '🇦🇫'),
        JerseyTeamPreset(teamName: 'Ireland', gameCode: 'ire24', badgeEmoji: '☘️'),
        JerseyTeamPreset(teamName: 'Nepal', gameCode: 'nep24', badgeEmoji: '🇳🇵'),
        JerseyTeamPreset(teamName: 'Netherlands', gameCode: 'ned24', badgeEmoji: '🇳🇱'),
        JerseyTeamPreset(teamName: 'Oman', gameCode: 'oman24', badgeEmoji: '🇴🇲'),
      ],
    ),

    // ── 2. PAKISTAN LEAGUE ────────────────────────────────────
    JerseyCategoryPreset(
      id: 'psl',
      name: 'Pakistan League',
      icon: '🏆',
      teams: [
        JerseyTeamPreset(teamName: 'Rawalpindi', gameCode: 'pindiz24', badgeEmoji: '⚡'),
        JerseyTeamPreset(teamName: 'Quetta', gameCode: 'quetta24', badgeEmoji: '⚔️'),
        JerseyTeamPreset(teamName: 'Islamabad', gameCode: 'unite24', badgeEmoji: '🦁'),
        JerseyTeamPreset(teamName: 'Peshawar', gameCode: 'zalmi24', badgeEmoji: '💛'),
        JerseyTeamPreset(teamName: 'Lahore', gameCode: 'lhr24', badgeEmoji: '🔴'),
        JerseyTeamPreset(teamName: 'Karachi', gameCode: 'kkg24', badgeEmoji: '👑'),
        JerseyTeamPreset(teamName: 'Hyderabad', gameCode: 'hhk24', badgeEmoji: '🦅'),
      ],
    ),

    // ── 3. INDIAN LEAGUE ──────────────────────────────────────
    JerseyCategoryPreset(
      id: 'ipl',
      name: 'Indian League',
      icon: '🏏',
      teams: [
        JerseyTeamPreset(teamName: 'Rajasthan', gameCode: 'rr24', badgeEmoji: '👑'),
        JerseyTeamPreset(teamName: 'Bangalore (RCB)', gameCode: 'rcb24', badgeEmoji: '❤️'),
        JerseyTeamPreset(teamName: 'Chennai (CSK)', gameCode: 'csk24', badgeEmoji: '💛'),
        JerseyTeamPreset(teamName: 'Delhi', gameCode: 'delhi24', badgeEmoji: '🔵'),
        JerseyTeamPreset(teamName: 'Punjab', gameCode: 'kxip24', badgeEmoji: '🦁'),
        JerseyTeamPreset(teamName: 'Lucknow (LSG)', gameCode: 'lsg24', badgeEmoji: '🩵'),
        JerseyTeamPreset(teamName: 'Mumbai', gameCode: 'mumbai24', badgeEmoji: '💙'),
        JerseyTeamPreset(teamName: 'Hyderabad (SRH)', gameCode: 'srh24', badgeEmoji: '🧡'),
        JerseyTeamPreset(teamName: 'Gujarat Titans', gameCode: 'titans24', badgeEmoji: '⚡'),
        JerseyTeamPreset(teamName: 'Kolkata (KKR)', gameCode: 'kkr24', badgeEmoji: '💜'),
      ],
    ),

    // ── 4. TEST MATCH ─────────────────────────────────────────
    JerseyCategoryPreset(
      id: 'test',
      name: 'Test Match',
      icon: '⚪',
      teams: [
        JerseyTeamPreset(teamName: 'Pakistan Test', gameCode: 'pak24_t', badgeEmoji: '🇵🇰'),
        JerseyTeamPreset(teamName: 'India Test', gameCode: 'ind24_t', badgeEmoji: '🇮🇳'),
        JerseyTeamPreset(teamName: 'Australia Test', gameCode: 'aus24_t', badgeEmoji: '🇦🇺'),
        JerseyTeamPreset(teamName: 'England Test', gameCode: 'eng24_t', badgeEmoji: '🏴󠁧󠁢󠁥󠁮󠁧󠁿'),
        JerseyTeamPreset(teamName: 'South Africa Test', gameCode: 'africa24_t', badgeEmoji: '🇿🇦'),
        JerseyTeamPreset(teamName: 'New Zealand Test', gameCode: 'nzl24_t', badgeEmoji: '🇳🇿'),
        JerseyTeamPreset(teamName: 'West Indies Test', gameCode: 'wind24_t', badgeEmoji: '🌴'),
        JerseyTeamPreset(teamName: 'Sri Lanka Test', gameCode: 'lanka24_t', badgeEmoji: '🇱🇰'),
        JerseyTeamPreset(teamName: 'Bangladesh Test', gameCode: 'bang24_t', badgeEmoji: '🇧🇩'),
        JerseyTeamPreset(teamName: 'Afghanistan Test', gameCode: 'afg24_t', badgeEmoji: '🇦🇫'),
        JerseyTeamPreset(teamName: 'Ireland Test', gameCode: 'ire24_t', badgeEmoji: '☘️'),
        JerseyTeamPreset(teamName: 'Nepal Test', gameCode: 'nep24_t', badgeEmoji: '🇳🇵'),
        JerseyTeamPreset(teamName: 'Netherlands Test', gameCode: 'ned24_t', badgeEmoji: '🇳🇱'),
        JerseyTeamPreset(teamName: 'Oman Test', gameCode: 'oman24_t', badgeEmoji: '🇴🇲'),
      ],
    ),
  ];
}
