
Pod::Spec.new do |s|
s.name         = "SRDownloadManager"
s.version      = "1.5.0"
s.summary      = "File download manager based on NSURLSession. Multitasking download and breakpoint download."
s.description  = "A file download manager based on NSURLSession. Provide multitasking download at the same time and breakpoint download even exit the App funtion. Provide download status callback, download progress callback and download completion callback."
s.homepage     = "https://github.com/guowilling/SRDownloadManager"
s.license      = "MIT"
s.author       = { "guowilling" => "guowilling90@gmail.com" }
s.platform     = :ios, "7.0"
s.source       = { :git => "https://github.com/guowilling/SRDownloadManager.git", :tag => "#{s.version}" }
s.source_files = "SRDownloadManager/*.{h,m}"
s.requires_arc = true
end
