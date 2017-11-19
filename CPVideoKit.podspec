Pod::Spec.new do |s|

  s.name         = "CPVideoKit"
  s.version      = "0.1.0"
  s.summary      = "A small yet powerful video cropping and scaling library."
  s.description  = "A small yet powerful video cropping and scaling library that can take an `AVAsset`, crop it, rescale it, and export it to a specified file. It also contains helper methods for calculating the crop area."
  s.homepage     = "https://github.com/canpoyrazoglu/CPVideoKit"

  s.license      = { :type => "MIT", :file => "LICENSE" }


  s.author             = { "Can Poyrazoğlu" => "can@canpoyrazoglu.com" }
  s.social_media_url   = "http://twitter.com/canpoyrazoglu"



  s.platform     = :ios, "8.0"


  s.source       = { :git => "https://github.com/canpoyrazoglu/CPVideoKit.git", :tag => 'v0.1.0' }


  s.source_files  = "Classes", "Classes/**/*.{h,m}"
  s.exclude_files = "Classes/Exclude"

end
