class Miniasm < Formula
  desc "Ultrafast de novo assembly for long noisy reads"
  homepage "https://github.com/lh3/miniasm"
  url "https://github.com/lh3/miniasm/archive/refs/tags/v0.3.tar.gz"
  sha256 "9b688454f30f99cf1a0b0b1316821ad92fbd44d83ff0b35b2403ee8692ba093d"
  license "MIT"
  head "https://github.com/lh3/miniasm.git", branch: "master"

  uses_from_macos "zlib"

  def install
    system "make", "CC=#{ENV.cc}"
    bin.install "miniasm", "minidot"
    man1.install "miniasm.1"
  end

  test do
    # Sixteen 5 kb reads tiling a 20 kb sequence in 1 kb steps, with the
    # all-versus-all overlaps minimap2 would report for them.
    rng = Random.new(3)
    genome = Array.new(20_000) { "ACGT"[rng.rand(4)] }.join
    reads = (0..15).map { |i| ["r#{i + 1}", genome[i * 1_000, 5_000]] }
    (testpath/"reads.fa").write(reads.map { |name, seq| ">#{name}\n#{seq}\n" }.join)

    paf = reads.each_with_index.flat_map do |(qname, _), i|
      reads.each_with_index.filter_map do |(tname, _), j|
        overlap = 5_000 - ((j - i) * 1_000)
        next if j <= i || overlap < 2_000

        [qname, 5_000, (j - i) * 1_000, 5_000, "+", tname, 5_000, 0,
         overlap, overlap, overlap, 60].join("\t")
      end
    end
    (testpath/"ovl.paf").write "#{paf.join("\n")}\n"

    gfa = shell_output("#{bin}/miniasm -c 1 -f reads.fa ovl.paf 2>/dev/null")
    assert_match(/^S\tutg000001l\t[ACGT]{5000,}/, gfa)

    assert_match "%!PS-Adobe-3.0 EPSF-3.0", shell_output("#{bin}/minidot ovl.paf")
  end
end
