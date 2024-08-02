import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'universal_points.dart';

class PinEntryDialog extends StatefulWidget {
  final Function(bool) onPinEntered;

  PinEntryDialog({required this.onPinEntered});

  @override
  _PinEntryDialogState createState() => _PinEntryDialogState();
}

class _PinEntryDialogState extends State<PinEntryDialog> {
  final TextEditingController _pinController = TextEditingController();
  final String correctPin = "61757439"; // Predefined PIN for Admin Panel
  final String universalPin = "9510220"; // Predefined PIN for Universal Points

  int _incorrectAttempts = 0;
  bool _isBlocked = false;
  Timer? _countdownTimer;
  Duration _blockDuration = Duration(hours: 1);
  late DateTime _unblockTime;

  @override
  void initState() {
    super.initState();
    _checkBlockStatus();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _checkBlockStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final blockTimeString = prefs.getString('blockTime');
    if (blockTimeString != null) {
      final blockTime = DateTime.parse(blockTimeString);
      if (blockTime.isAfter(DateTime.now())) {
        setState(() {
          _isBlocked = true;
          _unblockTime = blockTime;
        });
        _startCountdown();
      }
    }
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      final remainingTime = _unblockTime.difference(DateTime.now());
      if (remainingTime.isNegative) {
        timer.cancel();
        setState(() {
          _isBlocked = false;
          _incorrectAttempts = 0;
        });
        _clearBlockStatus();
      } else {
        setState(() {});
      }
    });
  }

  void _clearBlockStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('blockTime');
  }

  void _blockUser() async {
    setState(() {
      _isBlocked = true;
      _unblockTime = DateTime.now().add(_blockDuration);
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('blockTime', _unblockTime.toIso8601String());
    _startCountdown();
  }

  void _checkPin() {
    if (_isBlocked) {
      // Early exit if the user is already blocked
      return;
    }

    if (_pinController.text == correctPin) {
      widget.onPinEntered(true);
    } else if (_pinController.text == universalPin) {
      Navigator.of(context).pop();
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => UniversalPointsScreen()),
      );
    } else {
      widget.onPinEntered(false);
      setState(() {
        _incorrectAttempts++;
        if (_incorrectAttempts >= 3) {
          _blockUser();
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Incorrect PIN')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Enter Admin PIN', style: Theme.of(context).textTheme.headlineSmall),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _pinController,
            decoration: InputDecoration(
              labelText: 'PIN',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.lock_outline),
            ),
            obscureText: true,
            keyboardType: TextInputType.number,
          ),
          if (_isBlocked)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'You are blocked. Try again in ${_unblockTime.difference(DateTime.now()).inMinutes} minutes.',
                style: TextStyle(color: Colors.red),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
        ),
        ElevatedButton(
          onPressed: _isBlocked ? null : _checkPin,
          child: Text('Enter'),
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white, backgroundColor: Theme.of(context).primaryColor,
          ),
        ),
      ],
    );
  }
}
