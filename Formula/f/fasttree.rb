class Fasttree < Formula
  desc "Approximately-maximum-likelihood phylogenetic trees from alignments"
  homepage "https://morgannprice.github.io/fasttree/"
  url "https://github.com/morgannprice/fasttree/archive/refs/tags/v2.2.0.tar.gz"
  sha256 "db5f0d2d1e2b9099193a3a68a5c44f71166a870a7a4269398b9258b1e3478e12"
  license "GPL-3.0-or-later"
  head "https://github.com/morgannprice/fasttree.git", branch: "main"

  on_macos do
    depends_on "libomp"
  end

  def install
    # Double precision is the default in 2.2.0; build the OpenMP (multithreaded)
    # variant, which the community treats as the standard FastTree binary.
    args = %w[-O3 -finline-functions -funroll-loops -DOPENMP]
    if OS.mac?
      libomp = Formula["libomp"]
      args += ["-Xpreprocessor", "-fopenmp", "-I#{libomp.opt_include}",
               "-L#{libomp.opt_lib}", "-lomp"]
    else
      args << "-fopenmp"
    end

    system ENV.cc, "FastTree.c", "-o", "FastTree", "-lm", *args
    bin.install "FastTree"
  end

  test do
    (testpath/"test.fa").write <<~FASTA
      >1
      LCLYTHIGRNIYYGSYLYSETWNTTTMLLLITMATAFMGYVLPWGQMSFWGATVITNLFSAIPYIGTNLV
      >2
      LCLYTHIGRNIYYGSYLYSETWNTGIMLLLITMATAFMGYVLPWGQMSFWGATVITNLFSAIPYIGTNLV
      >3
      LCLYTHIGRNIYYGSYLYSETWNTGIMLLLITMATAFMGTTLPWGQMSFWGATVITNLFSAIPYIGTNLV
    FASTA

    assert_match(/1:0\.\d+,2:0\.\d+,3:0\.\d+/, shell_output("#{bin}/FastTree test.fa 2>&1"))
    assert_match version.to_s, shell_output("#{bin}/FastTree -expert 2>&1")
  end
end
