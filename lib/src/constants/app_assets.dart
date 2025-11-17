/// 应用资源管理类
class AppAssets {
  AppAssets._();

  /// 图片资源
  static const Images images = Images();

  /// SVG资源
  static const Svg svg = Svg();

  /// 字体资源
  static const Fonts fonts = Fonts();
}

/// 图片资源类
class Images {
  const Images();

  /// 图片基础路径
  final String _basePath = 'packages/yu_ni_photo_picker/assets/image/';

  /// 获取图片完整路径
  String get(String name) => '$_basePath$name';

  /// 应用图标
  String get appIcon => 'app_icon.png';

  /// 默认头像
  String get defaultAvatar => '${_basePath}default_avatar.png';

  /// 通知tab图标
  String get tabNoticeIcon => 'tab_notice_icon.png';

  String get tabNoticeSelectIcon => 'tab_notice_select_icon.png';

  /// 通知photo图标
  String get tabPhotoIcon => 'tab_photo_icon.png';

  String get tabPhotoSelectIcon => 'tab_photo_select_icon.png';

  /// 下箭头
  String get arrowIcon => 'arrow_icon.png';

  /// 回收站图标
  String get tabRecycleIcon => 'tab_recycle_icon.png';

  /// 添加相册图标
  String get optionAdd => 'option_add.png';

  /// 添加相册图标
  String get optionSelectionAdd => 'option_selection_add.png';

  /// 更多图标
  String get optionMore => 'option_more.png';

  ///搜索相册图标
  String get optionSearch => 'option_search.png';

  ///菜单图标
  String get optionMenu => 'option_menu.png';

  ///返回按钮
  String get leadingIcon => 'leading_icon.png';

  ///右侧进入
  String get rightArrowIcon => 'right_arrow_icon.png';

  ///紧凑宫格选项
  String get optionGridCompact => 'option_grid_compact.png';

  ///标准宫格选项
  String get optionGridStandard => 'option_grid_standard.png';

  ///回收站图标
  String get optionRecycleIcon => 'option_recycle_icon.png';

  ///传输列表图标
  String get optionTransIcon => 'option_trans_icon.png';

  ///关闭X图标
  String get closeSheetIcon => 'close_sheet_icon.png';

  ///设置选项图标
  String get optionSetting => 'option_setting.png';

  ///向下箭头
  String get bottomArrow => 'bottom_arrow.png';

  ///筛选图标
  String get filterIcon => 'filter_icon.png';

  ///详情按钮
  String get optionHelperInfo => 'option_helper_info.png';

  ///点赞
  String get optionLikeIcon => 'option_like_icon.png';

  ///转换
  String get optionBtnChange => 'option_btn_change.png';

  ///评论
  String get optionBtnComment => 'option_btn_comment.png';

  ///点赞
  String get optionBtnLike => 'option_btn_like.png';

  ///管理
  String get optionBtnManage => 'option_btn_manage.png';

  ///标签
  String get optionBtnTag => 'option_btn_tag.png';

  ///删除icon
  String get recycleIcon => 'recycle_icon.png';

  ///进行中icon
  String get optionPlayingIcon => 'option_playing_icon.png';

  ///上传icon
  String get optionUploadIcon => 'option_upload_icon.png';

  ///等待中icon
  String get optionWaitIcon => 'option_wait_icon.png';

  ///排序icon
  String get optionUnionIcon => 'option_union_icon.png';

  ///空数据
  String get iconEmpty => 'icon_empty.png';

  ///彻底删除
  String get optionDelIcon => 'option_del_icon.png';

  ///下载本地
  String get optionDownloadIcon => 'option_download_icon.png';

  ///复制按钮
  String get optionCopyIcon => 'option_copy_icon.png';

  ///编辑按钮
  String get optionEditIcon => 'option_edit_icon.png';

  ///更多操作
  String get optionMoreIcon => 'option_more_icon.png';

  ///移动按钮
  String get optionMoveIcon => 'option_move_icon.png';

  ///标签按钮
  String get optionBtnTagPrimary => 'option_btn_tag_primary.png';

  ///图像转换
  String get optionBtnChangePrimary => 'option_btn_change_primary.png';

  ///存储管理
  String get optionBtnManagePrimary => 'option_btn_manage_primary.png';

  ///分享
  String get optionBtnSharePrimary => 'option_btn_manage_primary.png';

  ///编辑按钮
  String get btnEditPrimary => 'btn_edit_primary.png';

  ///文件占位
  String get fileBg => 'file_bg.png';

  ///欢迎页图片
  String get welcome => 'welcome.png';

  ///图拽图片背景
  String get dropTargeBg => 'drop_targe_bg.png';

  ///实时动态图
  String get livePhotoIcon => 'live_photo_icon.png';

  ///文件夹图标
  String get iconFolder => 'icon_folder.png';

  ///已下载图标
  String get iconIsDownloaded => 'icon_is_downloaded.png';

  ///@
  String get btnAt => 'btn_at.png';

  ///上传左侧箭头
  String get optionTransLIcon => 'option_trans_l_icon.png';

  ///上传右侧箭头
  String get optionTransRIcon => 'option_trans_r_icon.png';

  ///删除按钮
  String get iconDelete => 'icon_delete.png';
}

/// SVG资源类
class Svg {
  const Svg();

  /// SVG基础路径
  final String _basePath = 'packages/yu_ni_photo_picker/assets/svg/';

  /// 获取SVG完整路径
  String get(String name) => '$_basePath$name';

  String get appName => 'svg_app_name.svg';

  /// 修改相册名称图标
  String get iconEdit => 'svg_icon_edit.svg';

  /// 修改用户组名称图标
  String get iconEditBlue => 'svg_icon_edit_blue.svg';

  /// 圆形添加图标
  String get addCircle => 'svg_add_circle.svg';

  /// 圆形减少图标
  String get minusCircle => 'svg_minus_circle.svg';

  /// 搜索图标
  String get iconSearch => 'svg_icon_search.svg';

  ///更多图标
  String get iconMore => 'svg_icon_more.svg';

  ///未选中的图标
  String get radio => 'svg_radio.svg';

  ///选中图标
  String get radioSelected => 'svg_radio_selected.svg';

  ///"X"图标
  String get error => 'svg_error.svg';

  ///"+"图标
  String get add => "svg_add.svg";

  ///欢迎页"->"图标
  String get rightArrow => "svg_right_arrow.svg";

  ///下箭头
  String get downArrow => "svg_down_arrow.svg";

  ///欢迎页"->"图标
  String get upArrow => "svg_up_arrow.svg";
}

/// 字体资源类
class Fonts {
  const Fonts();

  /// 字体基础路径
  final String _basePath = 'packages/yu_ni_photo_picker/assets/font/';

  /// 获取字体完整路径
  String get(String name) => '$_basePath$name';

  /// 应用字体
  String get roboto => '${_basePath}Roboto-Regular.ttf';

  String get robotoMedium => '${_basePath}Roboto-Medium.ttf';

  String get robotoBold => '${_basePath}Roboto-Bold.ttf';
}

