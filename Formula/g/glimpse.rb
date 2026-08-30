class Glimpse < Formula
  desc "Phasing and imputation for low-coverage sequencing datasets"
  homepage "https://odelaneau.github.io/GLIMPSE/"
  url "https://github.com/odelaneau/GLIMPSE/archive/refs/tags/v2.0.0.tar.gz"
  sha256 "9babfdbb4907d3528f16494f8913abb2b72676710a984becfeabe5f51c354854"
  license "MIT"
  head "https://github.com/odelaneau/GLIMPSE.git", branch: "master"

  depends_on "boost"
  depends_on "htslib"

  on_arm do
    # The phasing model is written with AVX2 intrinsics, translate them to NEON.
    depends_on "simde" => :build
  end

  def install
    # The upstream makefiles only know about the authors' own machines and
    # derive the version from a git checkout, which a release tarball is not.
    cxxflags = %W[
      -O3
      -Wno-ignored-attributes
      -D__COMMIT_ID__=\\"v#{version}\\"
      -D__COMMIT_DATE__=\\"2022-12-07\\"
    ]

    if Hardware::CPU.arm?
      (buildpath/"simde-shim/immintrin.h").write <<~C
        #include <simde/x86/avx2.h>
        #include <simde/x86/fma.h>
      C
      cxxflags += %W[
        -I#{buildpath}/simde-shim
        -I#{formula_opt_include("simde")}
        -DSIMDE_ENABLE_NATIVE_ALIASES
      ]
    end

    args = [
      "CXX=#{ENV.cxx} -std=c++17",
      "CXXFLAG=#{cxxflags.join(" ")}",
      "LDFLAG=-O3",
      "HTSLIB_INC=#{formula_opt_include("htslib")}",
      "HTSLIB_LIB=-L#{formula_opt_lib("htslib")} -lhts",
      "BOOST_INC=#{formula_opt_include("boost")}",
      "BOOST_LIB_IO=-L#{formula_opt_lib("boost")} -lboost_iostreams",
      "BOOST_LIB_PO=-lboost_program_options",
      "BOOST_LIB_SE=-lboost_serialization",
      "DYN_LIBS=-lz -lpthread",
    ]

    %w[chunk concordance ligate phase split_reference].each do |tool|
      system "make", "-C", tool, "system", *args
      bin.install "#{tool}/bin/GLIMPSE2_#{tool}"
    end

    pkgshare.install "maps"
  end

  test do
    (testpath/"reference.vcf").write <<~VCF
      ##fileformat=VCFv4.2
      ##contig=<ID=chr1,length=10000000>
      ##INFO=<ID=AC,Number=A,Type=Integer,Description="Allele count">
      ##INFO=<ID=AN,Number=1,Type=Integer,Description="Total number of alleles">
      ##FORMAT=<ID=GT,Number=1,Type=String,Description="Genotype">
      #CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\ts1\ts2
      #{(1..300).map { |i| "chr1\t#{i * 20_000}\t.\tA\tC\t.\tPASS\tAC=2;AN=4\tGT\t0|1\t1|0" }.join("\n")}
    VCF

    system formula_opt_bin("htslib")/"bgzip", "reference.vcf"
    system formula_opt_bin("htslib")/"tabix", "-p", "vcf", "reference.vcf.gz"

    system bin/"GLIMPSE2_chunk", "--input", "reference.vcf.gz", "--region", "chr1",
           "--sequential", "--window-count", "50", "--buffer-count", "10",
           "--output", "chunks.txt"

    chunks = (testpath/"chunks.txt").read.lines.map { |line| line.split("\t") }
    refute_empty chunks
    assert_equal "chr1", chunks[0][1]
    assert_equal 300, chunks.sum { |chunk| chunk[6].to_i }

    assert_match version.to_s, shell_output("#{bin}/GLIMPSE2_phase --help")
  end
end
