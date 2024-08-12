import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/app_drawer.dart';

class DawraOrganizerScreen extends StatefulWidget {
  @override
  _DawraOrganizerScreenState createState() => _DawraOrganizerScreenState();
}

class _DawraOrganizerScreenState extends State<DawraOrganizerScreen> {
  final List<String> _games = ['Ping Pong', 'Billiard Table', 'PlayStation', 'Connect Four'];
  final Map<String, IconData> _gameIcons = {
    'Ping Pong': Icons.sports_tennis,
    'Billiard Table': Icons.workspaces_sharp,
    'PlayStation': Icons.videogame_asset,
    'Connect Four': Icons.grid_4x4,
  };

  String? selectedGame;
  TextEditingController playerNameController = TextEditingController();
  Map<String, List<String>> gamePlayers = {};
  Map<String, List<List<String>>> gamePairings = {};
  Map<String, String> lastWinners = {};
  List<String> currentPlayers = [];
  List<String> roundWinners = [];
  List<List<String>> completedRounds = [];
  bool isDawraStarted = false;

  @override
  void initState() {
    super.initState();
    _loadGameData();
  }

  Future<void> _loadGameData() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    setState(() {
      for (var key in keys) {
        if (key.startsWith('players_')) {
          String game = key.replaceFirst('players_', '');
          gamePlayers[game] = prefs.getStringList(key) ?? [];
        } else if (key.startsWith('pairings_')) {
          String game = key.replaceFirst('pairings_', '');
          gamePairings[game] = prefs
              .getStringList(key)
              ?.map((pair) => pair.split(',').toList())
              .toList() ?? [];
        } else if (key.startsWith('winner_')) {
          String game = key.replaceFirst('winner_', '');
          lastWinners[game] = prefs.getString(key) ?? '';
        }
      }
    });
  }

  Future<void> _saveGameData() async {
    final prefs = await SharedPreferences.getInstance();
    for (var game in gamePlayers.keys) {
      prefs.setStringList('players_$game', gamePlayers[game]!);
    }
    for (var game in gamePairings.keys) {
      prefs.setStringList('pairings_$game',
          gamePairings[game]!.map((pair) => pair.join(',')).toList());
    }
    for (var game in lastWinners.keys) {
      prefs.setString('winner_$game', lastWinners[game]!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('Dawra Organizer'),
      ),
      drawer: user != null ? AppDrawer(user: user) : null,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildGameButtons(),
            SizedBox(height: 16),
            if (!isDawraStarted) _buildPlayerInput(), // Hide when Dawra starts
            SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    if (lastWinners[selectedGame] != null)
                      Text(
                        '🥇Last Winner🥇: ${lastWinners[selectedGame]}',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                      ),
                    if (!isDawraStarted && (gamePlayers[selectedGame]?.isNotEmpty ?? false))
                      ..._buildPlayerList(),
                    if (gamePairings[selectedGame]?.isNotEmpty ?? false)
                      _buildPairingTable(),
                  ],
                ),
              ),
            ),
            _buildStartDawraButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildGameButtons() {
    return Wrap(
      spacing: 10.0,
      runSpacing: 10.0,
      children: _games.map((game) {
        return ElevatedButton.icon(
          icon: Icon(_gameIcons[game]),
          label: Text(game),
          onPressed: () {
            setState(() {
              selectedGame = game;
              currentPlayers = List.from(gamePlayers[game] ?? []);
              roundWinners = [];
              completedRounds = [];
              isDawraStarted = false;
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: selectedGame == game ? Colors.white : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPlayerInput() {
    return Column(
      children: [
        TextField(
          controller: playerNameController,
          decoration: InputDecoration(
            labelText: 'Player Name',
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 16),
        ElevatedButton(
          onPressed: _addPlayer,
          child: Text('Add Player'),
        ),
      ],
    );
  }

  void _addPlayer() {
    if (playerNameController.text.isNotEmpty && selectedGame != null) {
      setState(() {
        if (gamePlayers[selectedGame!] == null) {
          gamePlayers[selectedGame!] = [];
        }
        gamePlayers[selectedGame!]!.add(playerNameController.text);
        playerNameController.clear();
        _saveGameData();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please enter a player name and select a game.'),
      ));
    }
  }

  List<Widget> _buildPlayerList() {
    return [
      ListView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: gamePlayers[selectedGame]?.length ?? 0,
        itemBuilder: (context, index) {
          return Card(
            elevation: 2.0,
            margin: EdgeInsets.symmetric(vertical: 8.0),
            child: ListTile(
              title: Text(gamePlayers[selectedGame!]![index]),
              trailing: IconButton(
                icon: Icon(Icons.delete),
                onPressed: () {
                  setState(() {
                    gamePlayers[selectedGame!]!.removeAt(index);
                    _saveGameData();
                  });
                },
              ),
            ),
          );
        },
      ),
    ];
  }

  Widget _buildPairingTable() {
    List<Widget> pairs = [];
    List<List<String>> pairings = gamePairings[selectedGame] ?? [];
    for (var pair in pairings) {
      String player1 = pair[0];
      String? player2;
      if (pair.length > 1) {
        player2 = pair[1];
      } else {
        player2 = null;
      }

      bool isPairCompleted = completedRounds.any((completedRound) =>
      completedRound.contains(player1) && (player2 == null || completedRound.contains(player2))
      );

      pairs.add(
        Card(
          elevation: 2.0,
          margin: EdgeInsets.symmetric(vertical: 8.0),
          color: isPairCompleted ? Colors.grey : Colors.white,
          child: ListTile(
            title: Text(player2 != null ? '$player1 vs $player2' : '$player1 is waiting'),
            subtitle: player2 != null ? Text('Tap to select winner') : null,
            onTap: () {
              if (!isPairCompleted) {
                if (player2 != null) {
                  _showWinnerDialog(player1, player2);
                } else {
                  setState(() {
                    roundWinners.add(player1);
                    currentPlayers.remove(player1);
                  });
                  _checkNextRound();
                }
              }
            },
          ),
        ),
      );
    }

    return Column(
      children: pairs,
    );
  }

  void _showWinnerDialog(String player1, String player2) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('🏆 Select Winner 🏆'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    roundWinners.add(player1);
                    completedRounds.add([player1, player2]);
                    currentPlayers.remove(player1);
                    currentPlayers.remove(player2);
                  });
                  Navigator.pop(context);
                  _checkNextRound();
                },
                child: Text(player1),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    roundWinners.add(player2);
                    completedRounds.add([player1, player2]);
                    currentPlayers.remove(player1);
                    currentPlayers.remove(player2);
                  });
                  Navigator.pop(context);
                  _checkNextRound();
                },
                child: Text(player2),
              ),
            ],
          ),
        );
      },
    );
  }

  void _checkNextRound() {
    if (currentPlayers.isEmpty) {
      if (roundWinners.length == 1) {
        setState(() {
          lastWinners[selectedGame!] = roundWinners[0];
          _saveGameData();
        });
        _showFinalWinnerDialog(roundWinners[0]);
      } else {
        setState(() {
          currentPlayers = List.from(roundWinners);
          roundWinners = [];
          gamePairings[selectedGame!] = _generatePairings(currentPlayers);
          completedRounds = [];
        });
      }
    } else if (currentPlayers.length == 1 && roundWinners.isNotEmpty) {
      // Pair waiting player with a round winner if any round winners exist
      setState(() {
        currentPlayers.add(roundWinners.removeAt(0));
        gamePairings[selectedGame!] = _generatePairings(currentPlayers);
      });
    }
  }

  Widget _buildStartDawraButton() {
    return ElevatedButton(
      onPressed: () {
        if (selectedGame != null && (gamePlayers[selectedGame]?.length ?? 0) >= 2) {
          setState(() {
            gamePairings[selectedGame!] = [];
            completedRounds = [];
            roundWinners = [];

            currentPlayers = List.from(gamePlayers[selectedGame]!);
            currentPlayers.shuffle(Random());
            gamePairings[selectedGame!] = _generatePairings(currentPlayers);
            isDawraStarted = true;  // Dawra starts
            _saveGameData();
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Please select a game and ensure there are at least 2 players.'),
          ));
        }
      },
      child: Text('Start Dawra'),
    );
  }

  List<List<String>> _generatePairings(List<String> players) {
    List<List<String>> pairings = [];
    for (int i = 0; i < players.length; i += 2) {
      if (i + 1 < players.length) {
        pairings.add([players[i], players[i + 1]]);
      } else {
        pairings.add([players[i]]);
      }
    }
    return pairings;
  }

  void _showFinalWinnerDialog(String winner) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('🎉 Ultimate Winner 🎉'),
          content: Text(
            'Congratulations $winner! Winner of the Dawra! 🏆',
            style: TextStyle(fontSize: 18),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                setState(() {
                  // Clear the game data
                  gamePlayers[selectedGame!] = [];
                  gamePairings[selectedGame!] = [];
                  currentPlayers = [];
                  roundWinners = [];
                  completedRounds = [];
                  isDawraStarted = false; // Make the input field appear
                  _saveGameData();
                });
                Navigator.pop(context);
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
