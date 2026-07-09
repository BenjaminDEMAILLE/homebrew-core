class Chopper < Formula
  desc "Filter and trim long-read sequencing data"
  homepage "https://github.com/wdecoster/chopper"
  url "https://github.com/wdecoster/chopper/archive/refs/tags/v0.13.0.tar.gz"
  sha256 "f5df330e68e76ceb62f33338be7f7c21bd876e2ad84baa9e50ecbcfdfbd9d232"
  license "MIT"
  head "https://github.com/wdecoster/chopper.git", branch: "master"

  depends_on "cmake" => :build
  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/chopper --version 2>&1")
    (testpath/"reads.fq").write "@r1\n#{"ACGT" * 40}\n+\n#{"I" * 160}\n"
    output = pipe_output("#{bin}/chopper -q 5 -l 50 2>/dev/null", File.read(testpath/"reads.fq"))
    assert_match "@r1", output
  end
end
