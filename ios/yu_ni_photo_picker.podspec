#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint yu_ni_photo_picker.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'yu_ni_photo_picker'
  s.version          = '0.0.1'
  s.summary          = 'Yu Ni Photo Picker: Flutter plugin for selecting photos and videos.'
  s.description      = <<-DESC
A Flutter plugin that provides a configurable photo/video picker with date/month grouping,
Live/Motion Photo detection, preview and original toggles.
                       DESC
  s.homepage         = 'https://github.com/lurongshuang/yu_ni_photo_picker'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'lurongshuang' => 'lurongshuang@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'yu_ni_photo_picker_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
end
