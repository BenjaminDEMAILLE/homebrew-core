class CdHit < Formula
  desc "Cluster and compare protein or nucleotide sequences"
  homepage "https://sites.google.com/view/cd-hit"
  url "https://github.com/weizhongli/cdhit/archive/refs/tags/V4.8.1.tar.gz"
  sha256 "f8bc3cdd7aebb432fcd35eed0093e7a6413f1e36bbd2a837ebc06e57cdb20b70"
  license "GPL-2.0-or-later"
  head "https://github.com/weizhongli/cdhit.git", branch: "master"

  uses_from_macos "zlib"

  on_macos do
    depends_on "libomp"
  end

  def install
    args = ["PREFIX=#{bin}"]
    if OS.mac?
      # The Makefile hardcodes -fopenmp, which Apple clang only accepts
      # through the preprocessor and links against libomp.
      args << "CCFLAGS=-Xpreprocessor -fopenmp -I#{formula_opt_include("libomp")} -DWITH_ZLIB -O2"
      args << "LDFLAGS=-L#{formula_opt_lib("libomp")} -lomp -lz -o"
    end

    bin.mkpath
    system "make", *args
    system "make", "install", *args
  end

  test do
    (testpath/"in.faa").write <<~EOS
      >seq1
      MKAILVVLLYTFATANADTLCIGYHANNSTDTVDTVLEKNVTVTHSVNLLEDKHNGKLCK
      >seq2
      MKAILVVLLYTFATANADTLCIGYHANNSTDTVDTVLEKNVTVTHSVNLLEDKHNGKLCR
      >seq3
      MASQGTKRSYEQMETDGERQNATEIRASVGKMIGGIGRFYIQMCTELKLSDYEGRLIQNS
    EOS
    system bin/"cd-hit", "-i", "in.faa", "-o", "out", "-c", "0.9"

    clusters = (testpath/"out.clstr").read
    assert_equal 2, clusters.scan(/^>Cluster/).length
    assert_match "seq1... *", clusters
    assert_match ">seq3", (testpath/"out").read
  end
end
