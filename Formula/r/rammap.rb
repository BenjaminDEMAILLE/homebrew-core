class Rammap < Formula
  desc "Pure-Rust minimap2-compatible sequence aligner and read mapper"
  homepage "https://github.com/jwanglab/rammap"
  url "https://github.com/jwanglab/rammap/archive/refs/tags/v1.1.1.tar.gz"
  sha256 "1693880fd550b28c49f143ddb22f8a17941a80935eebd0f82bef6e93e65c9f6f"
  license "MIT"
  head "https://github.com/jwanglab/rammap.git", branch: "main"

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args(path: "rammap")
  end

  test do
    ref = "CAGATTTTCATATTATGCAGAAAATCTACTTCGCCTGATACGAGTCGGTTATCTTCGGATAC" \
          "TGTATAGTCCCACCTGGTGATCCTATGCTTGTGAGTACCCAGAAAATAGCGACGGACCGCGG" \
          "TGTTAAGTGTCGAGCTACATCACTTCTCATGTAGCCAGAAGGCTGCAACTCATCGACTCTAT" \
          "GTAGTGACCGCGTC"
    (testpath/"ref.fa").write ">chr1\n#{ref}\n"
    (testpath/"read.fa").write ">r1\n#{ref[40, 120]}\n"

    paf = shell_output("#{bin}/rammap #{testpath}/ref.fa #{testpath}/read.fa")
    # PAF: query name, then target name in column 6, on a successful alignment
    assert_match(/\Ar1\t.*\tchr1\t/, paf)
  end
end
