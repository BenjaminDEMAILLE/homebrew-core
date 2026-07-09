class Nanoq < Formula
  desc "Fast quality control and summary for nanopore reads"
  homepage "https://github.com/esteinig/nanoq"
  url "https://github.com/esteinig/nanoq/archive/refs/tags/0.10.0.tar.gz"
  sha256 "c6ab28a5c738be950bfbf36ddf9e0e46216a9a1aa040d6745fcb9d87cc32534a"
  license "MIT"
  head "https://github.com/esteinig/nanoq.git", branch: "master"

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/nanoq --version")
    (testpath/"reads.fq").write "@r1\nACGTACGTACGTACGT\n+\nIIIIIIIIIIIIIIII\n"
    assert_match "1", shell_output("#{bin}/nanoq -i #{testpath}/reads.fq -s 2>&1")
  end
end
