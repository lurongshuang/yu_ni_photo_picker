import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:yu_ni_photo_picker/yu_ni_photo_picker.dart';
import 'package:yuni_widget/yuni_widget.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        ///app开始构建主页前，进行主题初始化
        // 初始化 YuniWidgetConfig
        themeInitialize(context);

        return MaterialApp(
          title: 'Yu Ni Photo Picker Example',
          theme: getThemeData(),
          darkTheme: getThemeData(),
          home: const PhotoPickerExample(),
        );
      },
    );
  }

  ThemeData getThemeData() {
    return YuniWidgetConfig.instance.theme.toThemeData().copyWith(
      // 应用栏主题
      appBarTheme: AppBarTheme(
        backgroundColor: YuniWidgetConfig.instance.colors.surface,
        foregroundColor: YuniWidgetConfig.instance.colors.onSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: YuniWidgetConfig.instance.textStyles.headingSmallTS
            .copyWith(color: YuniWidgetConfig.instance.colors.onSurface),
        iconTheme: IconThemeData(
          color: YuniWidgetConfig.instance.colors.onSurface,
        ),
      ),
      tabBarTheme: TabBarThemeData(
        dividerHeight: 0,
        indicatorSize: TabBarIndicatorSize.tab,
      ),
    );
  }

  void themeInitialize(BuildContext context) {
    AppTheme theme = AppTheme.light;
    if (YuniWidgetConfig.instance.theme.brightness ==
        AppTheme.light.brightness) {
      theme = mobileLightTheme;
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.dark,
        ),
      );
    } else {
      theme = AppTheme.dark;
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.light,
        ),
      );
    }

    YuniWidgetConfig.instance.init(theme: theme, brightness: theme.brightness);
  }

  ///app 明亮 主题配置
  AppTheme get mobileLightTheme => AppTheme.light.copyWith(
    colors: appColors,
    spacing: AppSpacing(
      zero: 0.0,
      xxs: 2.0,
      xs: 4.0,
      sm: 8.0,
      md: 12.0,
      lg: 16.0,
      xl: 24.0,
      xxl: 32.0,
      xxxl: 48.0,
      mega: 64.0,
    ),
    radius: AppRadius(
      sm: 4.0,
      md: 8.0,
      lg: 12.0,
      xl: 16.0,
      full: 9999.0,
      button: 8.0,
      input: 8.0,
      card: 16.0,
      dialog: 16.0,
      bottomSheet: 16.0,
    ),
    textStyles: AppTextStyles(
      fontFamily: '',
      regular: FontWeight.w400,
      medium: FontWeight.w400,
      bold: FontWeight.w600,
      displayLarge: 32.0.sp,
      displayMedium: 28.0.sp,
      displaySmall: 24.0.sp,
      headingLarge: 22.0.sp,
      headingMedium: 20.0.sp,
      headingSmall: 18.0.sp,
      bodyLarge: 16.0.sp,
      bodyMedium: 14.0.sp,
      bodySmall: 12.0.sp,
      labelLarge: 14.0.sp,
      labelMedium: 12.0.sp,
      labelSmall: 10.0.sp,
      lineHeight: 1.5,
      letterSpacing: 0.25.sp,
    ),
    appDialogStyles: AppDialogStyles(
      primaryButtonBorderRadius: BorderRadius.circular(999),
      secondaryButtonBorderRadius: BorderRadius.circular(999),
      textButtonBorderRadius: BorderRadius.circular(999),
      borderRadius: BorderRadius.circular(16),
    ),
  );

  ///app颜色配置
  static const AppColors appColors = AppColors(
    // 浅色主题通常是浅色背景，深色前景
    // 主要颜色
    primary: Color(0xFF1E5EFF),
    // 导航栏选中项、主要按钮的蓝色
    onPrimary: Color(0xFFFFFFFF),
    // 蓝色背景上的白色文字/图标

    // 次要颜色 (会员编辑界面未选中Tab的浅蓝)
    secondary: Color(0xFFDEEBFF),
    onSecondary: Color(0xFF1E5EFF),
    // 浅蓝背景上的深色文字/图标

    // 第三色 / 强调色 (移除成员按钮的红色)
    tertiary: Color(0xFFFA243C),
    onTertiary: Color(0xFFFFFFFF),
    // 红色背景上的白色文字/图标

    // 背景颜色
    background: Color(0xFFf3f4f6),
    // 整个应用的浅灰色背景
    onBackground: Color(0xFF1E1E1E),
    // 浅灰色背景上的深色文字

    // 表面颜色 (卡片、对话框、主要内容区的白色背景)
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF1E1E1E),
    // 白色表面上的深色文字

    // 表面变体颜色 (搜索框背景、未选中选项卡的浅灰色)
    surfaceVariant: Color(0xFFF6F6F6),
    onSurfaceVariant: Color(0xFF80858D),
    // 浅灰色变体背景上的中等灰色文字

    // 错误颜色 (与强调色类似，用于错误提示)
    error: Color(0xFFFA243C),
    onError: Color(0xFFFFFFFF),

    // 成功颜色 (设计图中未明确，常用绿色)
    success: Color(0xFF36D000),
    onSuccess: Color(0xFFFFFFFF),

    // 警告颜色 (设计图中未明确，常用橙色/黄色)
    warning: Color(0xFFFAAD14),
    onWarning: Color(0xFFFFFFFF),

    // 信息颜色 (设计图中未明确，常用信息蓝)
    info: Color(0xFF1E5EFF),
    onInfo: Color(0xFFFFFFFF),

    // 分隔线颜色
    divider: Color(0xFFE8EDF5),
    // 浅灰色分隔线

    // 禁用状态颜色
    disabledBackground: Color(0xFFD9D9D9),
    // 禁用组件的背景色
    onDisabled: Color(0xFFE8E8E8),
    // 禁用组件上的文字/图标颜色

    // 边框颜色
    outline: Color(0xFFF5F5F5),
    // 输入框、按钮边框的浅灰色

    // 阴影颜色
    shadow: Color(0x29000000),
    // 黑色16%透明度，用于对话框等阴影

    // 叠加层颜色 (模态对话框后的蒙版)
    scrim: Color(0x80000000),
    // 黑色50%透明度—
  );
}

class PhotoPickerExample extends StatefulWidget {
  const PhotoPickerExample({super.key});

  @override
  State<PhotoPickerExample> createState() => _PhotoPickerExampleState();
}

class _PhotoPickerExampleState extends State<PhotoPickerExample> {
  List<PhotoPickerFile> _selectedFiles = [];
  bool _isLoading = false;
  String? _errorMessage;
  final Set<AssetType> _paramRequestTypes = {AssetType.image};
  bool _paramGroupByDate = true;
  bool _paramGroupByMonth = false;
  bool _paramEnableCategoryTabs = false;
  bool _paramOrderAsc = false;
  int _paramMaxAssets = 9;
  bool _paramShowPreview = true;
  bool _paramShowOriginal = true;
  String _paramConfirmText = '上传';

  @override
  void initState() {
    super.initState();
    _requestPermission();
  }

  /// 请求相册权限
  Future<void> _requestPermission() async {
    try {
      final permission = await PhotoManager.requestPermissionExtend();
      if (permission != PermissionState.authorized &&
          permission != PermissionState.limited) {
        setState(() {
          _errorMessage = '需要相册权限才能使用此功能';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '权限请求失败: $e';
      });
    }
  }

  /// 单选图片
  Future<void> _pickSingleImage() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final file = await PhotoPicker.pickSingle(
        context: context,
        requestType: [AssetType.image],
      );

      if (file != null) {
        setState(() {
          _selectedFiles = [file];
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '选择失败: $e';
        _isLoading = false;
      });
    }
  }

  /// 多选图片
  Future<void> _pickMultipleImages() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final files = await PhotoPicker.pickMultiple(
        context: context,
        requestType: [AssetType.image],
        groupByDate: true,
      );

      setState(() {
        _selectedFiles = files;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '选择失败: $e';
        _isLoading = false;
      });
    }
  }

  /// 选择视频
  Future<void> _pickVideo() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final file = await PhotoPicker.pickSingle(
        context: context,
        requestType: [AssetType.video],
      );

      if (file != null) {
        setState(() {
          _selectedFiles = [file];
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '选择失败: $e';
        _isLoading = false;
      });
    }
  }

  /// 选择图片和视频
  Future<void> _pickImagesAndVideos() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final files = await PhotoPicker.pickMultiple(
        context: context,
        requestType: [AssetType.image, AssetType.video],
        groupByDate: true,
      );

      setState(() {
        _selectedFiles = files;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '选择失败: $e';
        _isLoading = false;
      });
    }
  }

  /// 清除选择
  void _clearSelection() {
    setState(() {
      _selectedFiles = [];
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yu Ni Photo Picker Example'),
        actions: [
          if (_selectedFiles.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _clearSelection,
              tooltip: '清除选择',
            ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red.shade700,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(color: Colors.red.shade700),
                              ),
                            ),
                          ],
                        ),
                      ),
                    _buildParamsPanel(),
                    const SizedBox(height: 12),
                    _buildButton(
                      '自定义参数-单选',
                      Icons.tune,
                      _openCustomSingle,
                      Colors.blueGrey,
                    ),
                    const SizedBox(height: 12),
                    _buildButton(
                      '自定义参数-多选',
                      Icons.tune,
                      _openCustomMultiple,
                      Colors.deepPurple,
                    ),
                    const SizedBox(height: 12),
                    _buildButton(
                      '单选图片',
                      Icons.image,
                      _pickSingleImage,
                      Colors.blue,
                    ),
                    const SizedBox(height: 12),
                    _buildButton(
                      '多选图片',
                      Icons.photo_library,
                      _pickMultipleImages,
                      Colors.green,
                    ),
                    const SizedBox(height: 12),
                    _buildButton(
                      '不分组多选图片',
                      Icons.photo_library_outlined,
                      _pickMultipleImagesNoGroup,
                      Colors.teal,
                    ),
                    const SizedBox(height: 12),
                    _buildButton(
                      '按月份分组多选',
                      Icons.date_range,
                      _pickMultipleImagesByMonth,
                      Colors.indigo,
                    ),
                    const SizedBox(height: 12),
                    _buildButton(
                      '选择视频',
                      Icons.video_library,
                      _pickVideo,
                      Colors.orange,
                    ),
                    const SizedBox(height: 12),
                    _buildButton(
                      '选择图片和视频',
                      Icons.collections,
                      _pickImagesAndVideos,
                      Colors.purple,
                    ),
                    const SizedBox(height: 24),
                    if (_selectedFiles.isNotEmpty) ...[
                      Text(
                        '已选择 ${_selectedFiles.length} 个文件',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ..._selectedFiles.asMap().entries.map((entry) {
                        final index = entry.key;
                        final file = entry.value;
                        return _buildFileCard(index + 1, file);
                      }),
                    ] else
                      Container(
                        padding: const EdgeInsets.all(32),
                        child: const Center(
                          child: Text(
                            '请选择一个操作',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
    );
  }

  Widget _buildButton(
    String text,
    IconData icon,
    VoidCallback onPressed,
    Color color,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildFileCard(int index, PhotoPickerFile file) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      '$index',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        file.fileName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        file.xFile?.path ?? '路径未知',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (file.isLivePhoto)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'LIVE',
                      style: TextStyle(
                        color: Colors.purple,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            if (file.mediaUrl != null) ...[
              const SizedBox(height: 8),
              Text(
                '媒体URL: ${file.mediaUrl}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        (file.sendOriginal
                            ? Colors.green.shade100
                            : Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '原图: ${file.sendOriginal ? '是' : '否'}',
                    style: TextStyle(
                      color:
                          file.sendOriginal
                              ? Colors.green.shade800
                              : Colors.grey.shade700,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        (file.sendLiveVideo
                            ? Colors.green.shade100
                            : Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '动态视频: ${file.sendLiveVideo ? '是' : '否'}',
                    style: TextStyle(
                      color:
                          file.sendLiveVideo
                              ? Colors.green.shade800
                              : Colors.grey.shade700,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 不分组多选图片（验证 Drag 偏移修复）
  Future<void> _pickMultipleImagesNoGroup() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final files = await PhotoPicker.pickMultiple(
        context: context,
        requestType: [AssetType.image],
        groupByDate: false,
      );

      setState(() {
        _selectedFiles = files;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '选择失败: $e';
        _isLoading = false;
      });
    }
  }

  /// 按月份分组多选图片
  Future<void> _pickMultipleImagesByMonth() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final files = await PhotoPicker.pickMultiple(
        context: context,
        requestType: [AssetType.image],
        groupByDate: true,
        groupByMonth: true,
      );

      setState(() {
        _selectedFiles = files;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '选择失败: $e';
        _isLoading = false;
      });
    }
  }

  Widget _buildParamsPanel() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '参数配置',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                FilterChip(
                  label: const Text('图片'),
                  selected: _paramRequestTypes.contains(AssetType.image),
                  onSelected: (v) {
                    setState(() {
                      if (v) {
                        _paramRequestTypes.add(AssetType.image);
                      } else {
                        _paramRequestTypes.remove(AssetType.image);
                      }
                      if (_paramRequestTypes.isEmpty) {
                        _paramRequestTypes.add(AssetType.image);
                      }
                    });
                  },
                ),
                FilterChip(
                  label: const Text('视频'),
                  selected: _paramRequestTypes.contains(AssetType.video),
                  onSelected: (v) {
                    setState(() {
                      if (v) {
                        _paramRequestTypes.add(AssetType.video);
                      } else {
                        _paramRequestTypes.remove(AssetType.video);
                      }
                      if (_paramRequestTypes.isEmpty) {
                        _paramRequestTypes.add(AssetType.image);
                      }
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: SwitchListTile(
                    title: const Text('按日期分组'),
                    value: _paramGroupByDate,
                    onChanged: (v) => setState(() => _paramGroupByDate = v),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                Expanded(
                  child: SwitchListTile(
                    title: const Text('按月份分组'),
                    value: _paramGroupByMonth,
                    onChanged: (v) => setState(() => _paramGroupByMonth = v),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: SwitchListTile(
                    title: const Text('多分类 Tab'),
                    value: _paramEnableCategoryTabs,
                    onChanged:
                        (v) => setState(() => _paramEnableCategoryTabs = v),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                // Expanded(
                //   child: SwitchListTile(
                //     title: const Text('升序'),
                //     value: _paramOrderAsc,
                //     onChanged: (v) => setState(() => _paramOrderAsc = v),
                //     contentPadding: EdgeInsets.zero,
                //   ),
                // ),
              ],
            ),
            Row(
              children: [
                const Text('最大选择数'),
                const SizedBox(width: 12),
                Expanded(
                  child: Slider(
                    value: _paramMaxAssets.toDouble(),
                    min: 1,
                    max: 100,
                    divisions: 99,
                    label: '$_paramMaxAssets',
                    onChanged:
                        (v) => setState(() => _paramMaxAssets = v.round()),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                // Expanded(
                //   child: SwitchListTile(
                //     title: const Text('显示预览按钮'),
                //     value: _paramShowPreview,
                //     onChanged: (v) => setState(() => _paramShowPreview = v),
                //     contentPadding: EdgeInsets.zero,
                //   ),
                // ),
                Expanded(
                  child: SwitchListTile(
                    title: const Text('显示原图开关'),
                    value: _paramShowOriginal,
                    onChanged: (v) => setState(() => _paramShowOriginal = v),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            TextField(
              decoration: const InputDecoration(
                labelText: '确认按钮文本',
                hintText: '例如：上传',
              ),
              onChanged:
                  (v) =>
                      setState(() => _paramConfirmText = v.isEmpty ? '上传' : v),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openCustomSingle() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final file = await PhotoPicker.pickSingle(
        context: context,
        requestType: _paramRequestTypes.toList(),
        groupByDate: _paramGroupByDate,
        groupByMonth: _paramGroupByMonth,
        enableCategoryTabs: _paramEnableCategoryTabs,
        // orderAsc: _paramOrderAsc,
        // showPreviewButton: _paramShowPreview,
        showOriginalToggle: _paramShowOriginal,
        confirmButtonText: _paramConfirmText,
      );

      if (file != null) {
        setState(() {
          _selectedFiles = [file];
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '选择失败: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _openCustomMultiple() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final files = await PhotoPicker.pickMultiple(
        context: context,
        requestType: _paramRequestTypes.toList(),
        groupByDate: _paramGroupByDate,
        groupByMonth: _paramGroupByMonth,
        enableCategoryTabs: _paramEnableCategoryTabs,
        // orderAsc: _paramOrderAsc,
        maxAssets: _paramMaxAssets,
        // showPreviewButton: _paramShowPreview,
        showOriginalToggle: _paramShowOriginal,
        confirmButtonText: _paramConfirmText,
      );

      setState(() {
        _selectedFiles = files;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '选择失败: $e';
        _isLoading = false;
      });
    }
  }
}
