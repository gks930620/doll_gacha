import 'dart:io';
import 'package:flutter/material.dart';
import '../models/community_model.dart';
import '../services/community_service.dart';
import '../services/file_service.dart';

/// 커뮤니티 글쓰기/수정 화면
class CommunityWriteScreen extends StatefulWidget {
  final Community? community; // null이면 새 글 작성, 있으면 수정

  const CommunityWriteScreen({super.key, this.community});

  @override
  State<CommunityWriteScreen> createState() => _CommunityWriteScreenState();
}

class _CommunityWriteScreenState extends State<CommunityWriteScreen> {
  final CommunityService _communityService = CommunityService();
  final FileService _fileService = FileService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isSubmitting = false;
  List<File> _selectedImages = [];
  static const int _maxImages = 5;

  bool get _isEditing => widget.community != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _titleController.text = widget.community!.title;
      _contentController.text =
          widget.community!.content.replaceAll(RegExp(r'<[^>]*>'), '');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  /// 이미지 선택
  Future<void> _pickImages() async {
    if (_selectedImages.length >= _maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('최대 $_maxImages개까지 첨부 가능합니다')),
      );
      return;
    }

    final images = await _fileService.pickMultipleImages(
      maxImages: _maxImages - _selectedImages.length,
    );

    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images);
        if (_selectedImages.length > _maxImages) {
          _selectedImages = _selectedImages.take(_maxImages).toList();
        }
      });
    }
  }

  /// 이미지 제거
  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    if (_isEditing) {
      // 수정
      final result = await _communityService.updateCommunity(
        widget.community!.id,
        CommunityUpdate(
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
        ),
      );

      setState(() => _isSubmitting = false);

      if (result.isSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('게시글이 수정되었습니다')),
          );
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result.error ?? '게시글 수정에 실패했습니다')),
          );
        }
      }
    } else {
      // 새 글 작성
      final result = await _communityService.createCommunity(
        CommunityCreate(
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
        ),
      );

      if (!result.isSuccess || result.data == null) {
        setState(() => _isSubmitting = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result.error ?? '게시글 작성에 실패했습니다')),
          );
        }
        return;
      }

      // 이미지 업로드
      if (_selectedImages.isNotEmpty) {
        final uploadResult = await _fileService.uploadFiles(
          files: _selectedImages,
          refId: result.data!,
          refType: 'COMMUNITY',
          usage: 'IMAGE',
        );

        if (!uploadResult.isSuccess) {
          debugPrint('이미지 업로드 실패: ${uploadResult.error}');
        }
      }

      setState(() => _isSubmitting = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('게시글이 작성되었습니다')),
        );
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '게시글 수정' : '글쓰기'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _submit,
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    '완료',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // 제목
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: '제목을 입력하세요',
                contentPadding: EdgeInsets.all(16),
                border: InputBorder.none,
              ),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '제목을 입력해주세요';
                }
                return null;
              },
            ),
            const Divider(height: 1),
            // 내용
            Expanded(
              child: TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  hintText: '내용을 입력하세요 (최소 5자)',
                  contentPadding: EdgeInsets.all(16),
                  border: InputBorder.none,
                ),
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '내용을 입력해주세요';
                  }
                  if (value.trim().length < 5) {
                    return '5자 이상 입력해주세요';
                  }
                  return null;
                },
              ),
            ),
            // 이미지 첨부 영역
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '이미지 첨부 (${_selectedImages.length}/$_maxImages)',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      IconButton(
                        onPressed: _pickImages,
                        icon: const Icon(Icons.add_a_photo, color: Colors.deepPurple),
                      ),
                    ],
                  ),
                  if (_selectedImages.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _selectedImages.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    _selectedImages[index],
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: GestureDetector(
                                    onTap: () => _removeImage(index),
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
