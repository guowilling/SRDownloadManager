
Pod::Spec.new do |s|
s.name         = "SRDownloadManager"
s.version      = "1.0.0"
s.summary      = "Files download manager based on NSURLSession, support breakpoint download, multitasking download etc."
s.description  = "Provide download status callback, download progress callback, download complete callback; Support multi-task at the same time to download; Support breakpoint download even exit the App; Support to delete the specified file by URL and clear all files that have been downloaded; Support customize the directory where the downloaded files are saved; Support set maximum concurrent downloads and waiting downloads queue mode."
s.homepage     = "https://github.com/guowilling/SRDownloadManager"
s.license      = "MIT"
s.author       = { "guowilling" => "guowilling90@gmail.com" }
s.platform     = :ios, "7.0"
s.source       = { :git => "https://github.com/guowilling/SRDownloadManager.git", :tag => "#{s.version}" }
s.source_files = "SRDownloadManager/*.{h,m}"
s.requires_arc = true
end
