import 'dart:io';
import 'package:flutter/material.dart';
import '../models/review_model.dart';
import '../services/review_service.dart';
import '../services/file_service.dart';

/// 리뷰 작성 화면
class ReviewWriteScreen extends StatefulWidget {
  final int shopId;
  final String shopName;

  const ReviewWriteScreen({
    super.key,
    required this.shopId,
    required this.shopName,
  });

  @override
  State<ReviewWriteScreen> createState() => _ReviewWriteScreenState();
}

class _ReviewWriteScreenState extends State<ReviewWriteScreen> {
  final ReviewService _reviewService = ReviewService();
  final FileService _fileService = FileService();
  final TextEditingController _contentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  int _rating = 5;
  int _machineStrength = 3;
  int? _largeDollCost;
  int? _mediumDollCost;
  int? _smallDollCost;
  bool _isSubmitting = false;
  List<File> _selectedImages = [];
  static const int _maxImages = 3;

  @override
  void dispose() {
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

  Future<void> _submitReview() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final review = ReviewCreate(
      dollShopId: widget.shopId,
      content: _contentController.text.trim(),
      rating: _rating,
      machineStrength: _machineStrength,
      largeDollCost: _largeDollCost != null ? _largeDollCost! * 1000 : null,
      mediumDollCost: _mediumDollCost != null ? _mediumDollCost! * 1000 : null,
      smallDollCost: _smallDollCost != null ? _smallDollCost! * 1000 : null,
    );

    // 1. 리뷰 작성
    final result = await _reviewService.createReview(review);

    if (!result.isSuccess || result.data == null) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.error ?? '리뷰 작성에 실패했습니다')),
        );
      }
      return;
    }

    // 2. 이미지 업로드 (리뷰 ID로)
    if (_selectedImages.isNotEmpty) {
      final uploadResult = await _fileService.uploadFiles(
        files: _selectedImages,
        refId: result.data!.id,
        refType: 'REVIEW',
        usage: 'IMAGE',
      );

      if (!uploadResult.isSuccess) {
        // 이미지 업로드 실패해도 리뷰는 성공
        debugPrint('이미지 업로드 실패: ${uploadResult.error}');
      }
    }

    setState(() => _isSubmitting = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('리뷰가 작성되었습니다')),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('리뷰 작성'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 매장명
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.store, color: Colors.deepPurple),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.shopName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 별점
              const Text('별점 *', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: List.generate(5, (index) {
                  return IconButton(
                    onPressed: () => setState(() => _rating = index + 1),
                    icon: Icon(
                      index < _rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 36,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),

              // 기계 힘
              const Text('기계 힘 (1: 약함 ~ 5: 강함) *',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: List.generate(5, (index) {
                  final value = index + 1;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () => setState(() => _machineStrength = value),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _machineStrength == value
                              ? Colors.deepPurple
                              : Colors.white,
                          border: Border.all(
                            color: _machineStrength == value
                                ? Colors.deepPurple
                                : Colors.grey[300]!,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '$value',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _machineStrength == value
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),

              // 비용 (천원 단위)
              const Text('비용 (천원 단위, 선택)',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: '대형',
                        suffixText: '천원',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => _largeDollCost = int.tryParse(v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: '중형',
                        suffixText: '천원',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => _mediumDollCost = int.tryParse(v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: '소형',
                        suffixText: '천원',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => _smallDollCost = int.tryParse(v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 이미지 첨부
              const Text('이미지 첨부 (선택, 최대 3개)',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  ...List.generate(
                    _selectedImages.length,
                    (index) => Padding(
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
                            child: IconButton(
                              onPressed: () => _removeImage(index),
                              icon: const Icon(
                                Icons.remove_circle,
                                color: Colors.red,
                                size: 24,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _pickImages,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.add_a_photo,
                        color: Colors.deepPurple,
                        size: 36,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 내용
              const Text('내용 *', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  hintText: '리뷰 내용을 작성해주세요',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
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
              const SizedBox(height: 24),

              // 제출 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitReview,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('리뷰 등록'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
