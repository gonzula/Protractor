Pod::Spec.new do |s|

  s.name         = "Protractor"
  s.version      = "1.1.1"
  s.summary      = "A UIControl to select angles"

  s.description  = <<-DESC
                    A UIControl to select angles. It was developed to work as a UITextField.inputView
                   DESC

  s.homepage     = "https://github.com/ceafdc/Protractor"
  s.screenshots  = "https://raw.githubusercontent.com/ceafdc/Protractor/master/screenshot.png"


  s.license      = { :type => "MIT", :file => "LICENSE" }


  s.author       = { "Gonzo Fialho" => "carloseaf@gmail.com" }

  s.platform     = :ios, "10.0"

  s.source       = { :git => "https://github.com/ceafdc/Protractor.git", :tag => s.version.to_s }

  s.source_files = "Protractor", "Protractor/**/*.{swift}"

  s.pod_target_xcconfig = {'SWIFT_VERSION' => '4'}

end
