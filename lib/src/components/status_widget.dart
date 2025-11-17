import 'package:flutter/material.dart';
import '../utils/page_status.dart';
import 'package:yuni_widget/yuni_widget.dart';

import 'status_empty_widget.dart';

///状态组件展示
class StatusWidget extends StatelessWidget {
  final PageStatus state;
  final Widget child;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final Widget? emptyWidget;
  final Widget? loadingCustomWidget;

  const StatusWidget({
    super.key,
    required this.state,
    required this.child,
    this.errorMessage,
    this.onRetry,
    this.emptyWidget,
    this.loadingCustomWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (state == PageStatus.success) {
      return child;
    }

    if (state == PageStatus.loading || state == PageStatus.initial) {
      return loadingCustomWidget ?? Center(child: YLoading());
    }

    if (state == PageStatus.empty) {
      return emptyWidget ?? Center(child: StatusEmptyWidget());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        YLoadingDialog.error(message: errorMessage),
        YSpacing.heightXxl(),
        YButton(text: '重试', onPressed: onRetry),
      ],
    );
  }
}

