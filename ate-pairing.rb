require "formula"

class AtePairing < Formula
  homepage "http://homepage1.nifty.com/herumi/crypt/ate-pairing.html"
  url "https://github.com/herumi/ate-pairing/archive/v1.0.tar.gz"
  sha1 "c929af546d13415c823fe1d32d8f8b18f11eaa75"
  head "https://github.com/herumi/ate-pairing.git"

  depends_on "xbyak"

  def install
    system "make", "-C", "src"
    lib.install "lib/libzm.a"
    (include+"ate-pairing").install Dir["include/*.h"]
  end

  test do
    (testpath / "test.cpp").write <<-EOS.undent
      #include <ate-pairing/bn.h>
      using namespace bn;

      const struct Point {
        struct G2 {
          const char *aa;
          const char *ab;
          const char *ba;
          const char *bb;
        } g2;
        struct G1 {
          int a;
          int b;
        } g1;
      } pt = {
        {
          "12723517038133731887338407189719511622662176727675373276651903807414909099441",
          "4168783608814932154536427934509895782246573715297911553964171371032945126671",
          "13891744915211034074451795021214165905772212241412891944830863846330766296736",
          "7937318970632701341203597196594272556916396164729705624521405069090520231616",
        },
        {
          -1, 1
        }
      };

      int main()
      {
        Param::init();
        const Ec2 g2(
          Fp2(Fp(pt.g2.aa), Fp(pt.g2.ab)),
          Fp2(Fp(pt.g2.ba), Fp(pt.g2.bb))
        );
        const Ec1 g1(pt.g1.a, pt.g1.b);
        mie::Vuint a("123456789");
        mie::Vuint b("98765432");
        Ec1 g1a = g1 * a;
        Ec2 g2b = g2 * b;
        Fp12 e, eab;
        opt_atePairing(e, g2, g1);
        opt_atePairing(eab, g2b, g1a);
        assert(eab == power(e, a*b));
        return 0;
      }
    EOS
    system ENV.cxx, "test.cpp", "-lzm", "-o", "test"
    system "./test"
  end
end
