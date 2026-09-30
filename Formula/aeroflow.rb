class Aeroflow < Formula
  @generated = true
  desc "Lightweight, config-driven tiling window manager for macOS (headless daemon)"
  homepage "https://github.com/frostymur/OmniWM"
  version "0.7.3"
  license "GPL-2.0-only"
  url "https://github.com/frostymur/OmniWM/archive/refs/tags/v#{version}.tar.gz"

  on_macos do
    on_arm do
      depends_on "swift" => :build
    end
  end

  def install
    system "swift", "build", "-c", "release", "--arch", "arm64"
    rel = buildpath/".build/arm64-apple-macosx/release"
    app = buildpath/"AeroFlow.app"
    rm_rf app
    (app/"Contents/MacOS").mkpath
    (app/"Contents/Resources").mkpath
    (rel/"AeroFlow").cp app/"Contents/MacOS/AeroFlow"
    (rel/"aeroflowctl").cp app/"Contents/MacOS/aeroflowctl"
    (buildpath/"Info.plist").cp app/"Contents/Info.plist"
    (rel/"AeroFlow_AeroFlow.bundle").cp_r app/"Contents/Resources/"
    system "codesign", "--force", "--sign", "-", app
    prefix.install app
  end

  test do
    assert_predicate (prefix/"AeroFlow.app/Contents/MacOS/AeroFlow"), :exist?
    assert_predicate (prefix/"AeroFlow.app/Contents/MacOS/aeroflowctl"), :exist?
  end

  def caveats
    <<~EOS
      AeroFlow is installed to:
        #{prefix}/AeroFlow.app

      Move it to /Applications for a stable path (macOS permissions are tied to the
      app location):
        cp -R "#{prefix}/AeroFlow.app" /Applications/

      First launch requires Accessibility and Input Monitoring:
        System Settings -> Privacy & Security
    EOS
  end
end
