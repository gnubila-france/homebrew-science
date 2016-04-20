require 'formula'

class Niftilib < Formula
  homepage "http://niftilib.sourceforge.net"
  url "https://downloads.sourceforge.net/project/niftilib/nifticlib/nifticlib_2_0_0/nifticlib-2.0.0.tar.gz"
  sha256 "a3e988e6a32ec57833056f6b09f940c69e79829028da121ff2c5c6f7f94a7f88"

  depends_on 'cmake' => :build unless OS.mac?

  def install
    ENV.deparallelize
    if OS.mac?
      system "make"
      bin.install Dir["bin/*"]
      lib.install Dir["lib/*"]
      include.install Dir["include/*"]
    else
      system "cmake -Wno-dev -G'Unix Makefiles' -DCMAKE_SKIP_RPATH=ON -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=on -DCMAKE_INSTALL_PREFIX=#{prefix}"
      system "make"
      system "make install"
    end
  end
end
