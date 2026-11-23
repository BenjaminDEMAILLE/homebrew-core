class Trinity < Formula
  include Language::Python::Shebang

  desc "RNA-Seq de novo transcriptome assembler"
  homepage "https://github.com/trinityrnaseq/trinityrnaseq/wiki"
  url "https://github.com/trinityrnaseq/trinityrnaseq/releases/download/Trinity-v2.16.2/trinityrnaseq-v2.16.2.FULL.tar.gz"
  sha256 "79012da5c2ea882cc1c57d7d782e1b5d13a076a02c2b6f32b3bbcf75b93bea0a"
  license "BSD-3-Clause"

  livecheck do
    url :stable
    regex(/^Trinity[._-]v?(\d+(?:\.\d+)+)$/i)
    strategy :github_latest
  end

  depends_on "cmake" => :build
  depends_on "bowtie2"
  depends_on "htslib"
  depends_on "jellyfish"
  depends_on "numpy"
  depends_on "openjdk"
  depends_on "python@3.14"
  depends_on "salmon"
  depends_on "samtools"

  uses_from_macos "perl"
  uses_from_macos "zlib"

  on_macos do
    depends_on "libomp"
  end

  def install
    # Remove prebuilt binaries and jars, rebuilt from source below
    prebuilt = %w[cigar_tweaker fastaToKmerCoverageStats inchworm SNP_stomper pull_reads_with_kmers FastaToDeBruijn]
    rm prebuilt.map { |f| "Inchworm/src/#{f}" }
    rm ["Butterfly/Butterfly.jar", "Butterfly/Butterfly/Butterfly.jar", "util/support_scripts/ExitTester.jar"]
    rm_r ["trinity-plugins/Trimmomatic-0.36", "trinity-plugins/COLLECTL",
          "trinity-plugins/bamsifter/htslib-1.22.1.tar.bz2"]

    if OS.mac?
      inreplace ["Inchworm/CMakeLists.txt", "Chrysalis/CMakeLists.txt"] do |s|
        s.gsub! "-fopenmp", "-Xpreprocessor -fopenmp"
        s.gsub! "-static-libstdc++", "-lomp"
      end
    end
    %w[Inchworm Chrysalis].each do |dir|
      system "cmake", "-S", dir, "-B", "#{dir}/build", *std_cmake_args(install_prefix: buildpath/dir)
      system "cmake", "--build", "#{dir}/build"
      system "cmake", "--install", "#{dir}/build"
    end

    cd "trinity-plugins" do
      openmp = OS.mac? ? "-Xpreprocessor -fopenmp" : "-fopenmp"
      cd "ParaFly" do
        args = ["CXXFLAGS=#{openmp}"]
        args << "LIBS=-lomp" if OS.mac?
        system "./configure", *args, *std_configure_args(prefix: Dir.pwd)
        system "make", "install"
      end
      system "make", "-C", "seqtk-trinity", "CC=#{ENV.cc}"
      system "make", "-C", "bamsifter", "CXX=#{ENV.cxx}", "HTSLIB_PREFIX=#{formula_opt_prefix("htslib")}"
      cp ["ParaFly/bin/ParaFly", "seqtk-trinity/seqtk-trinity"], "BIN"
      rm_r %w[ParaFly seqtk-trinity]
    end

    javac = Formula["openjdk"].bin/"javac"
    jar = Formula["openjdk"].bin/"jar"
    cd "Butterfly/Butterfly/src" do
      libs = %w[collections-generic-4.01 java-getopt-1.0.13 jung-algorithms-2.0.1 jung-api-2.0.1
                jung-graph-impl-2.0.1].map { |l| "lib/#{l}.jar" }
      system javac, "-nowarn", "-encoding", "UTF-8", "-d", "classes", "-cp", libs.join(":"), *Dir["src/**/*.java"]
      (Pathname.pwd/"manifest.txt").write "Main-Class: TransAssembly_allProbPaths\nClass-Path: #{libs.join(" ")}\n"
      system jar, "cfm", buildpath/"Butterfly/Butterfly.jar", "manifest.txt", "-C", "classes", "."
      (buildpath/"Butterfly/lib").install libs
    end

    # Upstream ships ExitTester.jar without source: it only exits with the given status
    mkdir "exittester" do
      (Pathname.pwd/"ExitTester.java").write <<~JAVA
        public class ExitTester {
          public static void main(String[] args) { System.exit(Integer.parseInt(args[0])); }
        }
      JAVA
      system javac, "ExitTester.java"
      system jar, "cfe", buildpath/"util/support_scripts/ExitTester.jar", "ExitTester", "ExitTester.class"
    end

    rm_r %w[Butterfly/Butterfly Docker WDL benchmarking trinityrnaseq.wiki trinity_ext_sample_data exittester
            Inchworm/build Chrysalis/build]
    libexec.install Dir["*"]
    rewrite_shebang detected_python_shebang, *libexec.glob("**/*").select(&:file?)
    (bin/"Trinity").write_env_script libexec/"Trinity", PATH: "#{formula_opt_bin("openjdk")}:$PATH"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/Trinity --version --no_version_check")

    # Subset of the bundled sample reads keeps the assembly to a few seconds
    %w[left right].each do |side|
      reads = Zlib::GzipReader.open(libexec/"sample_data/test_Trinity_Assembly/reads.#{side}.fq.gz") do |gz|
        gz.each_line.first(20_000)
      end
      (testpath/"#{side}.fq").write reads.join
    end
    system bin/"Trinity", "--seqType", "fq", "--max_memory", "1G", "--CPU", "2", "--no_version_check",
                          "--left", "left.fq", "--right", "right.fq", "--output", "trinity_out"
    assert_match ">TRINITY_DN", (testpath/"trinity_out.Trinity.fasta").read
  end
end
