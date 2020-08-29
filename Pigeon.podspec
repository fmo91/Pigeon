#
# Be sure to run `pod lib lint Pigeon.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'Pigeon'
  s.version          = '0.1.8'
  s.summary          = 'Server state management for UIKit and SwiftUI, heavily inspired by React Query.'
  s.description      = <<-DESC
  Pigeon is a server side state management library that is agnostic on how you fetch your data.
  It is inspired by React Query and works with both, SwiftUI and UIKit, and relies heavily in iOS native libraries and Combine.
                       DESC
  s.homepage         = 'https://github.com/fmo91/Pigeon'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'fmo91' => 'ortizfernandomartin@gmail.com' }
  s.source           = { :git => 'https://github.com/fmo91/Pigeon.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/fmortiz_91'
  s.ios.deployment_target = '13.0'
  s.source_files = 'Pigeon/Classes/**/*'
  s.frameworks = 'Combine'
end
