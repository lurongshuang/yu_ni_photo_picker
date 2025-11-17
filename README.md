# yu_ni_photo_picker

轻量、可配置的 Flutter 相册选择器，支持图片/视频、多选、按日期/月份分组、原图/预览开关、iOS Live Photo 与 Android Motion Photo 识别。

## 安装

在项目的 `pubspec.yaml` 中添加依赖：

```yaml
dependencies:
  yu_ni_photo_picker: ^0.0.1
```


## 平台配置

### iOS

- 在 `Info.plist` 中添加相册权限描述：

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>需要访问相册以选择图片或视频</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>需要保存媒体到相册</string>
```

### Android

- Android 13（SDK 33+）：

```xml
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
```

- Android 12 及以下：

```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
```

同时确保在运行时请求权限（插件内部已按需请求，但你也可以在业务入口预请求以获得更好的体验）。

## 快速开始

```dart
import 'package:yu_ni_photo_picker/yu_ni_photo_picker.dart';
import 'package:photo_manager/photo_manager.dart';

// 单选图片
final file = await PhotoPicker.pickSingle(
  context: context,
  requestType: const [AssetType.image],
);

// 多选图片（按日期分组）
final files = await PhotoPicker.pickMultiple(
  context: context,
  requestType: const [AssetType.image],
  groupByDate: true,
);

// 选择视频
final video = await PhotoPicker.pickSingle(
  context: context,
  requestType: const [AssetType.video],
);

// 图片 + 视频，多选
final medias = await PhotoPicker.pickMultiple(
  context: context,
  requestType: const [AssetType.image, AssetType.video],
  groupByDate: true,
);
```

## API 与参数

### PhotoPicker.pickSingle

```dart
Future<PhotoPickerFile?> pickSingle({
  required BuildContext context,
  List<AssetType> requestType = const [AssetType.image],
  bool groupByDate = false,
  bool groupByMonth = false,
  bool enableCategoryTabs = false,
  OrderOptionType orderBy = OrderOptionType.createDate,
  bool orderAsc = false,
  bool showPreviewButton = false,
  bool showOriginalToggle = false,
  String confirmButtonText = '上传',
})
```

- `context`：页面上下文，用于导航到选择器。
- `requestType`：请求的资源类型集合，`AssetType.image`、`AssetType.video`。
- `groupByDate`：是否按日期分组显示。
- `groupByMonth`：是否按月份分组（在 `groupByDate=true` 时生效）。
- `enableCategoryTabs`：顶部启用多分类 Tab（图片/视频）。
- `orderBy`：排序字段，默认按创建时间。
- `orderAsc`：升序或降序，默认降序。
- `showPreviewButton`：是否显示预览入口。
- `showOriginalToggle`：是否显示原图开关。
- `confirmButtonText`：确认按钮文案，默认“上传”。

返回 `PhotoPickerFile?`，为空表示用户取消。

### PhotoPicker.pickMultiple

```dart
Future<List<PhotoPickerFile>> pickMultiple({
  required BuildContext context,
  List<AssetType> requestType = const [AssetType.image],
  bool groupByDate = false,
  bool groupByMonth = false,
  bool enableCategoryTabs = false,
  OrderOptionType orderBy = OrderOptionType.createDate,
  bool orderAsc = false,
  int maxAssets = 5000,
  bool showPreviewButton = false,
  bool showOriginalToggle = false,
  String confirmButtonText = '上传',
})
```

- 与 `pickSingle` 参数一致，另含：
- `maxAssets`：最大可选择的数量，默认 `5000`。

返回 `List<PhotoPickerFile>`，可能为空列表。

### PhotoPickerFile

```dart
class PhotoPickerFile {
  XFile? xFile;        // 原始文件（图片或视频）
  String fileName;     // 原文件名
  bool isLivePhoto;    // 是否 Live/Motion Photo
  String? mediaUrl;    // Live/Motion 对应的视频路径（如有）
  bool sendOriginal;   // 是否选择“原图”
  bool sendLiveVideo;  // 是否同时发送 Live Video
}
```

说明：
- iOS：`isLivePhoto=true` 时，`mediaUrl` 为系统返回的 Live Photo 视频地址。
- Android：通过 Motion Photos 解析，若存在对应视频文件会在应用文档目录的 `motion_photos/` 下生成并返回路径。

## 进阶示例（自定义参数）

```dart
final files = await PhotoPicker.pickMultiple(
  context: context,
  requestType: const [AssetType.image],
  groupByDate: true,
  groupByMonth: true,
  enableCategoryTabs: true,
  orderBy: OrderOptionType.createDate,
  orderAsc: false,
  maxAssets: 9,
  showPreviewButton: true,
  showOriginalToggle: true,
  confirmButtonText: '上传',
);
```

## 权限与适配建议

- 建议在应用启动或进入相册前预请求权限以减少打断：

```dart
final state = await PhotoManager.requestPermissionExtend();
```

- 大量媒体时缩略图加载会有延迟，插件内部包含缩略图缓存与预加载逻辑。
- 在暗色/自定义主题下可配合你项目的主题系统调整颜色与样式。

## 依赖

- `photo_manager`：相册与媒体管理。
- `image_picker`：统一的文件对象 `XFile`。
- `motion_photos`：Android Motion Photo 解析（仅在 Android 图片下生效）。
- `path_provider`：生成应用文档目录以保存解析出的视频。

## 示例工程

查看 `example/` 以获取完整用法与 UI 示例。

