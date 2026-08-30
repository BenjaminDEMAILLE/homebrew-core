class Subread < Formula
  desc "Read alignment, quantification and mutation discovery for sequencing data"
  homepage "https://subread.sourceforge.net/"
  url "https://downloads.sourceforge.net/project/subread/subread-2.1.1/subread-2.1.1-source.tar.gz"
  sha256 "6392d7c66831cdd767e58251892a79a51b6fab8ed0ba9671ad5e85ff1ab01eaa"
  license "GPL-3.0-or-later"

  uses_from_macos "zlib"

  def install
    # Build with the Homebrew compiler and drop the hardcoded x86-only
    # tuning flags so that the package also builds on ARM.
    inreplace "src/Makefile.Linux" do |s|
      s.gsub! "CC_EXEC = gcc", "CC_EXEC = #{ENV.cc}"
      s.gsub! "-mtune=core2 ", ""
    end
    inreplace "src/Makefile.MacOS",
              "CC = gcc ${CCFLAGS} ${STATIC_MAKE} -ggdb -fomit-frame-pointer -O3 -ffast-math " \
              "-funroll-loops -mmmx -msse -msse2 -msse3 -fmessage-length=0",
              "CC = #{ENV.cc} ${CCFLAGS} ${STATIC_MAKE} -fomit-frame-pointer -O3 -ffast-math " \
              "-funroll-loops -fmessage-length=0"
    inreplace "src/longread-one/Makefile", "CC_EXEC = gcc", "CC_EXEC = #{ENV.cc}"

    makefile = OS.mac? ? "Makefile.MacOS" : "Makefile.Linux"
    system "make", "-C", "src", "-f", makefile

    bin.install Dir["bin/*"].reject { |f| File.directory?(f) }
    bin.install Dir["bin/utilities/*"]
    pkgshare.install "annotation"
    doc.install Dir["doc/*.pdf"]
  end

  test do
    (testpath/"genes.saf").write <<~SAF
      GeneID\tChr\tStart\tEnd\tStrand
      gene1\tchr1\t1\t100\t+
      gene2\tchr1\t201\t300\t+
    SAF

    (testpath/"reads.sam").write <<~SAM
      @HD\tVN:1.6\tSO:coordinate
      @SQ\tSN:chr1\tLN:1000
      r1\t0\tchr1\t11\t60\t20M\t*\t0\t0\tACGTACGTACGTACGTACGT\tIIIIIIIIIIIIIIIIIIII
      r2\t0\tchr1\t41\t60\t20M\t*\t0\t0\tACGTACGTACGTACGTACGT\tIIIIIIIIIIIIIIIIIIII
      r3\t0\tchr1\t211\t60\t20M\t*\t0\t0\tACGTACGTACGTACGTACGT\tIIIIIIIIIIIIIIIIIIII
    SAM

    system bin/"featureCounts", "-F", "SAF", "-a", "genes.saf", "-o", "counts.txt", "reads.sam"
    counts = (testpath/"counts.txt").read
    assert_match(/^gene1\tchr1\t1\t100\t\+\t100\t2$/, counts)
    assert_match(/^gene2\tchr1\t201\t300\t\+\t100\t1$/, counts)

    (testpath/"ref.fa").write ">chr1\n#{"ACGTACGTGGCCATTAGCAT" * 20}\n"
    system bin/"subread-buildindex", "-o", "idx", "ref.fa"
    assert_path_exists testpath/"idx.00.b.array"
  end
end
