class Scotch < Formula
  desc "Software package for graph and mesh/hypergraph partitioning, graph clustering, and sparse matrix ordering"
  homepage "https://gforge.inria.fr/projects/scotch"
  url "https://gforge.inria.fr/frs/download.php/file/34618/scotch_6.0.4.tar.gz"
  sha256 "f53f4d71a8345ba15e2dd4e102a35fd83915abf50ea73e1bf6efe1bc2b4220c7"
  revision 1

  bottle do
    cellar :any
    revision 1
    sha256 "cf4496e8f83b59f659ac6cca13d1d86d6a5cb0bfd6c0c649355421bd27067311" => :el_capitan
    sha256 "d003dd5e30c0945013e134842cd1cd8d16bbf234d161ccba6867ad95324c93cf" => :yosemite
    sha256 "90da8b03e290fae7c21f2907678aecf6339eb873f0f37a2086fa658cf1b45c4b" => :mavericks
  end

  option "without-check", "skip build-time tests (not recommended)"

  depends_on :mpi => :cc
  depends_on "xz" => :optional # Provides lzma compression.

  def install
    cd "src" do
      ln_s "Make.inc/Makefile.inc.i686_mac_darwin10", "Makefile.inc"
      # default CFLAGS: -O3 -Drestrict=__restrict -DCOMMON_FILE_COMPRESS_GZ -DCOMMON_PTHREAD -DCOMMON_PTHREAD_BARRIER -DCOMMON_RANDOM_FIXED_SEED -DCOMMON_TIMING_OLD -DSCOTCH_PTHREAD -DSCOTCH_RENAME
      # MPI implementation is not threadsafe, do not use DSCOTCH_PTHREAD

      cflags   = %w[-O3 -fPIC -Drestrict=__restrict -DCOMMON_PTHREAD_BARRIER
                    -DCOMMON_PTHREAD
                    -DSCOTCH_CHECK_AUTO -DCOMMON_RANDOM_FIXED_SEED
                    -DCOMMON_TIMING_OLD -DSCOTCH_RENAME
                    -DCOMMON_FILE_COMPRESS_BZ2 -DCOMMON_FILE_COMPRESS_GZ]
      ldflags  = %w[-lm -lz -lpthread -lbz2]

      cflags  += %w[-DCOMMON_FILE_COMPRESS_LZMA]   if build.with? "xz"
      ldflags += %W[-L#{Formula["xz"].lib} -llzma] if build.with? "xz"

      make_args = ["CCS=#{ENV["CC"]}",
                   "CCP=#{ENV["MPICC"]}",
                   "CCD=#{ENV["MPICC"]}",
                   "RANLIB=echo",
                   "CFLAGS=#{cflags.join(" ")}",
                   "LDFLAGS=#{ldflags.join(" ")}"]

      if OS.mac?
        make_args << "LIB=.dylib"
        make_args << "AR=libtool"
        make_args << "ARFLAGS=-dynamic -install_name #{lib}/$(notdir $@) -undefined dynamic_lookup -o "
      else
        make_args << "LIB=.so"
        make_args << "ARCH=ar"
        make_args << "ARCHFLAGS=-ruv"
      end

      system "make", "scotch", "VERBOSE=ON", *make_args
      system "make", "ptscotch", "VERBOSE=ON", *make_args
      system "make", "install", "prefix=#{prefix}", *make_args
      system "make", "check", "ptcheck", "EXECP=mpirun -np 2", *make_args if build.with? "check"
    end

    # Install documentation + sample graphs and grids.
    doc.install Dir["doc/*"]
    (share / "scotch").install "grf", "tgt"
  end

  test do
    mktemp do
      system "echo cmplt 7 | #{bin}/gmap #{share}/scotch/grf/bump.grf.gz - bump.map"
      system "#{bin}/gmk_m2 32 32 | #{bin}/gmap - #{share}/scotch/tgt/h8.tgt brol.map"
      system "#{bin}/gout -Mn -Oi #{share}/scotch/grf/4elt.grf.gz #{share}/scotch/grf/4elt.xyz.gz - graph.iv"
    end
  end
end
