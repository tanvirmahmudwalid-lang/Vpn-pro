import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:animate_do/animate_do.dart';
import '../models/server_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/ad_service.dart';
import '../services/vpn_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final AdService _adService = AdService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  UserProfile? _userProfile;
  List<Server> _servers = [];
  Server _selectedServer = Server(
    id: 'auto',
    name: 'Global Network',
    country: 'Auto',
    flag: '🌍',
    ip: '0.0.0.0',
    isPro: false,
    category: 'Recommended',
  );

  bool _isConnected = false;
  bool _isConnecting = false;
  int _remainingTime = 0;
  Timer? _timer;
  
  double _downloadSpeed = 0;
  double _uploadSpeed = 0;
  int _ping = 0;
  Timer? _statsTimer;

  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;
  int _adsWatchedCount = 0;
  bool _isWatchingAd = false;

  @override
  void initState() {
    super.initState();
    _initAuth();
    _adService.loadInterstitialAd();
  }

  void _initAuth() {
    _authService.authStateChanges.listen((user) {
      setState(() => _user = user);
      if (user != null) {
        _initUserProfile(user.uid);
        _initServers();
      }
    });
  }

  void _initUserProfile(String uid) {
    _firestore.collection('users').doc(uid).snapshots().listen((doc) {
      if (doc.exists) {
        setState(() {
          _userProfile = UserProfile.fromFirestore(doc);
          _remainingTime = _userProfile!.sessionTimeRemaining;
        });
        if (_userProfile!.isPro || _userProfile!.isPremium) {
          _isBannerAdLoaded = false;
          _bannerAd?.dispose();
        } else {
          _loadBannerAd();
        }
      }
    });
  }

  void _initServers() {
    _firestore.collection('servers').snapshots().listen((snapshot) {
      setState(() {
        _servers = snapshot.docs.map((doc) => Server.fromFirestore(doc)).toList();
      });
    });
  }

  void _loadBannerAd() {
    if (_userProfile?.isPro == true || _userProfile?.isPremium == true) return;
    _bannerAd = _adService.createBannerAd(() => setState(() => _isBannerAdLoaded = true));
  }

  void _handleTimeBoost() {
    if (_userProfile?.isPro == true || _userProfile?.isPremium == true) return;

    setState(() {
      _isWatchingAd = true;
      _adsWatchedCount = 0;
    });

    _playAdSequence();
  }

  void _playAdSequence() {
    _adService.loadRewardedAd(() {
      setState(() => _adsWatchedCount++);
      if (_adsWatchedCount < 3) {
        Future.delayed(const Duration(seconds: 1), _playAdSequence);
      } else {
        setState(() {
          _isWatchingAd = false;
          _remainingTime += 7200; // 2 hours
        });
        _syncSessionTime();
      }
    }, () {
      setState(() => _isWatchingAd = false);
    });
  }

  void _syncSessionTime() {
    if (_user != null) {
      _firestore.collection('users').doc(_user!.uid).update({
        'sessionTimeRemaining': _remainingTime,
      });
    }
  }

  void _toggleConnection() async {
    if (_isConnected) {
      _disconnect();
    } else {
      _connect();
    }
  }

  void _connect() async {
    setState(() => _isConnecting = true);

    // 1. Prepare VPN (Native Permission)
    final bool prepared = await VpnProvider.prepare();
    if (!prepared) {
      setState(() => _isConnecting = false);
      return;
    }

    Server target = _selectedServer;
    if (target.id == 'auto') {
      final freeServers = _servers.where((s) => !s.isPro).toList();
      if (freeServers.isNotEmpty) {
        target = freeServers[Random().nextInt(freeServers.length)];
      }
    }

    if (target.isPro && !(_userProfile?.isPro ?? false)) {
      setState(() => _isConnecting = false);
      _showPremiumRequired();
      return;
    }

    // 2. Start Native VPN Service
    final bool started = await VpnProvider.startVpn();
    if (!started) {
      setState(() => _isConnecting = false);
      return;
    }

    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _isConnecting = false;
        _isConnected = true;
        if (_remainingTime == 0 && !(_userProfile?.isPro ?? false)) {
          _remainingTime = 360; // 6 minutes
          _syncSessionTime();
        }
      });
      _startTimers();
    });
  }

  void _disconnect() async {
    await VpnProvider.stopVpn();
    setState(() {
      _isConnected = false;
      _stopTimers();
    });
    if (!(_userProfile?.isPro ?? false)) {
      _adService.showInterstitialAd();
    }
  }

  void _startTimers() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime > 0 && !(_userProfile?.isPro ?? false)) {
        setState(() => _remainingTime--);
        if (_remainingTime % 30 == 0) _syncSessionTime();
        if (_remainingTime == 0) _disconnect();
      }
    });

    _statsTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      setState(() {
        _downloadSpeed = (_userProfile?.isPro ?? false ? 12500 : 1200) + (Random().nextDouble() * 500 - 250);
        _uploadSpeed = (_userProfile?.isPro ?? false ? 4500 : 400) + (Random().nextDouble() * 100 - 50);
        _ping = Random().nextInt(20) + 10;
      });
    });
  }

  void _stopTimers() {
    _timer?.cancel();
    _statsTimer?.cancel();
    setState(() {
      _downloadSpeed = 0;
      _uploadSpeed = 0;
      _ping = 0;
    });
  }

  void _showPremiumRequired() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 64),
            const SizedBox(height: 16),
            const Text('Premium Required', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('This server is only available for Pro users.', textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF005F8A),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('GO PRO NOW'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildDrawer(),
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                _buildStats(),
                const Spacer(),
                _buildConnectButton(),
                const Spacer(),
                _buildServerSelector(),
                if (_isBannerAdLoaded) _buildBanner(),
              ],
            ),
          ),
          if (_isWatchingAd) _buildAdOverlay(),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF005F8A), Color(0xFF003D5B)],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Builder(builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          )),
          const Text('Btaf Meet', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          IconButton(
            icon: const Icon(Icons.star, color: Colors.amber),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem(Icons.group, '${(_downloadSpeed / 1024).toStringAsFixed(1)} K', 'Active Users'),
          _statItem(Icons.work, '${(_uploadSpeed / 1024).toStringAsFixed(1)} K', 'Jobs Available'),
          _statItem(Icons.connect_without_contact, '$_ping ms', 'Network Latency'),
        ],
      ),
    );
  }

  Widget _statItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
      ],
    );
  }

  Widget _buildConnectButton() {
    return Column(
      children: [
        GestureDetector(
          onTap: _isConnecting ? null : _toggleConnection,
          child: Pulse(
            animate: _isConnected,
            infinite: true,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
                border: Border.all(color: Colors.white24, width: 2),
              ),
              child: Center(
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isConnected ? Colors.green : Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: (_isConnected ? Colors.green : Colors.white).withOpacity(0.3),
                        blurRadius: 30,
                        spreadRadius: 10,
                      )
                    ],
                  ),
                  child: Icon(
                    Icons.power_settings_new,
                    size: 64,
                    color: _isConnected ? Colors.white : const Color(0xFF005F8A),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          _isConnecting ? 'SEARCHING...' : (_isConnected ? 'MEETING ACTIVE' : 'START MEETING'),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        if (_isConnected && !(_userProfile?.isPro ?? false))
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              _formatTime(_remainingTime),
              style: const TextStyle(color: Colors.amber, fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }

  String _formatTime(int seconds) {
    int m = seconds ~/ 60;
    int s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Widget _buildServerSelector() {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Text(_selectedServer.flag, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_selectedServer.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text(_selectedServer.country, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Colors.white),
            onPressed: _showServerList,
          ),
        ],
      ),
    );
  }

  void _showServerList() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            const SizedBox(height: 16),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const Padding(
              padding: EdgeInsets.all(24.0),
              child: Text('Select Category', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: _servers.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _serverTile(Server(id: 'auto', name: 'Global Network', country: 'Auto', flag: '🌍', ip: '0.0.0.0', isPro: false));
                  }
                  return _serverTile(_servers[index - 1]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _serverTile(Server server) {
    return ListTile(
      leading: Text(server.flag, style: const TextStyle(fontSize: 24)),
      title: Text(server.name, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(server.country),
      trailing: server.isPro ? const Icon(Icons.star, color: Colors.amber) : null,
      onTap: () {
        setState(() => _selectedServer = server);
        Navigator.pop(context);
      },
    );
  }

  Widget _buildBanner() {
    return SizedBox(
      height: 50,
      child: AdWidget(ad: _bannerAd!),
    );
  }

  Widget _buildAdOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.9),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.blue),
            const SizedBox(height: 32),
            const Text('WATCHING ADS', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Please watch all 3 ads to unlock 2 hours.', style: TextStyle(color: Colors.white54)),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [1, 2, 3].map((i) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _adsWatchedCount >= i ? Colors.blue : Colors.white10,
                ),
                child: Center(child: Text('$i', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF005F8A)),
            accountName: Text(_user?.displayName ?? 'Guest'),
            accountEmail: Text(_user?.email ?? 'Sign in to sync data'),
            currentAccountPicture: CircleAvatar(
              backgroundImage: _user?.photoURL != null ? NetworkImage(_user!.photoURL!) : null,
              child: _user?.photoURL == null ? const Icon(Icons.person) : null,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.timer),
            title: const Text('Add 2 Hours'),
            onTap: () {
              Navigator.pop(context);
              _handleTimeBoost();
            },
          ),
          ListTile(
            leading: const Icon(Icons.shield),
            title: const Text('Privacy Policy'),
            onTap: () {},
          ),
          const Spacer(),
          if (_user == null)
            ListTile(
              leading: const Icon(Icons.login),
              title: const Text('Sign In with Google'),
              onTap: () => _authService.signInWithGoogle(),
            )
          else
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign Out'),
              onTap: () => _authService.signOut(),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
