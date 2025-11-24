import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:audioplayers/audioplayers.dart';
import 'services/NearbyReceiverService .dart';
import 'services/socket_service.dart';
import 'GlobalCls/GLobalClass.dart' as Glb;

class MasjidApp extends StatefulWidget {
  const MasjidApp({super.key});

  @override
  State<MasjidApp> createState() => _MasjidAppState();
}

class _MasjidAppState extends State<MasjidApp> {
  String serverResponse = '';

  final SocketService socketService = SocketService();
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Masjid Info Display',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.green),
      home: const MasjidInfoScreen(),
    );
  }
}

class MasjidInfoScreen extends StatefulWidget {
  const MasjidInfoScreen({super.key});

  @override
  State<MasjidInfoScreen> createState() => _MasjidInfoScreenState();
}

class _MasjidInfoScreenState extends State<MasjidInfoScreen> {
  late NearbyReceiverService _receiverService;
  late Timer _timer;
  String _currentTime = '';
  String _nextEvent = 'Next: Fajr - Azan at 04:30 AM';

  final ScrollController _topController = ScrollController();
  final ScrollController _bottomController = ScrollController();
  late Timer _scrollTimer;
  String serverResponse = '';

  final SocketService socketService = SocketService();

  final String _topMessage =
      '📢 Important: Today’s bayan after Isha. Please attend on time.   ';
  final String _bottomMessage =
      '🕌 Jumma khutbah starts at 2:15 PM. Please arrive early.   ';

  List<Map<String, String>> _namazTimes = [
    {
      'name': 'Fajr',
      'azan': '04:30 AM',
      'jamat': '04:50 AM',
      'akhri': '05:10 AM'
    },
    {
      'name': 'Zohar',
      'azan': '01:15 PM',
      'jamat': '01:30 PM',
      'akhri': '01:50 PM'
    },
    {
      'name': 'Asr',
      'azan': '05:15 PM',
      'jamat': '05:30 PM',
      'akhri': '05:50 PM'
    },
    {
      'name': 'Maghrib',
      'azan': '06:45 PM',
      'jamat': '06:50 PM',
      'akhri': '07:10 PM'
    },
    {
      'name': 'Isha',
      'azan': '08:15 PM',
      'jamat': '08:30 PM',
      'akhri': '08:50 PM'
    },
    {
      'name': 'Juma',
      'azan': '01:15 PM',
      'jamat': '02:30 PM',
      'akhri': '03:00 PM'
    },
  ];

  final List<String> _videoMessages = [
    'Welcome to Masjid-e-Noumania!',
    'Join us for daily Quran dars after Maghrib.',
    'Please maintain silence and respect in the Masjid.',
  ];

  int _currentVideoMessageIndex = 0;
  String _typedMessage = '';
  int _charIndex = 0;
  Timer? _typingTimer;

  final AudioPlayer _audioPlayer = AudioPlayer();
  final Map<String, bool> _playedAzanToday = {};

  @override
  void initState() {
    super.initState();
    loginFuture();

    _receiverService = NearbyReceiverService(
      onMessageReceived: _onMessageReceived,
    );
    _receiverService.initialize();

    _startScrolling();
    _updateTime();
    _startTypingAnimation();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }

  Future<String> loginFuture() async {
    try {
      String query = "select uid , username , phone from mconnect.admintbl;";
      print("Query is $query");

      String response25 =
          await socketService.sendMessage(Glb.ip, Glb.port, query, 709);

      print("Raw response in loginFuture async: $response25");

      setState(() {
        serverResponse = response25;
      });
    } catch (e, stackTrace) {
      print("Error in loginFuture: $e");
      print("Stack Trace: $stackTrace");
    }
    return "Exit";
  }

  void _onMessageReceived(String message) {
    setState(() {
      if (message.startsWith('FILE_RECEIVED:')) {
        final path = message.replaceFirst('FILE_RECEIVED:', '');
        try {
          final file = File(path);
          if (file.existsSync()) {
            final content = file.readAsStringSync();
            _videoMessages.insert(0, content);
          }
        } catch (e) {
          debugPrint('Failed to read file: $e');
        }
      } else {
        _videoMessages.insert(0, message);
      }

      // Immediately restart typing animation
      _typedMessage = '';
      _currentVideoMessageIndex = 0;
      _startTypingAnimation();
    });
  }

  void _startScrolling() {
    _scrollTimer = Timer.periodic(const Duration(milliseconds: 60), (_) {
      _scrollText(_topController);
      _scrollText(_bottomController);
    });
  }

  void _scrollText(ScrollController controller) {
    if (!controller.hasClients) return;
    double maxScroll = controller.position.maxScrollExtent;
    double currentScroll = controller.offset;
    double nextScroll = currentScroll + 1;
    if (nextScroll >= maxScroll) {
      controller.jumpTo(0);
    } else {
      controller.jumpTo(nextScroll);
    }
  }

  void _startTypingAnimation() {
    final message = _videoMessages[_currentVideoMessageIndex];
    _typedMessage = '';
    _charIndex = 0;

    _typingTimer?.cancel();
    _typingTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_charIndex < message.length) {
        setState(() {
          _typedMessage += message[_charIndex];
        });
        _charIndex++;
      } else {
        timer.cancel();
        Future.delayed(const Duration(seconds: 2), () {
          setState(() {
            _typedMessage = '';
          });
          Future.delayed(const Duration(milliseconds: 500), () {
            setState(() {
              _currentVideoMessageIndex =
                  (_currentVideoMessageIndex + 1) % _videoMessages.length;
            });
            _startTypingAnimation();
          });
        });
      }
    });
  }

  void _updateTime() {
    final now = DateTime.now();
    final formatter = DateFormat('hh:mm:ss a');
    _currentTime = formatter.format(now);

    _nextEvent = 'All Namaz completed for today';

    bool isFriday = now.weekday == DateTime.friday;

    for (var time in _namazTimes) {
      final name = time['name'] ?? '';

      // Skip Zohar on Friday and skip Juma on other days
      if ((isFriday && name == 'Zohar') || (!isFriday && name == 'Juma')) {
        continue;
      }

      final azanTime = DateFormat('hh:mm a').parse(time['azan'] ?? '');
      final azanToday = DateTime(
          now.year, now.month, now.day, azanTime.hour, azanTime.minute);

      if (now.isBefore(azanToday)) {
        final formattedAzan = DateFormat('hh:mm a').format(azanToday);
        _nextEvent = 'Next: $name - Azan at $formattedAzan';
        break;
      }
    }

    _checkAndPlayAudio(now);
    setState(() {});
  }

  void _checkAndPlayAudio(DateTime now) {
    final currentTimeStr = DateFormat('hh:mm a').format(now);
    bool isFriday = now.weekday == DateTime.friday;

    for (var time in _namazTimes) {
      final prayerName = time['name'] ?? '';
      final azanTime = time['azan'] ?? '';

      // Skip Zohar on Friday; Skip Juma on other days
      if ((isFriday && prayerName == 'Zohar') ||
          (!isFriday && prayerName == 'Juma')) {
        continue;
      }

      if (azanTime == currentTimeStr) {
        if (_playedAzanToday[prayerName] != true) {
          setState(() {
            _playedAzanToday[prayerName] = true;
          });

          try {
            _audioPlayer.play(AssetSource('Audio/Azan.mp3'));
            Timer(const Duration(minutes: 1), () {
              _audioPlayer.stop();
            });
          } catch (e) {
            debugPrint('Audio playback error: $e');
          }
        }
      }
    }

    // Reset tracking at midnight
    if (currentTimeStr == '12:00 AM') {
      _playedAzanToday.clear();
    }
  }

  @override
  void dispose() {
    _receiverService.stop();
    _timer.cancel();
    _scrollTimer.cancel();
    _typingTimer?.cancel();
    _topController.dispose();
    _bottomController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          toolbarHeight: 15, elevation: 0, backgroundColor: Colors.white),
      body: Column(
        children: [
          _marquee(_topMessage, _topController, 20),
          Expanded(
            child: Row(
              children: [
                Expanded(flex: 1, child: _buildLeftPanel()),
                Expanded(flex: 1, child: _buildRightPanel()),
              ],
            ),
          ),
          _marquee(_bottomMessage, _bottomController, 20),
        ],
      ),
    );
  }

  Widget _buildLeftPanel() {
    return LayoutBuilder(
      builder: (context, constraints) {
        double availableHeight = constraints.maxHeight;
        double baseFontSize = availableHeight / 35;

        return Container(
          padding: const EdgeInsets.all(8),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _headerCard(baseFontSize),
              SizedBox(height: baseFontSize * 0.5),
              _dateCard(baseFontSize),
              SizedBox(height: baseFontSize * 0.8),
              _buildTable(baseFontSize),
              SizedBox(height: baseFontSize * 0.5),
              _bottomRowWithMasjidName(baseFontSize),
            ],
          ),
        );
      },
    );
  }

  Widget _headerCard(double fontSize) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.green[100],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              _currentTime,
              style: TextStyle(
                  fontSize: fontSize + 20, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 6,
            child: Text(_nextEvent,
                style: TextStyle(
                    fontSize: fontSize + 5, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _dateCard(double fontSize) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(
              'Date: ${DateFormat('EEEE, d MMMM y').format(DateTime.now())}',
              style: TextStyle(
                  fontSize: fontSize + 2, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: 5,
            child: Text(
              'اردو تاریخ: 25 ذو الحجہ 1446',
              style: TextStyle(
                  fontSize: fontSize + 2, fontWeight: FontWeight.bold),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(double fontSize) {
    return Table(
      border: TableBorder.all(color: Colors.black),
      columnWidths: const {
        0: FlexColumnWidth(8),
        1: FlexColumnWidth(8),
        2: FlexColumnWidth(8),
        3: FlexColumnWidth(8),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        _tableRow('NAMAZ', 'AZAN', 'JAMAT', 'AKHARI-WAKT', fontSize,
            isHeader: true),
        ..._namazTimes.map(
          (t) => _tableRow(
              t['name']!, t['azan']!, t['jamat']!, t['akhri']!, fontSize),
        ),
      ],
    );
  }

  TableRow _tableRow(
      String name, String azan, String jamat, String akhriWaqt, double fontSize,
      {bool isHeader = false}) {
    final baseStyle = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
      color: isHeader ? Colors.black : Colors.green,
    );
    final nameStyle =
        baseStyle.copyWith(color: isHeader ? Colors.black : Colors.black);

    final akhriStyle =
        baseStyle.copyWith(color: isHeader ? Colors.black : Colors.red);

    return TableRow(
      children: [
        _buildCell(name, nameStyle),
        _buildCell(azan, baseStyle),
        _buildCell(jamat, baseStyle),
        _buildCell(akhriWaqt, akhriStyle),
      ],
    );
  }

  Widget _buildCell(String text, TextStyle style) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          vertical: 4, horizontal: 4), // Increased height
      child: Text(
        text,
        style: style,
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _bottomRowWithMasjidName(double fontSize) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SAHR   Time: 5:45',
                    style: TextStyle(
                        fontSize: fontSize - 2, fontWeight: FontWeight.bold)),
                Text('IFTAR  Time: 6:15',
                    style: TextStyle(
                        fontSize: fontSize - 2, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                'MASJID-E-NOUMANIA',
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize),
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('TULU   7:14',
                    style: TextStyle(
                        fontSize: fontSize - 2, fontWeight: FontWeight.bold)),
                Text('ZAWAL  12:46',
                    style: TextStyle(
                        fontSize: fontSize - 2, fontWeight: FontWeight.bold)),
                Text('GURUB  6:17',
                    style: TextStyle(
                        fontSize: fontSize - 2, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightPanel() {
    return LayoutBuilder(
      builder: (context, constraints) {
        double width = constraints.maxWidth;
        double fontSize = width < 350
            ? 12
            : width < 600
                ? 14
                : width < 900
                    ? 16
                    : 18;

        return Container(
          padding: const EdgeInsets.all(8),
          color: Colors.green[50],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'NOTIFICATIONS',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Container(
                  width: double.infinity,
                  color: Colors.green[100],
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    _typedMessage,
                    textAlign: TextAlign.center,
                    softWrap: true,
                    overflow: TextOverflow.visible,
                    maxLines: 10,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _marquee(String text, ScrollController controller, double fontSize) {
    return SizedBox(
      height: 25,
      child: ListView.builder(
        controller: controller,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            text,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
        ),
        itemCount: 50,
      ),
    );
  }
}
