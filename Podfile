
# DEPRECATED: project uses Swift Package Manager. Keep for reference only.
# Uncomment the next line to define a global platform for your project
platform :ios, '15.0'

target 'World Arena. Flags' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for World Arena. Flags
  pod 'Firebase/Core'
  pod 'Firebase/Analytics'
  pod 'Google-Mobile-Ads-SDK'
  pod 'GoogleSignIn'

  target 'World Arena. FlagsTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'World Arena. FlagsUITests' do
    # Pods for testing
  end

end

post_install do |installer|
  # Xcode script sandbox can block CocoaPods rsync in [CP] Embed Pods Frameworks.
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['ENABLE_USER_SCRIPT_SANDBOXING'] = 'NO'
    end
  end

  installer.aggregate_targets.each do |aggregate_target|
    user_project = aggregate_target.user_project
    user_project.native_targets.each do |target|
      target.build_configurations.each do |config|
        config.build_settings['ENABLE_USER_SCRIPT_SANDBOXING'] = 'NO'
      end
    end
    user_project.save
  end
end