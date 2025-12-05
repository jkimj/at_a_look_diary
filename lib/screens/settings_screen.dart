import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  final bool openCoupleMode;

  const SettingsScreen({super.key, this.openCoupleMode = false});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();
  bool _coupleModeEnabled = false;
  bool _notificationsEnabled = true;
  bool _dailyReminderEnabled = false;
  String _selectedTheme = 'system'; // system, light, dark

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // 커플 모드 섹션으로 자동 스크롤
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('설정'),
      ),
      body: ListView(
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
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
        subtitle,
        style: const TextStyle(fontSize: 13),
      )
          : null,
      trailing: trailing,
      onTap: onTap,
    );
  }

  Widget _buildAccountCard() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.blue[50],
            child: Icon(
              _authService.isAnonymous() ? Icons.person_outline : Icons.person,
              size: 36,
              color: Colors.blue[700],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _authService.isAnonymous()
                      ? '익명 사용자'
                      : _authService.getCurrentUser()?.email ?? '사용자',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _authService.isAnonymous()
                        ? Colors.grey[200]
                        : Colors.blue[50],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _authService.isAnonymous() ? '게스트' : 'Google',
                    style: TextStyle(
                      fontSize: 12,
                      color: _authService.isAnonymous()
                          ? Colors.grey[700]
                          : Colors.blue[700],
                      fontWeight: FontWeight.w600,
                    ),
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
    return Column(
      children: [
        _buildListTile(
          icon: Icons.favorite,
          iconColor: _coupleModeEnabled ? Colors.pink : Colors.grey,
          title: '커플 모드',
          subtitle: _coupleModeEnabled
              ? '연인과 함께 일기를 공유하고 있어요'
              : '연인과 일기를 공유해보세요',
          trailing: Switch(
            value: _coupleModeEnabled,
            onChanged: (value) {
              setState(() {
                _coupleModeEnabled = value;
              });
              if (value) {
                _showCoupleModeDialog();
              }
            },
            activeColor: Colors.pink,
          ),
        ),
        if (_coupleModeEnabled) ...[
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _showInvitePartnerDialog,
              icon: const Icon(Icons.person_add, size: 20),
              label: const Text('파트너 초대하기'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink[50],
                foregroundColor: Colors.pink[700],
                elevation: 0,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ),
        ],
      ],
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

  // 다이얼로그들
  void _showCoupleModeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.favorite, color: Colors.pink),
            SizedBox(width: 8),
            Text('커플 모드'),
          ],
        ),
        content: const Text(
          '커플 모드를 활성화하면 연인과 일기를 공유할 수 있어요.\n\n'
              '• 서로의 일기를 볼 수 있어요\n'
              '• 함께 작성한 추억을 기록해요\n'
              '• 상대방에게 하트를 보낼 수 있어요',
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _coupleModeEnabled = false;
              });
              Navigator.pop(context);
            },
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink,
            ),
            child: const Text('시작하기'),
          ),
        ],
      ),
    );
  }

  void _showInvitePartnerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('파트너 초대'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('초대 코드를 공유하거나\n상대방의 코드를 입력하세요'),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'ABC-123-XYZ',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('초대 코드가 복사되었습니다')),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                hintText: '상대방 초대 코드 입력',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('파트너 연결 기능은 준비 중입니다')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink,
            ),
            child: const Text('연결하기'),
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
                setState(() {
                  _selectedTheme = value!;
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('라이트 모드'),
              value: 'light',
              groupValue: _selectedTheme,
              onChanged: (value) {
                setState(() {
                  _selectedTheme = value!;
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('다크 모드'),
              value: 'dark',
              groupValue: _selectedTheme,
              onChanged: (value) {
                setState(() {
                  _selectedTheme = value!;
                });
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
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/login',
                      (route) => false,
                );
              }
            },
            child: const Text('로그아웃', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}