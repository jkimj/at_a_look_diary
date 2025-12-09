import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';
import '../services/couple_service.dart';

class SettingsScreen extends StatefulWidget {
  final bool openCoupleMode;

  const SettingsScreen({super.key, this.openCoupleMode = false});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();
  final CoupleService _coupleService = CoupleService();

  bool _coupleModeEnabled = false;
  bool _isCheckingCoupleStatus = true;
  String? _partnerId;
  bool _notificationsEnabled = true;
  bool _dailyReminderEnabled = false;
  String _selectedTheme = 'system';

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _checkCoupleStatus();

    if (widget.openCoupleMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          250,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _checkCoupleStatus() async {
    final userId = _authService.getCurrentUserId();
    if (userId != null) {
      final isConnected = await _coupleService.isCoupleConnected(userId);
      if (isConnected) {
        final partnerId = await _coupleService.getPartnerId(userId);
        setState(() {
          _coupleModeEnabled = true;
          _partnerId = partnerId;
          _isCheckingCoupleStatus = false;
        });
      } else {
        setState(() {
          _coupleModeEnabled = false;
          _partnerId = null;
          _isCheckingCoupleStatus = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('설정'),
      ),
      body: _isCheckingCoupleStatus
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // 계정 정보
          _buildSection(
            title: '계정',
            children: [
              _buildAccountCard(),
            ],
          ),

          // 커플 모드
          _buildSection(
            title: '커플 모드',
            children: [
              _buildCoupleModeCard(),
            ],
          ),

          // 알림 설정
          _buildSection(
            title: '알림',
            children: [
              _buildListTile(
                icon: Icons.notifications_outlined,
                iconColor: Colors.blue,
                title: '알림',
                subtitle: '새로운 소식을 받아보세요',
                trailing: Switch(
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      _notificationsEnabled = value;
                    });
                  },
                  activeColor: const Color(0xFF2196F3),
                ),
              ),
              if (_notificationsEnabled) ...[
                const Divider(height: 1),
                _buildListTile(
                  icon: Icons.alarm,
                  iconColor: Colors.orange,
                  title: '일일 알림',
                  subtitle: '매일 저녁 9시에 알림을 받아요',
                  trailing: Switch(
                    value: _dailyReminderEnabled,
                    onChanged: (value) {
                      setState(() {
                        _dailyReminderEnabled = value;
                      });
                      if (value) {
                        _showDailyReminderDialog();
                      }
                    },
                    activeColor: const Color(0xFF2196F3),
                  ),
                ),
              ],
            ],
          ),

          // 데이터 관리
          _buildSection(
            title: '데이터',
            children: [
              _buildListTile(
                icon: Icons.backup_outlined,
                iconColor: Colors.green,
                title: '백업 및 복원',
                subtitle: '데이터를 안전하게 보관하세요',
                trailing: const Icon(Icons.chevron_right, color: Color(0xFF9E9E9E)),
                onTap: _showBackupOptions,
              ),
              const Divider(height: 1),
              _buildListTile(
                icon: Icons.download_outlined,
                iconColor: Colors.purple,
                title: '데이터 내보내기',
                subtitle: 'JSON 형식으로 다운로드',
                trailing: const Icon(Icons.chevron_right, color: Color(0xFF9E9E9E)),
                onTap: _exportData,
              ),
            ],
          ),

          // 테마 설정
          _buildSection(
            title: '화면',
            children: [
              _buildListTile(
                icon: Icons.palette_outlined,
                iconColor: Colors.pink,
                title: '테마',
                subtitle: _getThemeText(),
                trailing: const Icon(Icons.chevron_right, color: Color(0xFF9E9E9E)),
                onTap: _showThemeDialog,
              ),
            ],
          ),

          // 지원
          _buildSection(
            title: '지원',
            children: [
              _buildListTile(
                icon: Icons.share_outlined,
                iconColor: Colors.blue,
                title: '앱 공유하기',
                trailing: const Icon(Icons.chevron_right, color: Color(0xFF9E9E9E)),
                onTap: _shareApp,
              ),
              const Divider(height: 1),
              _buildListTile(
                icon: Icons.star_outline,
                iconColor: Colors.amber,
                title: '앱 평가하기',
                trailing: const Icon(Icons.chevron_right, color: Color(0xFF9E9E9E)),
                onTap: _rateApp,
              ),
              const Divider(height: 1),
              _buildListTile(
                icon: Icons.bug_report_outlined,
                iconColor: Colors.red,
                title: '문제 신고',
                trailing: const Icon(Icons.chevron_right, color: Color(0xFF9E9E9E)),
                onTap: _reportBug,
              ),
            ],
          ),

          // 정보
          _buildSection(
            title: '정보',
            children: [
              _buildListTile(
                icon: Icons.info_outline,
                iconColor: Colors.grey,
                title: '앱 정보',
                subtitle: '버전 1.0.0',
                trailing: const Icon(Icons.chevron_right, color: Color(0xFF9E9E9E)),
                onTap: _showAboutDialog,
              ),
              const Divider(height: 1),
              _buildListTile(
                icon: Icons.description_outlined,
                iconColor: Colors.blueGrey,
                title: '이용약관',
                trailing: const Icon(Icons.chevron_right, color: Color(0xFF9E9E9E)),
                onTap: () => _openUrl('https://example.com/terms'),
              ),
              const Divider(height: 1),
              _buildListTile(
                icon: Icons.privacy_tip_outlined,
                iconColor: Colors.deepPurple,
                title: '개인정보 처리방침',
                trailing: const Icon(Icons.chevron_right, color: Color(0xFF9E9E9E)),
                onTap: () => _openUrl('https://example.com/privacy'),
              ),
            ],
          ),

          // 로그아웃
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _showLogoutDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[50],
                foregroundColor: Colors.red[700],
                elevation: 0,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('로그아웃'),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: Color(0xFFE0E0E0), width: 1),
              bottom: BorderSide(color: Color(0xFFE0E0E0), width: 1),
            ),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey[600],
        ),
      )
          : null,
      trailing: trailing,
      onTap: onTap,
    );
  }

  Widget _buildAccountCard() {
    final user = _authService.getCurrentUser();
    final isAnonymous = _authService.isAnonymous();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFB39DDB).withOpacity(0.8),
            const Color(0xFF9575CD).withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFB39DDB).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              isAnonymous ? Icons.person_outline : Icons.person,
              color: const Color(0xFFB39DDB),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAnonymous ? '익명 사용자' : (user?.email ?? '사용자'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isAnonymous ? '게스트 모드' : 'Google 계정',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoupleModeCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _coupleModeEnabled
              ? [
            Colors.pink[300]!,
            Colors.pink[400]!,
          ]
              : [
            Colors.grey[100]!,
            Colors.grey[200]!,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: _coupleModeEnabled
            ? [
          BoxShadow(
            color: Colors.pink.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _coupleModeEnabled ? Colors.white : Colors.pink[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.favorite,
                  color: _coupleModeEnabled ? Colors.pink : Colors.pink[300],
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '커플 모드',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _coupleModeEnabled ? Colors.white : Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _coupleModeEnabled ? '파트너와 연결됨' : '일기를 함께 공유해요',
                      style: TextStyle(
                        fontSize: 13,
                        color: _coupleModeEnabled ? Colors.white.withOpacity(0.9) : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _coupleModeEnabled,
                onChanged: (value) {
                  if (value) {
                    _showCoupleConnectFlow();
                  } else {
                    _showDisconnectDialog();
                  }
                },
                activeColor: Colors.white,
                activeTrackColor: Colors.pink[200],
              ),
            ],
          ),
          if (_coupleModeEnabled && _partnerId != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '두 사람이 함께 쓰는 일기장 💕',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getThemeText() {
    switch (_selectedTheme) {
      case 'light':
        return '라이트 모드';
      case 'dark':
        return '다크 모드';
      default:
        return '시스템 설정';
    }
  }

  // 커플 연결 플로우
  void _showCoupleConnectFlow() {
    showDialog(
      context: context,
      builder: (context) => _CoupleConnectDialog(
        coupleService: _coupleService,
        authService: _authService,
        onSuccess: () {
          _checkCoupleStatus();
          Navigator.pop(context);
          _showSuccessDialog();
        },
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.celebration, color: Colors.pink[400], size: 28),
            const SizedBox(width: 12),
            const Text('매칭 성공!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite, color: Colors.pink, size: 64),
            const SizedBox(height: 16),
            const Text(
              '이제 두 사람이 함께 쓰는\n일기장이 열렸어요! ✨',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink,
              minimumSize: const Size(double.infinity, 45),
            ),
            child: const Text('시작하기'),
          ),
        ],
      ),
    );
  }

  void _showDisconnectDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('커플 모드 해제'),
        content: const Text('파트너와의 연결을 해제하시겠습니까?\n\n해제하면 두 사람의 일기가 더 이상 공유되지 않습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final userId = _authService.getCurrentUserId();
              if (userId != null) {
                try {
                  await _coupleService.disconnectCouple(userId);
                  _checkCoupleStatus();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('연결이 해제되었습니다')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('오류: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('해제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showDailyReminderDialog() {
    showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 21, minute: 0),
    ).then((time) {
      if (time != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('매일 ${time.format(context)}에 알림을 받습니다')),
        );
      }
    });
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('테마 선택'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('시스템 설정'),
              value: 'system',
              groupValue: _selectedTheme,
              onChanged: (value) {
                setState(() => _selectedTheme = value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('라이트 모드'),
              value: 'light',
              groupValue: _selectedTheme,
              onChanged: (value) {
                setState(() => _selectedTheme = value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('다크 모드'),
              value: 'dark',
              groupValue: _selectedTheme,
              onChanged: (value) {
                setState(() => _selectedTheme = value!);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showBackupOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.cloud_upload, color: Colors.blue[700]),
              ),
              title: const Text('백업하기'),
              subtitle: const Text('데이터를 클라우드에 저장'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('백업 완료!')),
                );
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.cloud_download, color: Colors.green[700]),
              ),
              title: const Text('복원하기'),
              subtitle: const Text('저장된 데이터 불러오기'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('복원 완료!')),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _exportData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('데이터 내보내기'),
        content: const Text('모든 일기 데이터를 JSON 파일로 내보내시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('데이터 내보내기가 완료되었습니다')),
              );
            },
            child: const Text('내보내기'),
          ),
        ],
      ),
    );
  }

  void _shareApp() {
    Share.share('한 눈에 보는 일기장 - 감정을 기록하는 가장 쉬운 방법\nhttps://example.com/app');
  }

  void _rateApp() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('스토어로 이동합니다...')),
    );
  }

  void _reportBug() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('문제 신고 기능은 준비 중입니다')),
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: '한 눈에 보는 일기장',
      applicationVersion: '1.0.0',
      applicationLegalese: '© 2025 Team 2\n이예린, 김재이, 김아리',
      applicationIcon: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: Colors.blue[100],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.book, size: 32, color: Colors.blue[700]),
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('로그아웃 하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              await _authService.signOut();
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
            child: const Text('로그아웃', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// 커플 연결 다이얼로그
class _CoupleConnectDialog extends StatefulWidget {
  final CoupleService coupleService;
  final AuthService authService;
  final VoidCallback onSuccess;

  const _CoupleConnectDialog({
    required this.coupleService,
    required this.authService,
    required this.onSuccess,
  });

  @override
  State<_CoupleConnectDialog> createState() => _CoupleConnectDialogState();
}

class _CoupleConnectDialogState extends State<_CoupleConnectDialog> {
  int _step = 0; // 0: 안내, 1: 코드생성, 2: 코드입력
  String? _generatedCode;
  bool _isLoading = false;
  final TextEditingController _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_step == 0) _buildIntroStep(),
            if (_step == 1) _buildCodeGenerationStep(),
            if (_step == 2) _buildCodeInputStep(),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.favorite, color: Colors.pink[300], size: 64),
        const SizedBox(height: 20),
        const Text(
          '연결하고 싶은 사람과\n일기를 공유해볼까요?',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '커플 모드를 활성화하면\n두 사람의 일기를 함께 볼 수 있어요',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            height: 1.5,
          ),
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _step = 2),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: Colors.grey[300]!),
                ),
                child: const Text('코드 입력'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _generateCode(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('코드 생성'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
      ],
    );
  }

  Widget _buildCodeGenerationStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.qr_code_2, color: Colors.pink[300], size: 64),
        const SizedBox(height: 20),
        const Text(
          '이 코드를 상대에게\n보내주세요',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.pink[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.pink[200]!, width: 2),
          ),
          child: Column(
            children: [
              Text(
                _generatedCode ?? '',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                  color: Colors.pink,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '24시간 동안 유효',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _generatedCode ?? ''));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('코드가 복사되었습니다')),
                  );
                },
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('복사'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Share.share('한 눈에 보는 일기장 커플 코드: ${_generatedCode ?? ''}\n\n앱에서 이 코드를 입력하면 일기를 함께 공유할 수 있어요!');
                },
                icon: const Icon(Icons.share, size: 18),
                label: const Text('공유'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('닫기'),
        ),
      ],
    );
  }

  Widget _buildCodeInputStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.vpn_key, color: Colors.pink[300], size: 64),
        const SizedBox(height: 20),
        const Text(
          '상대방의 코드를\n입력해주세요',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _codeController,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
          decoration: InputDecoration(
            hintText: 'A2B9-77LQ',
            hintStyle: TextStyle(
              color: Colors.grey[400],
              letterSpacing: 2,
            ),
            filled: true,
            fillColor: Colors.pink[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.pink[200]!, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.pink[200]!, width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.pink, width: 2),
            ),
          ),
          textCapitalization: TextCapitalization.characters,
          maxLength: 9, // A2B9-77LQ = 9자
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _connectWithCode,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: _isLoading
                ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
                : const Text('연결하기'),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => setState(() => _step = 0),
          child: const Text('뒤로'),
        ),
      ],
    );
  }

  Future<void> _generateCode() async {
    setState(() => _isLoading = true);

    try {
      final userId = widget.authService.getCurrentUserId();
      if (userId == null) throw Exception('로그인이 필요합니다');

      final code = await widget.coupleService.createCoupleCode(userId);

      setState(() {
        _generatedCode = code;
        _step = 1;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류: $e')),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _connectWithCode() async {
    final code = _codeController.text.trim().toUpperCase();

    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('코드를 입력해주세요')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = widget.authService.getCurrentUserId();
      if (userId == null) throw Exception('로그인이 필요합니다');

      await widget.coupleService.connectWithCode(userId, code);

      if (mounted) {
        widget.onSuccess();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }
}