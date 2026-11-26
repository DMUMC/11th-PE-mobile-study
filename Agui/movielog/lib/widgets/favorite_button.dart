import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../view_models/favorite_detail_view_model.dart';

class FavoriteButton extends StatelessWidget {
  const FavoriteButton({super.key});

  Future<void> _toggle(BuildContext context, FavoriteDetailViewModel vm) async {
    final message = await vm.toggle();
    if (!context.mounted || !vm.isCurrent || message == null) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF6750A4);
    return Consumer<FavoriteDetailViewModel>(
      builder: (context, vm, _) => SizedBox(
        width: 62,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 72,
              width: 62,
              decoration: BoxDecoration(
                color: const Color(0xFFFEFCF9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFD9D3E1)),
              ),
              child: vm.isLoading || vm.isSaving
                  ? Center(
                      child: SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: primary,
                          semanticsLabel: vm.isSaving
                              ? '즐겨찾기 저장 중'
                              : '즐겨찾기 여부 조회 중',
                        ),
                      ),
                    )
                  : IconButton(
                      tooltip: vm.isFavorite ? '즐겨찾기 해제' : '즐겨찾기 등록',
                      isSelected: vm.isFavorite,
                      iconSize: 32,
                      padding: EdgeInsets.zero,
                      style: IconButton.styleFrom(
                        foregroundColor: primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: vm.hasLoadedStatus && vm.isCurrent
                          ? () => _toggle(context, vm)
                          : null,
                      color: primary,
                      icon: Icon(
                        vm.isFavorite ? Icons.bookmark : Icons.bookmark_border,
                      ),
                    ),
            ),
            const SizedBox(height: 8),
            const Text(
              '즐겨찾기',
              style: TextStyle(
                fontSize: 11,
                height: 15 / 11,
                fontWeight: FontWeight.w700,
                color: primary,
              ),
            ),
            if (!vm.hasLoadedStatus &&
                !vm.isLoading &&
                vm.errorMessage != null) ...[
              const Text('조회 실패', style: TextStyle(fontSize: 11)),
              IconButton(
                tooltip: '즐겨찾기 여부 다시 확인',
                onPressed: vm.isCurrent ? vm.load : null,
                color: primary,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
