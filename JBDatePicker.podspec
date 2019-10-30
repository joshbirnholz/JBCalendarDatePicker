Pod::Spec.new do |s|

# 1
s.platform = :ios
s.ios.deployment_target = '13.0'
s.name = "JBDatePicker"
s.summary = "A replacement for UIDatePicker made for Catalyst."
s.requires_arc = true

# 2
s.version = "0.1.2"

# 3
s.license = { :type => "MIT", :file => "LICENSE" }

# 4 - Replace with your name and e-mail address
s.author = { "Josh Birnholz" => "josh@birnholz.com" }

# 5 - Replace this URL with your own GitHub page's URL (from the address bar)
s.homepage = "https://github.com/joshbirnholz/JBDatePicker"

# 6 - Replace this URL with your own Git URL from "Quick Setup"
s.source = { :git => "https://github.com/joshbirnholz/JBDatePicker.git",
             :tag => "#{s.version}" }

# 7
s.framework = "UIKit"

# 8
s.source_files = "JBDatePicker/**/*.{swift}"

# 9
s.resources = "JBDatePicker/**/*.{xib}"

# 10
s.swift_version = "5"

end
