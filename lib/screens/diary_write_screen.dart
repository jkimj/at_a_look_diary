import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/diary.dart';
import '../models/couple_entry.dart';
import '../models/emotion.dart';
import '../models/diary_space.dart';
import '../services/diary_service.dart';
import '../services/auth_service.dart';

class DiaryWriteScreen extends StatefulWidget {
  final DateTime date;
  final Diary? existingDiary;
  final CoupleEntry? existingEntry; // 커플 엔트리 수정용
  final DiarySpace currentSpace;
  final String? coupleId;

  const DiaryWriteScreen({
    super.key,
    required this.date,
    this.existingDiary,
    this.existingEntry,
    this.currentSpace = DiarySpace.personal,
    this.coupleId,
  });

  @override
  State<DiaryWriteScreen> createState() => _DiaryWriteScreenState();
}

class _DiaryWriteScreenState extends State<DiaryWriteScreen> with SingleTickerProviderStateMixin {
  final DiaryService _diaryService = DiaryService();
  final AuthService _authService = AuthService();
  final TextEditingController _textController = TextEditingController();

  String? _existingSharedImageUrl; // 커플 공통 이미지 URL

  String? _selectedEmotion;
  String? _selectedEmotionColor;
  File? _selectedImage;
  bool _isSaving = false;
  bool _showEmotionPicker = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // 개인 일기 수정
    if (widget.existingDiary != null) {
      _textController.text = widget.existingDiary!.text;
      _selectedEmotion = widget.existingDiary!.emotion;
      _selectedEmotionColor = widget.existingDiary!.emotionColor;
    }

    // 커플 일기 수정
    if (widget.existingEntry != null) {
      _textController.text = widget.existingEntry!.text;
      _selectedEmotion = widget.existingEntry!.emotion;
      _selectedEmotionColor = widget.existingEntry!.emotionColor;

      // 커플 일기의 공통 이미지 로드
      _loadSharedImage();
    }

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _animationController.forward();
  }

  Future<void> _loadSharedImage() async {
    if (widget.coupleId == null) return;

    String dateStr = '${widget.date.year}-${widget.date.month.toString().padLeft(2, '0')}-${widget.date.day.toString().padLeft(2, '0')}';
    final coupleDiary = await _diaryService.loadCoupleDiary(widget.coupleId!, dateStr);

    if (coupleDiary != null && coupleDiary.sharedImageUrl.isNotEmpty) {
      setState(() {
        _existingSharedImageUrl = coupleDiary.sharedImageUrl;
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  String _formatDisplayDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _takePicture() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _saveDiary() async {
    if (_selectedEmotion == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('감정을 선택해주세요'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('내용을 입력해주세요'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      String? userId = _authService.getCurrentUserId();
      if (userId == null) {
        throw Exception('로그인이 필요합니다');
      }

      bool success;

      if (widget.currentSpace == DiarySpace.couple && widget.coupleId != null) {
        // 커플 일기 저장 (내 엔트리만)
        success = await _diaryService.saveCoupleDiary(
          widget.coupleId!,
          userId,
          widget.date,
          _selectedEmotion!,
          _selectedEmotionColor!,
          _textController.text.trim(),
        );

        // 공통 이미지 업로드 (선택한 경우)
        if (success && _selectedImage != null) {
          String dateStr = '${widget.date.year}-${widget.date.month.toString().padLeft(2, '0')}-${widget.date.day.toString().padLeft(2, '0')}';
          await _diaryService.uploadSharedImage(
            widget.coupleId!,
            dateStr,
            _selectedImage!,
          );
        }
      } else {
        // 개인 일기 저장
        String existingImageUrl = widget.existingDiary?.imageUrl ?? '';

        Diary diary = Diary(
          diaryId: widget.existingDiary?.diaryId ?? '',
          emotion: _selectedEmotion!,
          emotionColor: _selectedEmotionColor!,
          text: _textController.text.trim(),
          imageUrl: existingImageUrl,
          timestamp: widget.date.millisecondsSinceEpoch,
        );

        success = await _diaryService.saveDiary(
          userId,
          widget.date,
          diary,
          _selectedImage,
        );
      }

      if (mounted && success) {
        Navigator.pop(context, true);
      } else if (mounted && !success) {
        throw Exception('저장에 실패했습니다');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Color? _getSelectedEmotionColor() {
    if (_selectedEmotionColor != null) {
      return Color(int.parse(_selectedEmotionColor!.replaceFirst('#', '0xFF')));
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // 상단 헤더
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 28, color: Color(0xFF424242)),
                        onPressed: () => Navigator.pop(context),
                        style: IconButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      Column(
                        children: [
                          Text(
                            _formatDisplayDate(widget.date),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF212121),
                              letterSpacing: -0.2,
                            ),
                          ),
                          if (widget.currentSpace == DiarySpace.couple)
                            Text(
                              '커플 일기',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.pink[400],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.check_rounded,
                          size: 28,
                          color: _isSaving ? Colors.grey : const Color(0xFFB39DDB),
                        ),
                        onPressed: _isSaving ? null : _saveDiary,
                        style: IconButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 본문
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 감정 선택 표시
                        if (_selectedEmotion != null)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _getSelectedEmotionColor()?.withOpacity(0.15) ?? Colors.grey[100],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: _getSelectedEmotionColor(),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.sentiment_satisfied,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _selectedEmotion!,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 20),

                        // 이미지
                        if (_selectedImage != null ||
                            (widget.existingDiary?.imageUrl.isNotEmpty ?? false) ||
                            (_existingSharedImageUrl?.isNotEmpty ?? false))
                          Container(
                            margin: const EdgeInsets.only(bottom: 20),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: _selectedImage != null
                                      ? Image.file(
                                    _selectedImage!,
                                    width: double.infinity,
                                    height: 250,
                                    fit: BoxFit.cover,
                                  )
                                      : Image.network(
                                    widget.existingDiary?.imageUrl ?? _existingSharedImageUrl ?? '',
                                    width: double.infinity,
                                    height: 250,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _selectedImage = null;
                                      });
                                    },
                                    icon: const Icon(Icons.close, color: Colors.white),
                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.black.withOpacity(0.5),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // 이미지 추가 버튼
                        if (_selectedImage == null &&
                            (widget.existingDiary?.imageUrl.isEmpty ?? true) &&
                            (_existingSharedImageUrl?.isEmpty ?? true))
                          GestureDetector(
                            onTap: _showImagePicker,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 20),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate, color: Colors.grey[600]),
                                  const SizedBox(width: 8),
                                  Text(
                                    widget.currentSpace == DiarySpace.couple
                                        ? '공통 이미지 추가'
                                        : '이미지 추가',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.grey[700],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // 텍스트 입력
                        TextField(
                          controller: _textController,
                          maxLines: null,
                          minLines: 10,
                          decoration: InputDecoration(
                            hintText: widget.currentSpace == DiarySpace.couple
                                ? '오늘의 이야기를 적어보세요\n(파트너도 각자 작성할 수 있어요)'
                                : '오늘의 이야기를 적어보세요',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            hintStyle: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[400],
                              height: 1.6,
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // 플로팅 감정 선택 버튼
            Positioned(
              bottom: 24,
              right: 24,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // 감정 선택 목록
                  if (_showEmotionPicker)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      constraints: const BoxConstraints(maxWidth: 280),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 12),
                            child: Text(
                              '오늘의 감정',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          ...EmotionData.defaultEmotions.map((emotion) {
                            bool isSelected = _selectedEmotion == emotion['name'];
                            Color emotionColor = Color(
                              int.parse(emotion['color']!.replaceFirst('#', '0xFF')),
                            );

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedEmotion = emotion['name'];
                                    _selectedEmotionColor = emotion['color'];
                                    _showEmotionPicker = false;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? emotionColor
                                        : emotionColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected
                                          ? emotionColor
                                          : emotionColor.withOpacity(0.3),
                                      width: isSelected ? 2 : 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        emotion['icon']!,
                                        style: const TextStyle(fontSize: 22),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        emotion['name']!,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                          color: isSelected ? Colors.grey[800] : Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),

                  // 메인 감정 버튼
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showEmotionPicker = !_showEmotionPicker;
                      });
                    },
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _getSelectedEmotionColor() != null
                              ? [
                            _getSelectedEmotionColor()!,
                            _getSelectedEmotionColor()!.withOpacity(0.8),
                          ]
                              : [
                            const Color(0xFFB39DDB),
                            const Color(0xFF9575CD),
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (_getSelectedEmotionColor() ?? const Color(0xFFB39DDB))
                                .withOpacity(0.4),
                            blurRadius: 16,
                            spreadRadius: 2,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Icon(
                        _showEmotionPicker ? Icons.close_rounded : Icons.mood_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              if (widget.currentSpace == DiarySpace.couple)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Text(
                    '💕 공통 이미지는 두 사람 모두에게 표시됩니다',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.pink[400],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.photo_library_rounded, color: Colors.blue[700], size: 24),
                ),
                title: const Text('갤러리에서 선택', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage();
                },
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.camera_alt_rounded, color: Colors.green[700], size: 24),
                ),
                title: const Text('카메라로 촬영', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  _takePicture();
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}