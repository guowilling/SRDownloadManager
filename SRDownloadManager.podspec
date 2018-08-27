
Pod::Spec.new do |s|
s.name         = "SRDownloadManager"
s.version      = "1.2.0"
s.summary      = "File download manager based on NSURLSession"
s.description  = "Powerful and easy-to-use file download manager based on NSURLSession. Provide download status, progress and completion callback block."
s.homepage     = "https://github.com/guowilling/SRDownloadManager"
s.license      = "MIT"
s.author       = { "guowilling" => "guowilling90@gmail.com" }
s.platform     = :ios, "7.0"
s.source       = { :git => "https://github.com/guowilling/SRDownloadManager.git", :tag => "#{s.version}" }
s.source_files = "SRDownloadManager/*.{h,m}"
s.requires_arc = true
end
