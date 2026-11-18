import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const HyruleIndexApp());
}

// ============================================================
// APP
// ============================================================

class HyruleIndexApp extends StatelessWidget {
  const HyruleIndexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hyrule Index',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF24152F),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF54246F),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

// ============================================================
// GAME DATA
// ============================================================

class Game {
  final String id;
  final String title;
  final String platform;

  Game({
    required this.id,
    required this.title,
    required this.platform,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'platform': platform,
    };
  }

  factory Game.fromJson(Map<String, dynamic> json) {
    return Game(
      id: json['id'],
      title: json['title'],
      platform: json['platform'],
    );
  }
}

// ============================================================
// HOME SCREEN
// ============================================================

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Game> games = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadGames();
  }

  // Load saved games
  Future<void> loadGames() async {
    final prefs = await SharedPreferences.getInstance();

    final savedGames = prefs.getStringList('games');

    if (savedGames != null) {
      games = savedGames
          .map(
            (game) => Game.fromJson(
          jsonDecode(game),
        ),
      )
          .toList();
    }

    setState(() {
      loading = false;
    });
  }

  // Save games
  Future<void> saveGames() async {
    final prefs = await SharedPreferences.getInstance();

    final encodedGames = games
        .map(
          (game) => jsonEncode(game.toJson()),
    )
        .toList();

    await prefs.setStringList('games', encodedGames);
  }

  // Add a game
  Future<void> addGame(Game game) async {
    setState(() {
      games.add(game);
    });

    await saveGames();
  }

  // Remove a game
  Future<void> removeGame(Game game) async {
    setState(() {
      games.removeWhere(
            (existingGame) => existingGame.id == game.id,
      );
    });

    await saveGames();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/index.png',
              width: 32,
              height: 32,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 10),
            const Text('Hyrule Index'),
          ],
        ),
        backgroundColor: const Color(0xFF24152F),
      ),

      body: games.isEmpty
          ? EmptyGamesState(
        onAddGame: () async {
          final game = await Navigator.push<Game>(
            context,
            MaterialPageRoute(
              builder: (_) => AddGameScreen(
                existingGames: games,
              ),
            ),
          );

          if (game != null) {
            await addGame(game);
          }
        },
      )
          : ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'My Games',
            style: Theme.of(context).textTheme.headlineMedium,
          ),

          const SizedBox(height: 8),

          const Text(
            'Choose a game to continue your adventure.',
            style: TextStyle(
              color: Colors.white70,
            ),
          ),

          const SizedBox(height: 24),

          ...games.map(
                (game) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: GameCard(
                game: game,
                onTap: () async {
                  final prefs = await SharedPreferences.getInstance();

                  final profile =
                      prefs.getInt('selected_profile_${game.id}') ?? 1;

                  if (!context.mounted) return;

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TrackerScreen(
                        game: game,
                        profileNumber: profile,
                      ),
                    ),
                  );
                },                onRemove: () => confirmRemoveGame(game),
              ),
            ),
          ),

          const SizedBox(height: 12),

          OutlinedButton.icon(
            onPressed: () async {
              final game = await Navigator.push<Game>(
                context,
                MaterialPageRoute(
                  builder: (_) => AddGameScreen(
                    existingGames: games,
                  ),
                ),
              );

              if (game != null) {
                await addGame(game);
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Game'),
          ),
        ],
      ),
    );
  }

  Future<void> confirmRemoveGame(Game game) async {
    final remove = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Remove game?'),
          content: Text(
            'Remove ${game.title} from My Games?\n\n'
                'Your profile data will not be permanently deleted.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );

    if (remove == true) {
      await removeGame(game);
    }
  }
}

// ============================================================
// EMPTY HOME SCREEN
// ============================================================

class EmptyGamesState extends StatelessWidget {
  final VoidCallback onAddGame;

  const EmptyGamesState({
    super.key,
    required this.onAddGame,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),

            const SizedBox(height: 20),

            Text(
              'Welcome to Hyrule Index',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),

            const SizedBox(height: 10),

            const Text(
              'Add a Zelda game to start tracking your adventures.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
              ),
            ),

            const SizedBox(height: 28),

            FilledButton.icon(
              onPressed: onAddGame,
              icon: const Icon(Icons.add),
              label: const Text('Add Game'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// ADD GAME
// ============================================================

class AddGameScreen extends StatelessWidget {
  final List<Game> existingGames;

  const AddGameScreen({
    super.key,
    required this.existingGames,
  });

  @override
  Widget build(BuildContext context) {
    final availableGames = [
      Game(
        id: 'majoras_mask',
        title: "Majora's Mask",
        platform: 'Nintendo 64',
      ),
    ];

    final gamesToShow = availableGames.where(
          (game) => !existingGames.any(
            (existing) => existing.id == game.id,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Game'),
        backgroundColor: const Color(0xFF24152F),
      ),

      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Choose a game',
            style: Theme.of(context).textTheme.headlineMedium,
          ),

          const SizedBox(height: 8),

          const Text(
            'Select a Zelda game to add to My Games.',
            style: TextStyle(
              color: Colors.white70,
            ),
          ),

          const SizedBox(height: 24),

          for (final game in gamesToShow)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: GameCard(
                game: game,
                onTap: () {
                  Navigator.pop(context, game);
                },
                onRemove: null,
              ),
            ),

          if (gamesToShow.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(
                child: Text(
                  'More Zelda games will be added in future updates. Check back later for new adventures to add to My Games.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================
// GAME CARD
// ============================================================

class GameCard extends StatelessWidget {
  final Game game;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  const GameCard({
    super.key,
    required this.game,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF2D1C38),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(
          color: Color(0xFF50345D),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFF392546),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Image.asset(
                  'assets/logo.png',
                  width: 48,
                  height: 48,
                  fit: BoxFit.contain,
                ),
              ),

              const SizedBox(width: 18),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),

                    const SizedBox(height: 4),

                    Text(
                      game.platform,
                      style: const TextStyle(
                        color: Colors.white60,
                      ),
                    ),

                  ],
                ),
              ),

              if (onRemove != null)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'remove') {
                      onRemove!();
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'remove',
                      child: Text('Remove from My Games'),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// PROFILE SELECTION
// ============================================================

class ProfileSelectionScreen extends StatelessWidget {
  final Game game;

  const ProfileSelectionScreen({
    super.key,
    required this.game,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(game.title),
        backgroundColor: const Color(0xFF24152F),
      ),

      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Choose a profile',
            style: Theme.of(context).textTheme.headlineMedium,
          ),

          const SizedBox(height: 8),

          const Text(
            'Each profile has its own independent progress.',
            style: TextStyle(
              color: Colors.white70,
            ),
          ),

          const SizedBox(height: 28),

          for (int i = 1; i <= 3; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: ProfileCard(
                gameId: game.id,
                profileNumber: i,
                percentage: 0,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TrackerScreen(
                        game: game,
                        profileNumber: i,
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================
// PROFILE CARD
// ============================================================

class ProfileCard extends StatelessWidget {
  final String gameId;
  final int profileNumber;
  final int percentage;
  final VoidCallback onTap;

  const ProfileCard({
    super.key,
    required this.gameId,
    required this.profileNumber,
    required this.percentage,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF2D1C38),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(
          color: Color(0xFF50345D),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFF392546),
                child: Text(
                  '$profileNumber',
                  style: TextStyle(
                    fontSize: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),

              const SizedBox(width: 18),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Profile $profileNumber',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),

                    const SizedBox(height: 8),

                    LinearProgressIndicator(
                      value: percentage / 100,
                      minHeight: 7,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              Text(
                '$percentage%',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// TRACKER
// ============================================================


class TrackerScreen extends StatefulWidget {
  final Game game;
  final int profileNumber;

  const TrackerScreen({
    super.key,
    required this.game,
    required this.profileNumber,
  });

  @override
  State<TrackerScreen> createState() => _TrackerScreenState();
}

class _TrackerScreenState extends State<TrackerScreen> {
  late int currentProfile;
  bool notebookUnlocked = false;
  String? savedBomberCode;
  int masksCollected = 0;
  int firstThreeDaysCollected = 0;
  int heartPiecesCollected = 0;
  int itemUpgradesCollected = 0;
  int songsCollected = 0;
  int bottlesCollected = 0;
  int bomberKidsCollected = 0;
  int strayFairiesCollected = 0;
  String get notebookUnlockKey =>
      'notebook_unlocked_${widget.game.id}_profile_$currentProfile';

  String get bomberCodeKey =>
      'bomber_code_${widget.game.id}_profile_$currentProfile';
  Future<void> loadNotebookStatus() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      notebookUnlocked = prefs.getBool(notebookUnlockKey) ?? false;
      savedBomberCode = prefs.getString(bomberCodeKey);
    });
  }
  int get overallProgress {
    final completed =
        firstThreeDaysCollected +
            bomberKidsCollected +
            masksCollected +
            heartPiecesCollected +
            itemUpgradesCollected +
            songsCollected +
            bottlesCollected +
            strayFairiesCollected;

    const total = 5 + 5 + 24 + 52 + 6 + 10 + 6 + 60;

    return ((completed / total) * 100).round();
  }
  @override
  void initState() {
    super.initState();
    currentProfile = widget.profileNumber;
    loadNotebookStatus();
    loadMaskProgress();
    loadFirstThreeDaysProgress();
    loadHeartPiecesProgress();
    loadItemUpgradesProgress();
    loadSongsProgress();
    loadBottlesProgress();
    loadBomberKidsProgress();
    loadStrayFairiesProgress();
  }
  Future<void> loadMaskProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'masks_${widget.game.id}_profile_$currentProfile';
    final masks = prefs.getStringList(key) ?? [];

    if (!mounted) return;

    setState(() {
      masksCollected = masks.toSet().length;
    });
  }
  Future<void> loadFirstThreeDaysProgress() async {
    final prefs = await SharedPreferences.getInstance();

    final key =
        'first_three_days_${widget.game.id}_profile_$currentProfile';

    final items = prefs.getStringList(key) ?? [];

    if (!mounted) return;

    setState(() {
      firstThreeDaysCollected = items.toSet().length;
    });
  }
  Future<void> loadHeartPiecesProgress() async {
    final prefs = await SharedPreferences.getInstance();

    final key =
        'heart_pieces_${widget.game.id}_profile_$currentProfile';

    final items = prefs.getStringList(key) ?? [];

    if (!mounted) return;

    setState(() {
      heartPiecesCollected = items.toSet().length;
    });
  }
  Future<void> loadItemUpgradesProgress() async {
    final prefs = await SharedPreferences.getInstance();

    final key =
        'item_upgrades_${widget.game.id}_profile_$currentProfile';

    final items = prefs.getStringList(key) ?? [];

    if (!mounted) return;

    setState(() {
      itemUpgradesCollected = items.toSet().length;
    });
  }
  Future<void> loadSongsProgress() async {
    final prefs = await SharedPreferences.getInstance();

    final key =
        'songs_${widget.game.id}_profile_$currentProfile';

    final collected = prefs.getStringList(key) ?? [];

    if (!mounted) return;

    setState(() {
      songsCollected = collected.toSet().length;
    });
  }
  Future<void> loadBottlesProgress() async {
    final prefs = await SharedPreferences.getInstance();

    final key =
        'bottles_${widget.game.id}_profile_$currentProfile';

    final collected = prefs.getStringList(key) ?? [];

    if (!mounted) return;

    setState(() {
      const validBottles = {
        'Southern Swamp bottle',
        'Goron Race bottle',
        'Romani Ranch bottle',
        'western Ocean bottle',
        'Ikana Graveyard Bottle',
        'Milk Bar Bottle',
      };

      bottlesCollected = collected
          .where((bottle) => validBottles.contains(bottle))
          .toSet()
          .length;
    });
  }
  Future<void> loadStrayFairiesProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final key =
        'stray_fairies_${widget.game.id}_profile_$currentProfile';
    final collected = prefs.getStringList(key) ?? [];

    if (!mounted) return;

    setState(() {
      strayFairiesCollected = collected.toSet().length;
    });
  }
  Future<void> loadBomberKidsProgress() async {
    final prefs = await SharedPreferences.getInstance();

    final key =
        'bomber_kids_${widget.game.id}_profile_$currentProfile';

    final collected = prefs.getStringList(key) ?? [];

    if (!mounted) return;

    setState(() {
      bomberKidsCollected = collected.toSet().length;
    });
  }
  Future<void> switchProfile(int profile) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt(
      'selected_profile_${widget.game.id}',
      profile,
    );

    setState(() {
      currentProfile = profile;
    });

    await loadMaskProgress();
    await loadFirstThreeDaysProgress();
    await loadHeartPiecesProgress();
    await loadItemUpgradesProgress();
    await loadSongsProgress();
    await loadBottlesProgress();
    await loadBomberKidsProgress();
    await loadStrayFairiesProgress();
    await loadNotebookStatus();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF24152F),
        title: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'reset') {
              final shouldReset = await showDialog<bool>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: Text('Reset Profile $currentProfile?'),
                  content: Text(
                    'This will erase all progress saved to Profile '
                        '$currentProfile for this game. This cannot be undone.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () =>
                          Navigator.pop(dialogContext, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () =>
                          Navigator.pop(dialogContext, true),
                      child: const Text('Reset Profile'),
                    ),
                  ],
                ),
              );

              if (shouldReset != true) return;

              final prefs = await SharedPreferences.getInstance();
              final profileSuffix =
                  '_${widget.game.id}_profile_$currentProfile';

              final keysToRemove = prefs
                  .getKeys()
                  .where((key) => key.endsWith(profileSuffix))
                  .toList();

              for (final key in keysToRemove) {
                await prefs.remove(key);
              }

              if (!mounted) return;

              setState(() {
                masksCollected = 0;
                firstThreeDaysCollected = 0;
                heartPiecesCollected = 0;
                itemUpgradesCollected = 0;
                songsCollected = 0;
                bottlesCollected = 0;
                bomberKidsCollected = 0;
                strayFairiesCollected = 0;
                notebookUnlocked = false;
                savedBomberCode = null;
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Profile $currentProfile progress reset.',
                  ),
                ),
              );
            } else {
              await switchProfile(int.parse(value));
            }
          },
          itemBuilder: (context) {
            return [
              for (int profile = 1; profile <= 3; profile++)
                PopupMenuItem<String>(
                  value: '$profile',
                  child: Row(
                    children: [
                      Icon(
                        profile == currentProfile
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                      ),
                      const SizedBox(width: 12),
                      Text('Profile $profile'),
                    ],
                  ),
                ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'reset',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline),
                    SizedBox(width: 12),
                    Text('Reset Current Profile'),
                  ],
                ),
              ),
            ];
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Profile $currentProfile'),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_drop_down),
            ],
          ), // PopupMenuButton
        ), // AppBar
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            widget.game.title,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Profile $currentProfile',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF2D1C38),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF50345D),
              ),
            ),
            child: Column(
              children: [
                Text(
                  'Overall Progress',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Text(
                  '$overallProgress%',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: overallProgress / 100,
                  minHeight: 10,
                ),
                if (notebookUnlocked) ...[
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();

                      final codeKey =
                          'bomber_code_${widget.game.id}_profile_$currentProfile';

                      final bomberCode = prefs.getString(codeKey) ?? '';

                      if (!mounted) return;

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BombersNotebookScreen(
                            game: widget.game,
                            profileNumber: currentProfile,
                            bomberCode: bomberCode,
                          ),
                        ),
                      );
                    },
                    icon: Image.asset(
                      'assets/Checklists/bomber_squad_kids.png',
                      width: 24,
                      height: 24,
                      fit: BoxFit.contain,
                    ),
                    label: const Text("Open Bombers' Notebook"),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          TrackerCategory(
            imageAsset: 'assets/Checklists/first_three_days.png',
            title: 'First Three Days',
            completed: firstThreeDaysCollected,
            total: 5,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FirstThreeDaysScreen(
                    game: widget.game,
                    profileNumber: currentProfile,
                  ),
                ),
              );
              await loadFirstThreeDaysProgress();
            },
          ),
          TrackerCategory(
            imageAsset: 'assets/Checklists/bomber_squad_kids.png',
            title: 'Bomber Squad Kids',
            completed: bomberKidsCollected,
            total: 5,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BomberKidsTrackerScreen(
                    game: widget.game,
                    profileNumber: currentProfile,
                  ),
                ),
              );


              await loadBomberKidsProgress();
              await loadNotebookStatus();
            },
          ),

          TrackerCategory(
            imageAsset: 'assets/Checklists/masks.png',
            title: 'Masks',
            completed: masksCollected,
            total: 24,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MaskTrackerScreen(
                    game: widget.game,
                    profileNumber: currentProfile,
                  ),
                ),
              );

              await loadMaskProgress();
            },
          ),
          TrackerCategory(
            imageAsset: 'assets/Checklists/heart_pieces.png',
            title: 'Heart Pieces',
            completed: heartPiecesCollected,
            total: 52,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HeartPiecesScreen(
                    game: widget.game,
                    profileNumber: currentProfile,
                  ),
                ),
              );

              await loadHeartPiecesProgress();
            },
          ),
          TrackerCategory(
            imageAsset: 'assets/Checklists/item_upgrades.png',
            title: 'Item Upgrades',
            completed: itemUpgradesCollected,
            total: 14,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ItemUpgradesScreen(
                    game: widget.game,
                    profileNumber: currentProfile,
                  ),
                ),
              );

              await loadItemUpgradesProgress();
            },
          ),
          TrackerCategory(
            imageAsset: 'assets/Checklists/songs.png',
            title: 'Songs',
            completed: songsCollected,
            total: 10,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SongsTrackerScreen(
                    game: widget.game,
                    profileNumber: currentProfile,
                  ),
                ),
              );

              await loadSongsProgress();
            },
          ),
          TrackerCategory(
            imageAsset: 'assets/Checklists/bottles.png',
            title: 'Bottles',
            completed: bottlesCollected,
            total: 6,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BottlesTrackerScreen(
                    game: widget.game,
                    profileNumber: currentProfile,
                  ),
                ),
              );

              await loadBottlesProgress();
            },
          ),

          TrackerCategory(
            imageAsset: 'assets/Checklists/stray_fairies.png',
            title: 'Stray Fairies',
            completed: strayFairiesCollected,
            total: 60,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StrayFairiesTrackerScreen(
                    game: widget.game,
                    profileNumber: currentProfile,
                  ),
                ),
              );
              await loadStrayFairiesProgress();
            },
          ),
        ],
      ),
    );
  }
}


// ============================================================
// TRACKER CATEGORY
// ============================================================


class TrackerCategory extends StatelessWidget {
  final String imageAsset;
  final String title;
  final int completed;
  final int total;
  final VoidCallback? onTap;

  const TrackerCategory({
    super.key,
    required this.imageAsset,
    required this.title,
    required this.completed,
    required this.total,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF2D1C38),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 8,
        ),
        leading: Image.asset(
          imageAsset,
          width: 32,
          height: 32,
          fit: BoxFit.contain,
        ),
        title: Text(title),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: LinearProgressIndicator(
            value: total == 0 ? 0 : completed / total,
            minHeight: 5,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        trailing: Text(
          '$completed/$total',
          style: const TextStyle(color: Colors.white70),
        ),
      ),
    );
  }
}


class MaskTrackerScreen extends StatefulWidget {
  final Game game;
  final int profileNumber;

  const MaskTrackerScreen({
    super.key,
    required this.game,
    required this.profileNumber,
  });

  @override
  State<MaskTrackerScreen> createState() =>
      _MaskTrackerScreenState();
}

class _MaskTrackerScreenState extends State<MaskTrackerScreen> {
  final List<String> masks = const [
    'Deku Mask',
    "Great Fairy's Mask",
    "Kafei's Mask",
    'Bremen Mask',
    'Blast Mask',
    'Bunny Hood',
    "Kamaro's Mask",
    'Keaton Mask',
    "Postman's Hat",
    'All-Night Mask',
    'Don Gero Mask',
    'Mask of Scents',
    "Goron's Mask",
    "Romani's Mask",
    "Circus Leader's Mask",
    'Zora Mask',
    'Stone Mask',
    "Captain's Hat",
    "Gibdo's Mask",
    'Garo Mask',
    'Couple Mask',
    'Giant Mask',
    'Mask of Truth',
    'Fierce Deity Mask',
  ];

  final Set<String> collectedMasks = {};
  bool loading = true;

  String get storageKey =>
      'masks_${widget.game.id}_profile_${widget.profileNumber}';

  @override
  void initState() {
    super.initState();
    loadMasks();
  }

  Future<void> loadMasks() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      collectedMasks.addAll(prefs.getStringList(storageKey) ?? []);
      loading = false;
    });
  }

  Future<void> toggleMask(String mask) async {
    setState(() {
      if (collectedMasks.contains(mask)) {
        collectedMasks.remove(mask);
      } else {
        collectedMasks.add(mask);
      }
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(storageKey, collectedMasks.toList());
  }

  @override
  Widget build(BuildContext context) {
    final count = collectedMasks.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Masks'),
        backgroundColor: const Color(0xFF24152F),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Profile ${widget.profileNumber} · $count/${masks.length} collected',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: count / masks.length,
            minHeight: 8,
          ),
          const SizedBox(height: 16),
          for (final mask in masks)
            Card(
              color: const Color(0xFF2D1C38),
              child: CheckboxListTile(
                value: collectedMasks.contains(mask),
                onChanged: (_) => toggleMask(mask),
                title: Text(mask),
                activeColor: Theme.of(context).colorScheme.primary,
              ),
            ),
        ],
      ),
    );
  }
}


class FirstThreeDaysScreen extends StatefulWidget {
  final Game game;
  final int profileNumber;

  const FirstThreeDaysScreen({
    super.key,
    required this.game,
    required this.profileNumber,
  });

  @override
  State<FirstThreeDaysScreen> createState() =>
      _FirstThreeDaysScreenState();
}

class _FirstThreeDaysScreenState
    extends State<FirstThreeDaysScreen> {
  final List<String> items = const [
    'Reach Clock Town',
    'Help the Great Fairy',
    'Hide and Seek With the Bombers!',
    'Obtain The Town Title Deed',
    'Recover the Ocarina of Time',
  ];

  final Set<String> collected = {};
  bool loading = true;

  String get storageKey =>
      'first_three_days_${widget.game.id}_profile_${widget.profileNumber}';

  @override
  void initState() {
    super.initState();
    loadItems();
  }

  Future<void> loadItems() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      collected.addAll(prefs.getStringList(storageKey) ?? []);
      loading = false;
    });
  }

  Future<void> toggleItem(String item) async {
    setState(() {
      if (collected.contains(item)) {
        collected.remove(item);
      } else {
        collected.add(item);
      }
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(storageKey, collected.toList());
  }

  @override
  Widget build(BuildContext context) {
    final count = collected.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('First Three Days'),
        backgroundColor: const Color(0xFF24152F),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Profile ${widget.profileNumber} · $count/${items.length} collected',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: count / items.length,
            minHeight: 8,
          ),
          const SizedBox(height: 16),
          for (final item in items)
            Card(
              color: const Color(0xFF2D1C38),
              child: CheckboxListTile(
                value: collected.contains(item),
                onChanged: (_) => toggleItem(item),
                title: Text(item),
                activeColor:
                Theme.of(context).colorScheme.primary,
              ),
            ),
        ],
      ),
    );
  }
}

class HeartPiecesScreen extends StatefulWidget {
  final Game game;
  final int profileNumber;

  const HeartPiecesScreen({
    super.key,
    required this.game,
    required this.profileNumber,
  });

  @override
  State<HeartPiecesScreen> createState() =>
      _HeartPiecesScreenState();
}

class _HeartPiecesScreenState extends State<HeartPiecesScreen> {
  final Map<String, List<String>> locations = const {
    'Clock Town': [
      'South Clock Town — Clock Tower Balcony',
      'Stock Pot Inn — Restroom',
      'North Clock Town — Deku Scrub Playground',
      'North Clock Town — Tree',
      'West Clock Town — Post Office',
      "West Clock Town — Swordsman's School",
      "East Clock Town — Honey & Darling's Shop",
      'North Clock Town — Keaton Quiz',
      'West Clock Town — Rosa Sisters',
      'Clock Town — Mailbox',
      'East Clock Town — Town Shooting Gallery',
      'East Clock Town — Treasure Chest Shop',
      'South Clock Town — Clock Town Bank',
      "Stock Pot Inn — Anju's Grandmother (Story 1)",
      "Stock Pot Inn — Anju's Grandmother (Story 2)",
      "East Clock Town — Mayor's Residence",
    ],
    'Termina Field': [
      'Outside Astral Observatory — Business Scrub',
      'Hidden Hole near Milk Road',
      'Hidden Hole near North Clock Town',
      'Hidden Hole near West Clock Town',
      'Four Gossip Stone Holes',
    ],
    'Southern Swamp and Woodfall': [
      'Road to Southern Swamp — Tree Top',
      'Southern Swamp — Tourist Center Roof',
      'Southern Swamp — Pictograph Contest',
      'Deku Palace — Palace Gardens Maze',
      'Woodfall — Platform Chest',
      'Southern Swamp — Swamp Shooting Gallery',
      'Southern Swamp — Koume Boat Cruise',
    ],
    'Mountain Village and Snowhead': [
      'Goron Village — Business Scrub',
      'Mountain Village — Twin Islands Underwater Chest',
      'Path to Snowhead Temple — Invisible Platforms',
      'Mountain Village — Frog Choir',
    ],
    'Romani Ranch': [
      "Mamamu Yan's Doggy Racetrack",
    ],
    'Great Bay': [
      'Great Bay Coast — Marine Research Lab Aquarium',
      'Zora Cape — Waterfall Basin Like Like',
      'Zora Hall — Jam Session with Japas',
      "Zora Hall — Lulu's Room Business Scrub",
      "Pirate's Fortress — Sewers Cage",
      'Pinnacle Rock — Rescue Seahorse',
      'Zora Cape — Beaver Race Rematch',
      'Great Bay Coast — Scarecrow Platform',
      'Great Bay — Oceanside Spider House Library',
    ],
    'Ikana Canyon': [
      'Ikana Graveyard — Night 2 Grave',
      'Ikana Canyon — Business Scrub',
      'Ikana Canyon — Spirit House',
      'Ancient Castle of Ikana — Pillar Top',
      'Ikana Canyon — Secret Shrine Behind Waterfall',
      'Ikana Graveyard — Dampé Digging',
    ],
    'The Moon': [
      'Deku Trial',
      'Goron Trial',
      'Zora Trial',
      'Link Trial',
    ],
  };

  final Set<String> collected = {};
  bool loading = true;

  String get storageKey =>
      'heart_pieces_${widget.game.id}_profile_${widget.profileNumber}';

  int get total => locations.values.fold(
    0,
        (sum, items) => sum + items.length,
  );

  @override
  void initState() {
    super.initState();
    loadItems();
  }

  Future<void> loadItems() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      collected.addAll(prefs.getStringList(storageKey) ?? []);
      loading = false;
    });
  }

  Future<void> toggleItem(String item) async {
    setState(() {
      if (collected.contains(item)) {
        collected.remove(item);
      } else {
        collected.add(item);
      }
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(storageKey, collected.toList());
  }

  @override
  Widget build(BuildContext context) {
    final count = collected.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Heart Pieces'),
        backgroundColor: const Color(0xFF24152F),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Profile ${widget.profileNumber} · $count/$total collected',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: total == 0 ? 0 : count / total,
            minHeight: 8,
          ),
          const SizedBox(height: 16),
          for (final location in locations.entries) ...[
            Padding(
              padding: const EdgeInsets.only(
                top: 12,
                bottom: 8,
              ),
              child: Text(
                location.key,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium,
              ),
            ),
            for (final item in location.value)
              Card(
                color: const Color(0xFF2D1C38),
                child: CheckboxListTile(
                  value: collected.contains(item),
                  onChanged: (_) => toggleItem(item),
                  title: Text(item),
                  activeColor:
                  Theme.of(context).colorScheme.primary,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class ItemUpgradesScreen extends StatefulWidget {
  final Game game;
  final int profileNumber;

  const ItemUpgradesScreen({
    super.key,
    required this.game,
    required this.profileNumber,
  });

  @override
  State<ItemUpgradesScreen> createState() =>
      _ItemUpgradesScreenState();
}

class _ItemUpgradesScreenState
    extends State<ItemUpgradesScreen> {
  final List<String> items = const [
    'Razor Sword',
    'Gilded Sword',
    'Great Fairy Sword',
    'Mirror Shield',
    'Large Quiver',
    'Largest Quiver',
    'Bomb Bag',
    'Big Bomb Bag',
    'Biggest Bomb Bag',
    'Adult Wallet',
    'Giant Wallet',
    'Epona',
    'Pictograph Box',
    'Hookshot',
  ];

  final Set<String> collected = {};
  bool loading = true;

  String get storageKey =>
      'item_upgrades_${widget.game.id}_profile_${widget.profileNumber}';

  @override
  void initState() {
    super.initState();
    loadItems();
  }

  Future<void> loadItems() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      collected.addAll(
        prefs.getStringList(storageKey) ?? [],
      );
      loading = false;
    });
  }

  Future<void> toggleItem(String item) async {
    setState(() {
      if (collected.contains(item)) {
        collected.remove(item);
      } else {
        collected.add(item);
      }
    });

    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(
      storageKey,
      collected.toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final count = collected.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Item Upgrades'),
        backgroundColor: const Color(0xFF24152F),
      ),
      body: loading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Profile ${widget.profileNumber} · '
                '$count/${items.length} collected',
            style: Theme.of(context)
                .textTheme
                .titleLarge,
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: count / items.length,
            minHeight: 8,
          ),
          const SizedBox(height: 16),
          for (final item in items)
            Card(
              color: const Color(0xFF2D1C38),
              child: CheckboxListTile(
                value: collected.contains(item),
                onChanged: (_) => toggleItem(item),
                title: Text(item),
                activeColor:
                Theme.of(context).colorScheme.primary,
              ),
            ),
        ],
      ),
    );
  }
}
class SongsTrackerScreen extends StatefulWidget {
  final Game game;
  final int profileNumber;

  const SongsTrackerScreen({
    super.key,
    required this.game,
    required this.profileNumber,
  });

  @override
  State<SongsTrackerScreen> createState() =>
      _SongsTrackerScreenState();
}

class _SongsTrackerScreenState
    extends State<SongsTrackerScreen> {
  final List<String> songs = const [
    'Song of Time',
    'Song of Healing',
    "Epona's Song",
    'Song of Soaring',
    'Song of Storms',
    'Sonata of Awakening',
    'Goron Lullaby',
    'New Wave Bossa Nova',
    'Elegy of Emptiness',
    'Oath to Order',
  ];

  final Set<String> collected = {};
  bool loading = true;

  String get storageKey =>
      'songs_${widget.game.id}_profile_${widget.profileNumber}';

  @override
  void initState() {
    super.initState();
    loadSongs();
  }

  Future<void> loadSongs() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      collected.addAll(
        prefs.getStringList(storageKey) ?? [],
      );
      loading = false;
    });
  }

  Future<void> toggleSong(String song) async {
    setState(() {
      if (collected.contains(song)) {
        collected.remove(song);
      } else {
        collected.add(song);
      }
    });

    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(
      storageKey,
      collected.toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final count = collected.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Songs'),
        backgroundColor: const Color(0xFF24152F),
      ),
      body: loading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Profile ${widget.profileNumber} · '
                '$count/${songs.length} collected',
            style: Theme.of(context)
                .textTheme
                .titleLarge,
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: count / songs.length,
            minHeight: 8,
          ),
          const SizedBox(height: 16),
          for (final song in songs)
            Card(
              color: const Color(0xFF2D1C38),
              child: CheckboxListTile(
                value: collected.contains(song),
                onChanged: (_) => toggleSong(song),
                title: Text(song),
                activeColor:
                Theme.of(context).colorScheme.primary,
              ),
            ),
        ],
      ),
    );
  }
}
class BottlesTrackerScreen extends StatefulWidget {
  final Game game;
  final int profileNumber;

  const BottlesTrackerScreen({
    super.key,
    required this.game,
    required this.profileNumber,
  });

  @override
  State<BottlesTrackerScreen> createState() =>
      _BottlesTrackerScreenState();
}

class _BottlesTrackerScreenState
    extends State<BottlesTrackerScreen> {
  final List<String> bottles = const [
    'Southern Swamp bottle',
    'Goron Race bottle',
    'Romani Ranch bottle',
    'western Ocean bottle',
    'Ikana Graveyard Bottle',
    'Milk Bar Bottle',
  ];

  final Set<String> collected = {};
  bool loading = true;

  String get storageKey =>
      'bottles_${widget.game.id}_profile_${widget.profileNumber}';

  @override
  void initState() {
    super.initState();
    loadBottles();
  }

  Future<void> loadBottles() async {
    final prefs = await SharedPreferences.getInstance();

    final savedBottles =
        prefs.getStringList(storageKey) ?? [];

    final validBottles = savedBottles
        .where((bottle) => bottles.contains(bottle))
        .toSet();

    await prefs.setStringList(
      storageKey,
      validBottles.toList(),
    );

    if (!mounted) return;

    setState(() {
      collected
        ..clear()
        ..addAll(validBottles);

      loading = false;
    });
  }

  Future<void> toggleBottle(String bottle) async {
    setState(() {
      if (collected.contains(bottle)) {
        collected.remove(bottle);
      } else {
        collected.add(bottle);
      }
    });

    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(
      storageKey,
      collected.toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final count = bottles
        .where((bottle) => collected.contains(bottle))
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bottles'),
        backgroundColor: const Color(0xFF24152F),
      ),
      body: loading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Profile ${widget.profileNumber} · '
                '$count/${bottles.length} collected',
            style: Theme.of(context)
                .textTheme
                .titleLarge,
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: count / bottles.length,
            minHeight: 8,
          ),
          const SizedBox(height: 16),
          for (final bottle in bottles)
            Card(
              color: const Color(0xFF2D1C38),
              child: CheckboxListTile(
                value: collected.contains(bottle),
                onChanged: (_) => toggleBottle(bottle),
                title: Text(bottle),
                activeColor:
                Theme.of(context).colorScheme.primary,
              ),
            ),
        ],
      ),
    );
  }
}
class BomberKidsTrackerScreen extends StatefulWidget {
  final Game game;
  final int profileNumber;

  const BomberKidsTrackerScreen({
    super.key,
    required this.game,
    required this.profileNumber,
  });

  @override
  State<BomberKidsTrackerScreen> createState() =>
      _BomberKidsTrackerScreenState();
}

class _BomberKidsTrackerScreenState
    extends State<BomberKidsTrackerScreen> {
  final List<String> kids = const [
    'Jim — North Clock Town',
    'Bomber Kid 2 — North Clock Town',
    'Bomber Kid 3 — East Clock Town',
    'Bomber Kid 4 — East Clock Town',
    'Bomber Kid 5 — West Clock Town',
  ];

  final Set<String> collected = {};
  bool loading = true;

  String get storageKey =>
      'bomber_kids_${widget.game.id}_profile_${widget.profileNumber}';

  @override
  void initState() {
    super.initState();
    loadKids();
  }

  Future<void> loadKids() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      collected.addAll(
        prefs.getStringList(storageKey) ?? [],
      );
      loading = false;
    });
  }


  Future<void> toggleKid(String kid) async {
    final wasCollected = collected.contains(kid);

    setState(() {
      if (wasCollected) {
        collected.remove(kid);
      } else {
        collected.add(kid);
      }
    });

    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(
      storageKey,
      collected.toList(),
    );

    final unlockKey =
        'notebook_unlocked_${widget.game.id}_profile_${widget.profileNumber}';
    final codeKey =
        'bomber_code_${widget.game.id}_profile_${widget.profileNumber}';

    final alreadyUnlocked =
        prefs.getBool(unlockKey) ?? false;

    final hasAllKids = collected.length == kids.length;

    if (hasAllKids && !alreadyUnlocked) {
      final code = await askForBomberCode();

      if (code != null && code.isNotEmpty) {
        await prefs.setBool(unlockKey, true);
        await prefs.setString(codeKey, code);
      } else {
        setState(() {
          collected.remove(kid);
        });

        await prefs.setStringList(
          storageKey,
          collected.toList(),
        );
      }
    } else if (hasAllKids && alreadyUnlocked && !wasCollected) {
      final code = await askForBomberCode();

      if (code != null && code.isNotEmpty) {
        await prefs.setString(codeKey, code);
      }
    }
  }

  Future<String?> askForBomberCode() async {
    final controller = TextEditingController();

    final code = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Enter Bomber Code'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Bomber Code',
              hintText: 'Enter the code you discovered',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final enteredCode = controller.text.trim();

                if (enteredCode.isNotEmpty) {
                  Navigator.pop(dialogContext, enteredCode);
                }
              },
              child: const Text('Save Code'),
            ),
          ],
        );
      },
    );

    return code;
  }
  @override
  Widget build(BuildContext context) {
    final count = kids
        .where((kid) => collected.contains(kid))
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bomber Squad Kids'),
        backgroundColor: const Color(0xFF24152F),
      ),
      body: loading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Profile ${widget.profileNumber} · '
                '$count/${kids.length} found',
            style: Theme.of(context)
                .textTheme
                .titleLarge,
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: count / kids.length,
            minHeight: 8,
          ),
          const SizedBox(height: 16),
          for (final kid in kids)
            Card(
              color: const Color(0xFF2D1C38),
              child: CheckboxListTile(
                value: collected.contains(kid),
                onChanged: (_) => toggleKid(kid),
                title: Text(kid),
                activeColor:
                Theme.of(context).colorScheme.primary,
              ),
            ),
        ],
      ),
    );
  }
}
class StrayFairiesTrackerScreen extends StatefulWidget {
  final Game game;
  final int profileNumber;

  const StrayFairiesTrackerScreen({
    super.key,
    required this.game,
    required this.profileNumber,
  });

  @override
  State<StrayFairiesTrackerScreen> createState() =>
      _StrayFairiesTrackerScreenState();
}

class _StrayFairiesTrackerScreenState
    extends State<StrayFairiesTrackerScreen> {
  final Map<String, List<String>> templeFairies = {
    'Woodfall Temple': List.generate(
      15,
          (index) => 'Woodfall Fairy ${index + 1}',
    ),
    'Snowhead Temple': List.generate(
      15,
          (index) => 'Snowhead Fairy ${index + 1}',
    ),
    'Great Bay Temple': List.generate(
      15,
          (index) => 'Great Bay Fairy ${index + 1}',
    ),
    'Stone Tower Temple': List.generate(
      15,
          (index) => 'Stone Tower Fairy ${index + 1}',
    ),
  };

  final Set<String> collected = {};
  bool loading = true;

  String get storageKey =>
      'stray_fairies_${widget.game.id}_profile_${widget.profileNumber}';

  @override
  void initState() {
    super.initState();
    loadFairies();
  }

  Future<void> loadFairies() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      collected.addAll(prefs.getStringList(storageKey) ?? []);
      loading = false;
    });
  }

  Future<void> toggleFairy(String fairy) async {
    setState(() {
      if (collected.contains(fairy)) {
        collected.remove(fairy);
      } else {
        collected.add(fairy);
      }
    });

    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(
      storageKey,
      collected.toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalCollected = templeFairies.values
        .expand((fairies) => fairies)
        .where((fairy) => collected.contains(fairy))
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stray Fairies'),
        backgroundColor: const Color(0xFF24152F),
      ),
      body: loading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Profile ${widget.profileNumber} · '
                '$totalCollected/60 collected',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: totalCollected / 60,
            minHeight: 8,
          ),
          const SizedBox(height: 16),
          for (final temple in templeFairies.entries)
            Card(
              color: const Color(0xFF2D1C38),
              child: ExpansionTile(
                title: Text(temple.key),
                subtitle: Text(
                  '${temple.value.where((fairy) => collected.contains(fairy)).length}/15 collected',
                ),
                children: [
                  for (final fairy in temple.value)
                    CheckboxListTile(
                      value: collected.contains(fairy),
                      onChanged: (_) => toggleFairy(fairy),
                      title: Text(fairy),
                      activeColor:
                      Theme.of(context).colorScheme.primary,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class BombersNotebookScreen extends StatefulWidget {
  final dynamic game;
  final int profileNumber;
  final String bomberCode;

  const BombersNotebookScreen({
    super.key,
    required this.game,
    required this.profileNumber,
    required this.bomberCode,
  });

  @override
  State<BombersNotebookScreen> createState() =>
      _BombersNotebookScreenState();
}

class _BombersNotebookScreenState
    extends State<BombersNotebookScreen> {
  Set<String> learnedSongs = {};
  List<String> scarecrowSong = [];
  bool isLoading = true;

  String get profileKey =>
      '${widget.game.id}_profile_${widget.profileNumber}';

  String get learnedSongsKey => 'songs_$profileKey';

  String get scarecrowSongKey =>
      'scarecrow_song_$profileKey';

  final List<Map<String, dynamic>> songs = [
    {
      'name': 'Song of Time',
      'notes': [
        'C-Right', 'A', 'C-Down',
        'C-Right', 'A', 'C-Down'
      ],
      'isVariation': false,
    },
    {
      'name': 'Inverted Song of Time',
      'notes': [
        'C-Down', 'A', 'C-Right',
        'C-Down', 'A', 'C-Right'
      ],
      'isVariation': true,
    },
    {
      'name': 'Song of Double Time',
      'notes': [
        'C-Right', 'C-Right', 'A',
        'A', 'C-Down', 'C-Down'
      ],
      'isVariation': true,
    },
    {
      'name': 'Song of Healing',
      'notes': [
        'C-Left', 'C-Right', 'C-Down',
        'C-Left', 'C-Right', 'C-Down'
      ],
    },
    {
      'name': "Epona's Song",
      'notes': [
        'C-Up', 'C-Left', 'C-Right',
        'C-Up', 'C-Left', 'C-Right'
      ],
    },
    {
      'name': 'Song of Soaring',
      'notes': [
        'C-Down', 'C-Left', 'C-Up',
        'C-Down', 'C-Left', 'C-Up'
      ],
    },
    {
      'name': 'Sonata of Awakening',
      'notes': [
        'C-Up', 'C-Left', 'C-Up', 'C-Left',
        'A', 'C-Right', 'A',
      ],
    },
    {
      'name': 'Goron Lullaby',
      'notes': [
        'A', 'C-Right', 'C-Left', 'A',
        'C-Right', 'C-Left', 'C-Right', 'A',
      ],
    },
    {
      'name': 'New Wave Bossa Nova',
      'notes': [
        'C-Left', 'C-Up', 'C-Left', 'C-Right',
        'C-Down', 'C-Left', 'C-Right'
      ],
    },
    {
      'name': 'Elegy of Emptiness',
      'notes': [
        'C-Right', 'C-Left', 'C-Right',
        'C-Down', 'C-Right', 'C-Up', 'C-Left'
      ],
    },
    {
      'name': 'Oath to Order',
      'notes': [
        'C-Right', 'C-Down', 'A',
        'C-Down', 'C-Right', 'C-Up'
      ],
    },
    {
      'name': 'Song of Storms',
      'notes': [
        'A', 'C-Down', 'C-Up', 'A', 'C-Down', 'C-Up'
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    loadSongs();
  }

  Future<void> loadSongs() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      learnedSongs =
          (prefs.getStringList(learnedSongsKey) ?? []).toSet();

      scarecrowSong =
          prefs.getStringList(scarecrowSongKey) ?? [];

      isLoading = false;
    });
  }

  Future<void> recordNote(String note) async {
    if (scarecrowSong.length >= 8) return;

    final updatedSong = [...scarecrowSong, note];

    setState(() {
      scarecrowSong = updatedSong;
    });

    if (updatedSong.length == 8) {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setStringList(
        scarecrowSongKey,
        updatedSong,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Scarecrow Song saved!'),
        ),
      );
    }
  }

  Future<void> clearScarecrowSong() async {
    setState(() {
      scarecrowSong = [];
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(scarecrowSongKey);
  }

  Widget buildSongNotes(List<String> notes) {
return LayoutBuilder(
builder: (context, constraints) {
  final noteSize = ((constraints.maxWidth -
      (notes.length - 1) * 4) / notes.length)
      .clamp(0.0, 38.0)
      .toDouble();

return Row(
mainAxisSize: MainAxisSize.max,
        children: notes.asMap().entries.map((entry) {
          final note = entry.value;
          final isA = note == 'A';

          final IconData arrow = switch (note) {
            'C-Up' => Icons.arrow_upward,
            'C-Down' => Icons.arrow_downward,
            'C-Left' => Icons.arrow_back,
            'C-Right' => Icons.arrow_forward,
            _ => Icons.music_note,
          };

          return Padding(
            padding: EdgeInsets.only(
              right: entry.key == notes.length - 1 ? 0 : 4,
            ),
            child: Container(
              width: noteSize,
              height: noteSize,
              decoration: BoxDecoration(
                color: isA
                    ? const Color(0xFF238442)
                    : const Color(0xFFE0C34F),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isA
                      ? const Color(0xFF65C982)
                      : const Color(0xFFFFE783),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    offset: const Offset(0, 2),
                    blurRadius: 2,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: isA
                  ? Text(
                'A',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: noteSize * 0.45,
                  fontWeight: FontWeight.bold,
                ),
              )
                  : Icon(
                arrow,
                color: const Color(0xFF292714),
                size: noteSize * 0.55,
              ),
            ),
          );
        }).toList(),
);
},
);
  }

  Widget buildSongsPage() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final regularSongs = songs.where(
          (song) => song['isVariation'] != true,
    ).toList();

    final learnedCount = regularSongs.where(
          (song) => learnedSongs.contains(song['name']),
    ).length;

    final songOfTimeLearned =
    learnedSongs.contains('Song of Time');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Songbook',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text('$learnedCount of 10 songs discovered'),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: learnedCount / 10,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Discover songs in your main tracker to '
                      'reveal their names and notes here.',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        ...songs
            .where((song) =>
        song['isVariation'] != true ||
            songOfTimeLearned)
            .map((song) {
          final name = song['name'] as String;
          final notes = song['notes'] as List<String>;
          final isVariation = song['isVariation'] == true;

          final isLearned = isVariation
              ? songOfTimeLearned
              : learnedSongs.contains(name);

          return Card(
            child: ListTile(
              leading: Icon(
                isLearned
                    ? Icons.music_note
                    : Icons.music_off,
              ),
              title: Text(
                isLearned ? name : 'Undiscovered Song',
              ),
              subtitle: isLearned
                  ? Padding(
                padding: const EdgeInsets.only(top: 8),
                child: buildSongNotes(notes),
              )
                  : const Text(
                'Learn this song to reveal its notes.',
              ),
              isThreeLine: isLearned,
            ),
          );
        }),

        const SizedBox(height: 20),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Scarecrow Song',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Create your own eight-note melody. '
                      'Your recording saves automatically '
                      'when you press the eighth note.',
                ),
                const SizedBox(height: 12),
                Text(
                  'Notes recorded: ${scarecrowSong.length}/8',
                ),
                const SizedBox(height: 8),

                if (scarecrowSong.isEmpty)
                  const Text('Your melody will appear here.')
                else
                  buildSongNotes(scarecrowSong),

                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    'A',
                    'C-Up',
                    'C-Left',
                    'C-Right',
                    'C-Down',
                  ].map((note) {
                    final bool isA = note == 'A';

                    final IconData? arrow = switch (note) {
                      'C-Up' => Icons.arrow_upward,
                      'C-Down' => Icons.arrow_downward,
                      'C-Left' => Icons.arrow_back,
                      'C-Right' => Icons.arrow_forward,
                      _ => null,
                    };

                    return Expanded(
                        child: SizedBox(
                      height: 58,
                      child: ElevatedButton(
                        onPressed: scarecrowSong.length < 8
                            ? () => recordNote(note)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isA
                              ? const Color(0xFF238442)
                              : const Color(0xFFE0C34F),
                          foregroundColor: isA ? Colors.white : const Color(0xFF292714),
                          disabledBackgroundColor: const Color(0xFF30342D),
                          disabledForegroundColor: const Color(0xFF777A72),
                          padding: EdgeInsets.zero,
                          shape: isA
                              ? const CircleBorder()
                              : RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(
                            color: isA
                                ? const Color(0xFF65C982)
                                : const Color(0xFFFFE783),
                            width: 2,
                          ),
                          elevation: 2,
                        ),
                        child: isA
                            ? const Text(
                          'A',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                            : Icon(arrow, size: 28),
                      ),
                        ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: scarecrowSong.isNotEmpty
                            ? clearScarecrowSong
                            : null,
                        child: const Text('Record Again'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Record your melody again at any time. '
                      'Press eight notes to save the new version.',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }


  Widget buildCharactersPage() {
    final characters = [

      {
        'name': 'Anju',
        'description':
        'The Stock Pot Inn’s innkeeper. Her story is closely connected to Kafei.',
        'location': 'Stock Pot Inn, Clock Town',
        'schedule': {
          'First Day': [
            {
              'time': '2:15–8:00 PM',
              'location': 'Stock Pot Inn',
              'activity':
              'After the Postman delivers Kafei’s letter, speak to Anju while wearing Kafei’s Mask. She will arrange to meet you in the kitchen late that night.',
            },
            {
              'time': '11:30 PM',
              'location': 'Stock Pot Inn kitchen',
              'activity':
              'Meet Anju at the arranged time. The encounter and handover of the Letter to Kafei occur around midnight.',
            },
          ],
          'Second Day': [
            {
              'time': '4:10–9:00 PM',
              'location': 'Stock Pot Inn',
              'activity':
              'Give Anju the Pendant of Memories after obtaining it from Kafei.',
            },
          ],
          'Final Day': [
            {
              'time': '6:00 AM–12:00 PM',
              'location': 'Stock Pot Inn',
              'activity':
              'If you missed the previous day, you can still give Anju the Pendant of Memories during this window.',
            },
            {
              'time': 'Around 4:30–6:00 AM',
              'location': 'Stock Pot Inn staff room',
              'activity':
              'If the required quest conditions have been met, Anju reunites with Kafei and you can obtain the Couple’s Mask.',
            },
          ],
        },
      },

      {
        'name': 'Kafei',
        'description':
        'Anju’s fiancé, transformed into a child by Skull Kid. He is hiding while trying to recover his stolen Sun’s Mask.',
        'location': 'Laundry Pool, Clock Town, and Ikana Canyon',
        'schedule': {
          'First Day': [
            {
              'time': 'Throughout the day',
              'location': 'Curiosity Shop hideout, Laundry Pool',
              'activity':
              'Kafei is in hiding. Speak to Anju while wearing Kafei’s Mask and arrange to meet her that night to begin the quest.',
            },
          ],
          'Second Day': [
            {
              'time': '3:10–3:50 PM',
              'location': 'Laundry Pool, Clock Town',
              'activity':
              'The Postman delivers Anju’s letter. Kafei comes outside to collect his mail, allowing you to enter his hideout.',
            },
            {
              'time': '4:10–6:00 PM',
              'location': 'Curiosity Shop hideout, Laundry Pool',
              'activity':
              'Speak with Kafei to learn about the stolen Sun’s Mask. He gives you the Pendant of Memories to deliver to Anju.',
            },
          ],
          'Final Day': [
            {
              'time': '6:00 AM',
              'location': 'Ikana Canyon',
              'activity':
              'Kafei waits near Sakon’s Hideout, preparing to recover his stolen Sun’s Mask.',
            },
            {
              'time': 'Around 6:00 PM onward',
              'location': 'Sakon’s Hideout, Ikana Canyon',
              'activity':
              'Meet Kafei and help him recover the Sun’s Mask from Sakon’s Hideout.',
            },
            {
              'time': '4:30–6:00 AM',
              'location': 'Stock Pot Inn, Employees Only room',
              'activity':
              'After recovering the Sun’s Mask and giving Anju the Pendant of Memories, Anju and Kafei reunite. You receive the Couple’s Mask.',
            },
          ],
        },
      },
      {
        'name': 'Curiosity Shop Owner',
        'description':
        'The owner of the Curiosity Shop, who trades in unusual goods and helps Kafei during his quest.',
        'location': 'Curiosity Shop, West Clock Town',
        'schedule': {
          'First Day': [
            {
              'time': '10:00 PM–5:00 AM',
              'location': 'Curiosity Shop, West Clock Town',
              'activity':
              'Opens the Curiosity Shop for the night, selling unusual goods.',
            },
          ],
          'Second Day': [
            {
              'time': '10:00 PM–5:00 AM',
              'location': 'Curiosity Shop, West Clock Town',
              'activity':
              'Opens the Curiosity Shop for the night, selling unusual goods.',
            },
          ],
          'Final Day': [
            {
              'time': '1:00–10:00 PM',
              'location': 'Kafei’s hideout, Laundry Pool',
              'activity':
              'If you have spoken to Kafei and received the Pendant of Memories, speak to the owner in the hideout. He gives you the Keaton Mask and the Special Delivery to Mama.',
            },
            {
              'time': '10:00 PM–5:00 AM',
              'location': 'Curiosity Shop, West Clock Town',
              'activity':
              'Opens the Curiosity Shop for the final night.',
            },
          ],
        },
      },
      {
        'name': 'Old Lady from Bomb Shop',
        'description':
        'The elderly owner of the Bomb Shop, who carries bomb bags into Clock Town for her son.',
        'location': 'Bomb Shop, West Clock Town',
        'schedule': {
          'First Day': [
            {
              'time': 'Around 12:00–12:30 AM',
              'location': 'North Clock Town',
              'activity':
              'The Old Lady enters Clock Town carrying a sack of bomb bags. Sakon steals her sack. If you stop him with your sword before he escapes, she rewards you with the Blast Mask.',
            },
            {
              'time': 'Around 12:30 AM onward',
              'location': 'Bomb Shop, West Clock Town',
              'activity':
              'After arriving at the shop, she continues her usual business. Rescuing her allows the Big Bomb Bag to become available for purchase at the Bomb Shop.',
            },
          ],
        },
      },
      {
        'name': 'Romani',
        'description':
        'The younger of the two sisters at Romani Ranch. She knows that mysterious creatures will try to abduct the ranch’s cows and asks you to help protect them.',
        'location': 'Romani Ranch',
        'schedule': {
          'First Day': [
            {
              'time': '6:00 AM–6:00 PM',
              'location': 'Romani Ranch',
              'activity':
              'Find Romani outside near the ranch house and barn. Complete her balloon-shooting test on Epona to prove your skill with a bow. She teaches you Epona’s Song and asks you to help defend the ranch that night.',
            },
            {
              'time': 'Around 2:00–2:30 AM',
              'location': 'Romani Ranch',
              'activity':
              'Meet Romani outside the barn. The mysterious aliens arrive, and she explains how to defend the cows. Use your bow to stop the aliens from reaching the barn.',
            },
          ],
        },
      },
      {
        'name': 'Cremia',
        'description':
        'Romani’s older sister and the manager of Romani Ranch. She runs the ranch and delivers its milk to Clock Town.',
        'location': 'Romani Ranch and Milk Road',
        'schedule': {

          'Second Day': [
            {
              'time': '6:00–9:00 PM',
              'location': 'Romani Ranch and Milk Road',
              'activity':
              'If you successfully defended the cows for Romani, Cremia offers you a ride into Clock Town with the milk delivery. The Gorman Brothers attack the wagon on the way. Protect the milk bottles until you reach your destination to receive Romani’s Mask.',
            },
          ],

        },
      },
      {
        'name': 'Mayor Dotour',
        'description':
        'The mayor of Clock Town, struggling to decide whether the Carnival of Time should continue as the Moon approaches.',
        'location': 'Mayor’s Residence, East Clock Town',
        'schedule': {
          'First Day': [
            {
              'time': '10:00 AM–8:00 PM',
              'location': 'Mayor’s Residence, meeting room',
              'activity':
              'Mayor Dotour attends a meeting about whether Clock Town should evacuate or continue the Carnival of Time. Wear the Couple’s Mask during the meeting to resolve the dispute and receive a Piece of Heart.',
            },
          ],
          'Second Day': [
            {
              'time': '10:00 AM–8:00 PM',
              'location': 'Mayor’s Residence, meeting room',
              'activity':
              'Mayor Dotour continues the meeting about the Carnival of Time. If you have not already done so, wear the Couple’s Mask during the meeting to resolve the dispute and receive a Piece of Heart.',
            },
          ],
          'Final Day': [
            {
              'time': '10:00 AM–6:00 PM',
              'location': 'Mayor’s Residence, meeting room',
              'activity':
              'The meeting continues as the Moon approaches. If you have not already done so, wear the Couple’s Mask during the meeting to resolve the dispute and receive a Piece of Heart.',
            },
          ],
        },
      },
      {
        'name': 'Madame Aroma',
        'description':
        'The mayor’s wife and Kafei’s mother. She hires Link to find her missing son.',
        'location': 'Mayor’s Residence, East Clock Town',
        'schedule': {
          'First Day': [
            {
              'time': '10:00 AM–8:00 PM',
              'location': 'Mayor’s Residence',
              'activity':
              'Speak to Madame Aroma and agree to help find her missing son, Kafei. She gives you Kafei’s Mask, which helps you continue the search.',
            },
          ],
          'Second Day': [
            {
              'time': '10:00 AM–8:00 PM',
              'location': 'Mayor’s Residence',
              'activity':
              'If you have not already accepted her request, speak to Madame Aroma and agree to find Kafei. She gives you Kafei’s Mask.',
            },
          ],
          'Final Day': [
            {
              'time': 'After 10:00 AM',
              'location': 'Milk Bar, East Clock Town',
              'activity':
              'After receiving the Special Delivery to Mama from the Curiosity Shop Owner, speak to Madame Aroma while wearing Kafei’s Mask and give her the letter. She rewards you with a bottle filled with Chateau Romani.',
            },
          ],
        },
      },
      {
        'name': 'Toto',
        'description':
        'The manager of the Indigo-Go’s, visiting Clock Town to prepare for the troupe’s cancelled Carnival of Time performance.',
        'location': 'Mayor’s Residence and Milk Bar, Clock Town',
        'schedule': {
          'First Day': [
            {
              'time': '10:00 AM–11:45 AM',
              'location': 'Mayor’s Residence',
              'activity':
              'Meets with Madame Aroma to discuss the Indigo-Go’s performance and preparations for the Carnival of Time.',
            },
            {
              'time': '10:00 PM–5:00 AM',
              'location': 'Milk Bar, East Clock Town',
              'activity':
              'Conducts a sound check for the Indigo-Go’s cancelled performance. Speak to Toto as Hylian, Deku, Goron, and Zora Link, then play the requested music on stage in each form. Completing all four parts prompts Gorman to give you the Circus Leader’s Mask.',
            },
          ],
          'Second Day': [
            {
              'time': '10:00 AM–8:00 PM',
              'location': 'Mayor’s Residence',
              'activity':
              'Can be found at the Mayor’s Residence discussing the cancelled performance with Madame Aroma.',
            },
            {
              'time': '10:00 PM–5:00 AM',
              'location': 'Milk Bar, East Clock Town',
              'activity':
              'If you have not completed the sound check, speak to Toto and play the requested music on stage as Hylian, Deku, Goron, and Zora Link. Completing all four parts prompts Gorman to give you the Circus Leader’s Mask.',
            },
          ],
        },
      },
      {
        'name': 'Gorman',
        'description':
        'The leader of the Gorman Troupe. Upset that his troupe’s performance has been cancelled, he spends time drinking at the Milk Bar.',
        'location': 'Mayor’s Residence and Milk Bar, Clock Town',
        'schedule': {
          'First Day': [
            {
              'time': '10:00 AM–11:45 AM',
              'location': 'Mayor’s Residence',
              'activity':
              'Meets with Madame Aroma to discuss the cancelled performance.',
            },
            {
              'time': '1:00 PM',
              'location': 'Milk Bar, East Clock Town',
              'activity':
              'Visits the Milk Bar and spends time thinking about the cancelled performance.',
            },
            {
              'time': '10:00 PM–5:59 AM',
              'location': 'Milk Bar, East Clock Town',
              'activity':
              'Drinks at the Milk Bar. If you complete Toto’s sound check by playing the requested music in all four forms, Gorman is moved by the song and gives you the Circus Leader’s Mask.',
            },
          ],
          'Second Day': [
            {
              'time': '10:00 PM–5:59 AM',
              'location': 'Milk Bar, East Clock Town',
              'activity':
              'Drinks at the Milk Bar. If you have not completed Toto’s sound check, you can still play the requested music in all four forms to receive the Circus Leader’s Mask from Gorman.',
            },
          ],
        },
      },
      {
        'name': 'Postman',
        'description':
        'Clock Town’s hardworking mail carrier. He follows a strict schedule and takes his duties very seriously.',
        'location': 'Post Office, West Clock Town, and Clock Town',
        'schedule': {
          'First Day': [
            {
              'time': 'Around 2:00 PM',
              'location': 'Stock Pot Inn, East Clock Town',
              'activity':
              'Delivers Kafei’s letter to Anju at the inn’s front desk.',
            },
            {
              'time': '3:00 PM–12:00 AM',
              'location': 'Post Office, West Clock Town',
              'activity':
              'Returns to the Post Office after his deliveries. You can take his ten-second timing challenge to earn a Piece of Heart.',
            },
          ],
          'Second Day': [
            {
              'time': 'Morning',
              'location': 'Clock Town mailboxes',
              'activity':
              'Collects letters from the town’s mailboxes during his morning rounds, including Anju’s letter if it was posted in time.',
            },
            {
              'time': 'Around 3:10–3:50 PM',
              'location': 'Laundry Pool, Clock Town',
              'activity':
              'Delivers Anju’s letter to Kafei. Kafei comes out to collect it, allowing you to enter his hideout.',
            },
            {
              'time': '3:00 PM–12:00 AM',
              'location': 'Post Office, West Clock Town',
              'activity':
              'Returns to the Post Office after his deliveries. You can take his ten-second timing challenge if you have not already completed it.',
            },
          ],
          'Final Day': [
            {
              'time': '6:00 PM onward',
              'location': 'Post Office, West Clock Town',
              'activity':
              'Can receive the Special Delivery to Mama from the player. He delivers it to Madame Aroma at the Milk Bar. Speak to him outside afterward to receive the Postman’s Hat.',
            },
          ],
        },
      },
      {
        'name': 'Rosa Sisters',
        'description':
        'Twin dancers from the Gorman Troupe who are struggling to find a dance for the Carnival of Time.',
        'location': 'West Clock Town and Stock Pot Inn',
        'schedule': {
          'First Day': [
            {
              'time': '6:00 PM–6:00 AM',
              'location': 'West Clock Town, outside the Lottery Shop',
              'activity':
              'The sisters practise their dance for the Carnival of Time. Wear Kamaro’s Mask and perform his dance in front of them to teach them new moves. They reward you with a Piece of Heart.',
            },
          ],
          'Second Day': [
            {
              'time': '6:00 PM–6:00 AM',
              'location': 'West Clock Town, outside the Lottery Shop',
              'activity':
              'The sisters continue practising their dance. If you have not already done so, wear Kamaro’s Mask and perform his dance in front of them to teach them new moves and receive a Piece of Heart.',
            },
          ],
        },
      },
      {
        'name': '???',
        'description':
        'A mysterious hand that reaches out from the toilet in the Stock Pot Inn, asking for paper.',
        'location': 'Stock Pot Inn restroom, Clock Town',
        'schedule': {
          'First Day': [
            {
              'time': '12:00–6:00 AM',
              'location': 'Stock Pot Inn restroom',
              'activity':
              'Reaches out from the toilet and asks for paper. Give the hand a letter or Land Title Deed to receive a Piece of Heart.',
            },
          ],
          'Second Day': [
            {
              'time': '12:00–6:00 AM',
              'location': 'Stock Pot Inn restroom',
              'activity':
              'Reaches out from the toilet and asks for paper. If you have not already received the reward, give the hand a letter or Land Title Deed to receive a Piece of Heart.',
            },
          ],
          'Final Day': [
            {
              'time': '12:00–6:00 AM',
              'location': 'Stock Pot Inn restroom',
              'activity':
              'Reaches out from the toilet and asks for paper. If you have not already received the reward, give the hand a letter or Land Title Deed to receive a Piece of Heart.',
            },
          ],
        },
      },
      {
        'name': 'Anju’s Grandmother',
        'description':
        'Anju’s grandmother, who spends her time telling stories at the Stock Pot Inn.',
        'location': 'Stock Pot Inn, East Clock Town',
        'schedule': {
          'First Day': [
            {
              'time': '8:00 AM–6:00 PM',
              'location': 'Stock Pot Inn, Granny’s room',
              'activity':
              'Wear the All-Night Mask and listen to her story about the Carnival of Time. Answer “On the eve of the festival” to receive a Piece of Heart.',
            },
            {
              'time': '8:00 AM–6:00 PM',
              'location': 'Stock Pot Inn, Granny’s room',
              'activity':
              'Wear the All-Night Mask and listen to her story about the Four Giants. Answer “I dunno” to receive a second Piece of Heart.',
            },
          ],
          'Second Day': [
            {
              'time': '8:00 AM–6:00 PM',
              'location': 'Stock Pot Inn, Granny’s room',
              'activity':
              'If you have not already heard her story about the Carnival of Time, wear the All-Night Mask and listen. Answer “On the eve of the festival” to receive a Piece of Heart.',
            },
            {
              'time': '8:00 AM–6:00 PM',
              'location': 'Stock Pot Inn, Granny’s room',
              'activity':
              'If you have not already heard her story about the Four Giants, wear the All-Night Mask and listen. Answer “I dunno” to receive a second Piece of Heart.',
            },
          ],
        },
      },
      {
        'name': 'Kamaro',
        'description':
        'The ghost of a dancer who wanted to share his dance with the world but died before he could teach it to anyone.',
        'location': 'Mushroom-shaped rock in northern Termina Field',
        'schedule': {
          'First Day': [
            {
              'time': '12:00–6:00 AM',
              'location': 'Mushroom-shaped rock, northern Termina Field',
              'activity':
              'Appears as a ghost dancing on the rock. Speak to him and play the Song of Healing to receive Kamaro’s Mask.',
            },
          ],
          'Second Day': [
            {
              'time': '12:00–6:00 AM',
              'location': 'Mushroom-shaped rock, northern Termina Field',
              'activity':
              'Appears dancing on the rock. If you have not already received Kamaro’s Mask, speak to him and play the Song of Healing.',
            },
          ],
          'Final Day': [
            {
              'time': '12:00–6:00 AM',
              'location': 'Mushroom-shaped rock, northern Termina Field',
              'activity':
              'Appears dancing on the rock. If you have not already received Kamaro’s Mask, speak to him and play the Song of Healing.',
            },
          ],
        },
      },
      {
        'name': 'Grog',
        'description':
        'The Cucco Shack breeder at Romani Ranch. He hopes to see all his chicks grow into adult Cuccos before the Moon falls.',
        'location': 'Cucco Shack, Romani Ranch',
        'schedule': {
          'First Day': [
            {
              'time': '6:00 AM–8:00 PM',
              'location': 'Cucco Shack, Romani Ranch',
              'activity':
              'If you have opened the road to Romani Ranch, speak to Grog about his chicks. Wear the Bremen Mask and march around the pen to gather all ten chicks and help them grow into adult Cuccos. Grog rewards you with the Bunny Hood.',
            },
          ],
          'Second Day': [
            {
              'time': '6:00 AM–8:00 PM',
              'location': 'Cucco Shack, Romani Ranch',
              'activity':
              'If you have opened the road to Romani Ranch and have not already received the Bunny Hood, speak to Grog. Wear the Bremen Mask and march around the pen to gather all ten chicks and help them grow into adult Cuccos.',
            },
          ],
          'Final Day': [
            {
              'time': '6:00 AM–8:00 PM',
              'location': 'Cucco Shack, Romani Ranch',
              'activity':
              'Speak to Grog if you have not already helped his chicks grow. Wear the Bremen Mask and march around the pen to gather all ten chicks and help them grow into adult Cuccos. Grog rewards you with the Bunny Hood.',
            },
          ],
        },
      },
      {
        'name': 'Gorman Brothers',
        'description':
        'Two horse trainers who run the Gorman Racetrack and try to steal Cremia’s milk shipment.',
        'location': 'Gorman Racetrack, Milk Road',
        'schedule': {
          'First Day': [
            {
              'time': '6:00 AM–6:00 PM',
              'location': 'Gorman Racetrack, Milk Road',
              'activity':
              'Speak to either brother while riding Epona and pay 10 Rupees to race them. Win the race to receive the Garo’s Mask.',
            },
          ],
          'Second Day': [
            {
              'time': '6:00 AM–6:00 PM',
              'location': 'Gorman Racetrack, Milk Road',
              'activity':
              'Speak to either brother while riding Epona and pay 10 Rupees to race them. If you have not already won, defeat them to receive the Garo’s Mask.',
            },
            {
              'time': '6:00–8:00 PM',
              'location': 'Milk Road, along Cremia’s delivery route',
              'activity':
              'If Romani’s cows were successfully protected the previous night, the brothers ride after Cremia’s milk wagon and attempt to damage the milk bottles. Help Cremia protect the delivery to Clock Town.',
            },
          ],
          'Final Day': [
            {
              'time': '6:00 AM–6:00 PM',
              'location': 'Gorman Racetrack, Milk Road',
              'activity':
              'Speak to either brother while riding Epona and pay 10 Rupees to race them. If you have not already won, defeat them to receive the Garo’s Mask.',
            },
          ],
        },
      },
      {
        'name': 'Shiro',
        'description':
        'An injured soldier whom nobody notices because he is wearing the Stone Mask, which makes him invisible to most people and enemies.',
        'location': 'Road to Ikana, near the Ikana Canyon entrance',
        'schedule': {
          'First Day': [
            {
              'time': 'Any time',
              'location':
              'Ring of stones on the Road to Ikana',
              'activity':
              'Use the Lens of Truth to find Shiro sitting invisibly among the stones. Speak to him and give him a Red or Blue Potion to heal him. He rewards you with the Stone Mask.',
            },
          ],
          'Second Day': [
            {
              'time': 'Any time',
              'location':
              'Ring of stones on the Road to Ikana',
              'activity':
              'Use the Lens of Truth to find Shiro if you have not already helped him. Give him a Red or Blue Potion to receive the Stone Mask.',
            },
          ],
          'Final Day': [
            {
              'time': 'Any time',
              'location':
              'Ring of stones on the Road to Ikana',
              'activity':
              'Use the Lens of Truth to find Shiro if you have not already helped him. Give him a Red or Blue Potion to receive the Stone Mask.',
            },
          ],
        },
      },
      {
        'name': 'Guru-Guru',
        'description':
        'A musician from the Gorman Troupe who plays a music box and tells Link about his past mistake involving the Bremen Mask.',
        'location': 'Laundry Pool, Clock Town',
        'schedule': {
          'First Day': [
            {
              'time': '6:00 PM–6:00 AM',
              'location': 'Laundry Pool, Clock Town',
              'activity':
              'Sits by the water playing his music box. Speak to him as Hylian Link and listen to his story about stealing the Bremen Mask. He gives you the Bremen Mask.',
            },
          ],
          'Second Day': [
            {
              'time': '6:00 PM–6:00 AM',
              'location': 'Laundry Pool, Clock Town',
              'activity':
              'Returns to the Laundry Pool at night. If you have not already received the Bremen Mask, speak to him as Hylian Link and listen to his story.',
            },
          ],
        },
      },
    ];

    int selectedIndex = 0;

    return StatefulBuilder(
      builder: (context, setCharacterState) {
        final character = characters[selectedIndex];
        final portraitAssets = {
          'Anju': 'assets/portraits/anju.png',
          'Kafei': 'assets/portraits/kafei.png',
          'Curiosity Shop Owner': 'assets/portraits/curiosity_shop_owner.png',
          'Old Lady from Bomb Shop': 'assets/portraits/old_lady_from_the_bomb_shop.png',
          'Romani': 'assets/portraits/romani.png',
          'Cremia': 'assets/portraits/cremia.png',
          'Mayor Dotour': 'assets/portraits/mayor_dotour.png',
          'Madame Aroma': 'assets/portraits/madame_aroma.png',
          'Toto': 'assets/portraits/toto.png',
          'Gorman': 'assets/portraits/gorman.png',
          'Postman': 'assets/portraits/postman.png',
          'Rosa Sisters': 'assets/portraits/rosa_sisters.png',
          '???': 'assets/portraits/???.png',
          'Anju’s Grandmother': 'assets/portraits/anju_grandmother.png',
          'Kamaro': 'assets/portraits/kamaro.png',
          'Grog': 'assets/portraits/grog.png',
          'Gorman Brothers': 'assets/portraits/gorman_brothers.png',
          'Shiro': 'assets/portraits/shiro.png',
          'Guru-Guru': 'assets/portraits/guru_guru.png',
        };

        final portrait = portraitAssets[character['name']]!;
        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Characters',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Choose a character to view their profile.',
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.12,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: characters.length,
                        itemBuilder: (context, index) {
                          final isSelected =
                              index == selectedIndex;

                          return Padding(
                            padding:
                            const EdgeInsets.only(right: 8),
                            child: InkWell(
                              borderRadius:
                              BorderRadius.circular(12),
                              onTap: () {
                                setCharacterState(() {
                                  selectedIndex = index;
                                });
                              },
                              child: Container(
                                width: MediaQuery.of(context).size.width * 0.28,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius:
                                  BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? Theme.of(context)
                                        .colorScheme
                                        .primary
                                        : Theme.of(context)
                                        .dividerColor,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment:
                                  MainAxisAlignment.center,
                                  children: [
                                    Image.asset(
                                      portraitAssets[characters[index]['name']]!,
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.contain,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      characters[index]['name']! as String,
                                      maxLines: 2,
                                      overflow:
                                      TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          portrait,
                          width: 100,
                          height: 100,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        character['name']! as String,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(character['description']! as String),
                    const SizedBox(height: 12),
                    const Text(
                      'Usual location',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(character['location']! as String),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            ...['First Day', 'Second Day', 'Final Day']
                .where((day) {
              final schedule =
              character['schedule'] as Map<String, dynamic>?;
              final entries =
                  schedule?[day] as List<dynamic>? ?? [];
              return entries.isNotEmpty;
            })
                .map((day) {
              final schedule =
              character['schedule'] as Map<String, dynamic>?;

              final entries =
                  schedule?[day] as List<dynamic>? ?? [];

              return Card(
                child: ExpansionTile(
                  leading: Image.asset(
                    day == 'First Day'
                        ? 'assets/notebook/first.png'
                        : day == 'Second Day'
                        ? 'assets/notebook/second.png'
                        : 'assets/notebook/final.png',
                    width: 32,
                    height: 32,
                    fit: BoxFit.contain,
                  ),
                  title: Text(day),
                  subtitle: Text(
                    entries.isEmpty
                        ? 'Schedule details to be added'
                        : '${entries.length} ${entries.length == 1 ? 'event' : 'events'}',
                  ),
                  children: entries.isEmpty
                      ? const [
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Schedule details have not been added '
                            'for this day yet.',
                      ),
                    ),
                  ]
                      : entries.map<Widget>((entry) {
                    final event =
                    Map<String, dynamic>.from(entry as Map);

                    return ListTile(
                      leading: const Icon(Icons.access_time),
                      title: Text(
                        event['time'] as String? ?? 'Time unknown',
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event['activity'] as String? ??
                                'Activity not specified',
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Location: ${event['location'] as String? ?? 'Unknown'}',
                          ),
                        ],
                      ),
                      isThreeLine: true,
                    );
                  }).toList(),
                ),
              );
            }),

          ],
        );
      },
    );
  }


  Widget buildEventsPage() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        Card(
          child: ListTile(
            leading: Icon(Icons.event_note),
            title: Text('Events & Rumours'),
            subtitle: Text(
              'Coming in a future update! This section will be a hint system.',
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Bombers' Notebook"),
          bottom: TabBar(
            isScrollable: false,
            tabs: [
              Tab(
                icon: Image.asset(
                  'assets/notebook/characters.png',
                  width: 24,
                  height: 24,
                ),
                text: 'Characters',
              ),
              Tab(
                icon: Image.asset(
                  'assets/notebook/hints.png',
                  width: 24,
                  height: 24,
                ),
                text: 'Gossip',
              ),
              Tab(
                icon: Image.asset(
                  'assets/Checklists/songs.png',
                  width: 24,
                  height: 24,
                ),
                text: 'Songs',
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            Card(
              margin: const EdgeInsets.all(12),
              child: ListTile(
                leading: Image.asset(
                  'assets/notebook/bomber_code.png',
                  width: 36,
                  height: 36,
                  fit: BoxFit.contain,
                ),
                title: Text(
                  'Profile ${widget.profileNumber}',
                ),
                subtitle: const Text('Bomber Code'),
                trailing: Text(
                  widget.bomberCode.isEmpty
                      ? 'Not set'
                      : widget.bomberCode,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  buildCharactersPage(),
                  buildEventsPage(),
                  buildSongsPage(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
