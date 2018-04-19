Pod::Spec.new do |s|
    s.name     = 'OOHTTP'
    s.version  = '3.0.0'
    s.license  = 'MIT'
    s.summary  = 'Free http headers for Retriable AFNetworking'
    s.homepage = 'https://github.com/emsihyo/OOHTTP'
    s.author   = { 'emsihyo' => 'emsihyo@gmail.com' }
    s.source   = { :git => 'https://github.com/emsihyo/OOHTTP.git',:tag => "#{s.version}" }
    s.description = 'Free http headers for Retriable AFNetworking.'
    s.requires_arc = true
    s.platform = :ios
    s.ios.deployment_target = '8.0'
    s.source_files = 'OOHTTP/*.{h,m}'
    s.framework = 'UIKit'
    s.dependency 'RetriableAFNetworking'
    s.dependency 'JRSwizzle'
end
