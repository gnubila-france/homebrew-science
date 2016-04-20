class Superlu < Formula
  desc "Solve large, sparse nonsymmetric systems of equations"
  homepage "http://crd-legacy.lbl.gov/~xiaoye/SuperLU/"
  url "http://crd-legacy.lbl.gov/~xiaoye/SuperLU/superlu_5.1.tar.gz"
  sha256 "307ef10edef4cebc6c7f672cd931ae6682db4c4f5f93a44c78e9544a520e2db1"
  revision 2

  bottle do
    cellar :any
    sha256 "aa3b95ee77fde6925dcb11782c3db80887ea46f65f0e63e79225af9cb8c46d90" => :el_capitan
    sha256 "f5c6806dd0e4f8b8be17f51ef534b87c2bd1c0e08d17b9c53689d23e5a9ef347" => :yosemite
    sha256 "57caa18d436edb752c2486567db047dbfc1b072acf1334388557e13d300056e6" => :mavericks
  end

  deprecated_option "without-check" => "without-test"

  option "with-matlab", "Build MEX files for use with Matlab"
  option "with-matlab-path=", "Directory that contains MATLAB bin and extern subdirectories"

  option "without-test", "skip build-time tests (not recommended)"
  option "with-openmp", "Enable OpenMP multithreading"

  depends_on :fortran

  # Accelerate single precision is buggy and causes certain single precision
  # tests to fail.
  depends_on "openblas" => ((OS.mac?) ? :optional : :recommended)
  depends_on "veclibfort" if build.without?("openblas") && OS.mac?

  needs :openmp if build.with? "openmp"

  patch :DATA

  def install
    ENV.deparallelize
    cp "MAKE_INC/make.mac-x", "./make.inc"
    make_args = ["RANLIB=true",
                 "CC=#{ENV.cc}",
                 "CFLAGS=-fPIC #{ENV.cflags}",
                 "FORTRAN=#{ENV.fc}",
                 "FFLAGS=#{ENV.fcflags}",
                 "SuperLUroot=#{buildpath}",
                 "SUPERLULIB=$(SuperLUroot)/lib/libsuperlu.a",
                 "NOOPTS=-fPIC",
                ]

    if build.with? "openblas"
      blas = "-L#{Formula["openblas"].opt_lib} -lopenblas"
    else
      blas = (OS.mac?) ? "-L#{Formula["veclibfort"].opt_lib} -lvecLibFort" : "-lblas"
    end
    make_args << "BLASLIB=#{blas}"
    make_args << ("LOADOPTS=" + ((build.with? "openmp") ? "-fopenmp" : ""))

    system "make", "lib", *make_args
    if build.with? "test"
      system "make", "testing", *make_args
      cd "TESTING" do
        system "make", *make_args
        %w[stest dtest ctest ztest].each do |tst|
          ohai `tail -1 #{tst}.out`.chomp
        end
      end
    end

    cd "EXAMPLE" do
      system "make", *make_args
    end

    if build.with? "matlab"
      matlab = ARGV.value("with-matlab-path") || HOMEBREW_PREFIX
      cd "MATLAB" do
        system "make", "MATLAB=#{matlab}", *make_args
      end
    end

    prefix.install "make.inc"
    File.open(prefix/"make_args.txt", "w") do |f|
      f.puts(make_args.join(" ")) # Record options passed to make.
    end
    lib.install Dir["lib/*"]
    (include/"superlu").install Dir["SRC/*.h"]
    doc.install Dir["Doc/*"]
    (pkgshare/"examples").install Dir["EXAMPLE/*[^.o]"]
    (pkgshare/"matlab").install Dir["MATLAB/*"] if build.with? "matlab"
  end

  def caveats
    s = ""
    if build.with? "matlab"
      s += <<-EOS.undent
        Matlab interfaces are located in

          #{opt_pkgshare}/matlab
      EOS
    end
    s
  end

  test do
    ENV.fortran
    cp_r pkgshare/"examples", testpath
    cp prefix/"make.inc", testpath
    make_args = ["CC=#{ENV.cc}",
                 "CFLAGS=-fPIC #{ENV.cflags}",
                 "FORTRAN=#{ENV.fc}",
                 "FFLAGS=#{ENV.fcflags}",
                 "SuperLUroot=#{opt_prefix}",
                 "SUPERLULIB=#{opt_lib}/libsuperlu.a",
                 "NOOPTS=-fPIC",
                 "HEADER=#{opt_include}/superlu",
                ]

    if build.with? "openblas"
      blas = "-L#{Formula["openblas"].opt_lib} -lopenblas"
    else
      blas = (OS.mac?) ? "-L#{Formula["veclibfort"].opt_lib} -lvecLibFort" : "-lblas"
    end
    make_args << "BLASLIB=#{blas}"
    make_args << ("LOADOPTS=" + ((build.with? "openmp") ? "-fopenmp" : ""))

    cd "examples" do
      system "make", *make_args

      system "./superlu"
      system "./slinsol < g20.rua"
      system "./slinsolx  < g20.rua"
      system "./slinsolx1 < g20.rua"
      system "./slinsolx2 < g20.rua"

      system "./dlinsol < g20.rua"
      system "./dlinsolx  < g20.rua"
      system "./dlinsolx1 < g20.rua"
      system "./dlinsolx2 < g20.rua"

      system "./clinsol < cg20.cua"
      system "./clinsolx < cg20.cua"
      system "./clinsolx1 < cg20.cua"
      system "./clinsolx2 < cg20.cua"

      system "./zlinsol < cg20.cua"
      system "./zlinsolx < cg20.cua"
      system "./zlinsolx1 < cg20.cua"
      system "./zlinsolx2 < cg20.cua"

      system "./sitersol -h < g20.rua" # broken with Accelerate
      system "./sitersol1 -h < g20.rua"
      system "./ditersol -h < g20.rua"
      system "./ditersol1 -h < g20.rua"
      system "./citersol -h < g20.rua"
      system "./citersol1 -h < g20.rua"
      system "./zitersol -h < cg20.cua"
      system "./zitersol1 -h < cg20.cua"
    end
  end
end

__END__
diff --git a/EXAMPLE/citersol.c b/EXAMPLE/citersol.c
index 1bcd6a2..6ced186 100644
--- a/EXAMPLE/citersol.c
+++ b/EXAMPLE/citersol.c
@@ -292,7 +292,7 @@ int main(int argc, char *argv[])
     restrt = SUPERLU_MIN(n / 3 + 1, 50);
     maxit = 1000;
     iter = maxit;
-    resid = 1e-8;
+    resid = 1e-4;
     if (!(x = complexMalloc(n))) ABORT("Malloc fails for x[].");

     if (info <= n + 1)
@@ -326,7 +326,7 @@ int main(int argc, char *argv[])
	if (iter >= maxit)
	{
	    if (resid >= 1.0) iter = -180;
-	    else if (resid > 1e-8) iter = -111;
+	    else if (resid > 1e-4) iter = -111;
	}
	printf("iteration: %d\nresidual: %.1e\nGMRES time: %.2f seconds.\n",
		iter, resid, t);
diff --git a/EXAMPLE/citersol1.c b/EXAMPLE/citersol1.c
index 09036d0..836c9ac 100644
--- a/EXAMPLE/citersol1.c
+++ b/EXAMPLE/citersol1.c
@@ -304,7 +304,7 @@ int main(int argc, char *argv[])
     restrt = SUPERLU_MIN(n / 3 + 1, 50);
     maxit = 1000;
     iter = maxit;
-    resid = 1e-8;
+    resid = 1e-4;
     if (!(x = complexMalloc(n))) ABORT("Malloc fails for x[].");

     if (info <= n + 1)
@@ -338,7 +338,7 @@ int main(int argc, char *argv[])
	if (iter >= maxit)
	{
	    if (resid >= 1.0) iter = -180;
-	    else if (resid > 1e-8) iter = -111;
+	    else if (resid > 1e-4) iter = -111;
	}
	printf("iteration: %d\nresidual: %.1e\nGMRES time: %.2f seconds.\n",
		iter, resid, t);
diff --git a/EXAMPLE/sitersol.c b/EXAMPLE/sitersol.c
index fc6045c..8f0b6f7 100644
--- a/EXAMPLE/sitersol.c
+++ b/EXAMPLE/sitersol.c
@@ -291,7 +291,7 @@ int main(int argc, char *argv[])
     restrt = SUPERLU_MIN(n / 3 + 1, 50);
     maxit = 1000;
     iter = maxit;
-    resid = 1e-8;
+    resid = 1e-4;
     if (!(x = floatMalloc(n))) ABORT("Malloc fails for x[].");

     if (info <= n + 1)
@@ -325,7 +325,7 @@ int main(int argc, char *argv[])
	if (iter >= maxit)
	{
	    if (resid >= 1.0) iter = -180;
-	    else if (resid > 1e-8) iter = -111;
+	    else if (resid > 1e-4) iter = -111;
	}
	printf("iteration: %d\nresidual: %.1e\nGMRES time: %.2f seconds.\n",
		iter, resid, t);
diff --git a/EXAMPLE/sitersol1.c b/EXAMPLE/sitersol1.c
index 7d098fb..2ee355c 100644
--- a/EXAMPLE/sitersol1.c
+++ b/EXAMPLE/sitersol1.c
@@ -303,7 +303,7 @@ int main(int argc, char *argv[])
     restrt = SUPERLU_MIN(n / 3 + 1, 50);
     maxit = 1000;
     iter = maxit;
-    resid = 1e-8;
+    resid = 1e-4;
     if (!(x = floatMalloc(n))) ABORT("Malloc fails for x[].");

     if (info <= n + 1)
@@ -337,7 +337,7 @@ int main(int argc, char *argv[])
	if (iter >= maxit)
	{
	    if (resid >= 1.0) iter = -180;
-	    else if (resid > 1e-8) iter = -111;
+	    else if (resid > 1e-4) iter = -111;
	}
	printf("iteration: %d\nresidual: %.1e\nGMRES time: %.2f seconds.\n",
		iter, resid, t);
diff --git a/MATLAB/mexsuperlu.c b/MATLAB/mexsuperlu.c
index 08fe3fd..d9e3a7b 100644
--- a/MATLAB/mexsuperlu.c
+++ b/MATLAB/mexsuperlu.c
@@ -45,6 +45,7 @@ void mexFunction(
     SuperMatrix A;
     SuperMatrix Ac;        /* Matrix postmultiplied by Pc */
     SuperMatrix L, U;
+    GlobalLU_t  Glu;
     int	   	m, n, nnz;
     double      *val;
     int       	*rowind;
@@ -124,7 +125,7 @@ void mexFunction(
     }

     dgstrf(&options, &Ac, relax, panel_size, etree,
-	   NULL, 0, perm_c, perm_r, &L, &U, &stat, &info);
+	   NULL, 0, perm_c, perm_r, &L, &U, &Glu, &stat, &info);

     if ( verbose ) mexPrintf("INFO from dgstrf %d\n", info);
