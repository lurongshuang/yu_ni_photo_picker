import 'page_status.dart';

/// 基础状态类，用于被具体页面状态继承
abstract class BaseState<T extends BaseState<T>> {
  final PageStatus status;
  final String? errorMessage;

  const BaseState({
    this.status = PageStatus.initial,
    this.errorMessage,
  });

  /// 抽象方法，用于复制当前状态并更新部分属性
  T copyWith({
    PageStatus? status,
    String? errorMessage,
  });
}

