class RustarAligner < Formula
  desc "Rust reimplementation of STAR, the RNA-seq aligner"
  homepage "https://scverse.org/rustar-aligner/"
  url "https://github.com/scverse/rustar-aligner/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "36bc9b578bfec649b0339642a8eb0cce6bbdf1d8f6ab7a63e7848b0e4ad8e443"
  license "MIT"
  head "https://github.com/scverse/rustar-aligner.git", branch: "main"

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    assert_match "rustar-aligner", shell_output("#{bin}/rustar-aligner --version")

    (testpath/"genome.fa").write <<~FASTA
      >chr1
      GATCACAGGTCTATCACCCTATTAACCACTCACGGGAGCTCTCCATGCATTTGGTATTTTC
      GTCTGGGGGGTATGCACGCGATAGCATTGCGAGACGCTGGAGCCGGAGCACCCTATGTCGC
    FASTA

    system bin/"rustar-aligner", "--runMode", "genomeGenerate",
           "--genomeDir", testpath/"index",
           "--genomeFastaFiles", testpath/"genome.fa",
           "--genomeSAindexNbases", "2"
    assert_path_exists testpath/"index/SA"
  end
end
