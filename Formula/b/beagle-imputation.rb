class BeagleImputation < Formula
  desc "Genotype imputation and haplotype phasing"
  homepage "https://faculty.washington.edu/browning/beagle/beagle.html"
  # Upstream has no version control system and names every source release
  # after its date; the jar reports this one as Beagle 5.5 / 27Feb25.75f.
  url "https://faculty.washington.edu/browning/beagle/beagle.250227.zip"
  sha256 "12521996021dbd79f8140e8adbb91c3f73bec51fd795a6594525bbe9fd486d23"
  license "GPL-3.0-or-later"

  livecheck do
    url :homepage
    regex(/href=.*?beagle\.?v?(\d+)\.zip/i)
  end

  depends_on "openjdk"

  def install
    # The zip contains a single `src` directory, which Homebrew strips when
    # staging, so look for the sources both with and without that prefix.
    mkdir "classes"
    system "javac", "-nowarn", "-d", "classes", *Dir["**/*.java"]

    {
      "beagle"  => "main.Main",
      "bref3"   => "bref.Bref3",
      "unbref3" => "bref.UnBref3",
    }.each do |name, main_class|
      system "jar", "--create", "--file", "#{name}.jar", "--main-class", main_class, "-C", "classes", "."
      libexec.install "#{name}.jar"
      bin.write_jar_script libexec/"#{name}.jar", name
    end
  end

  test do
    samples = (1..10).map { |i| "s#{i}" }
    genotypes = ["0/0", "0/1", "1/1"]
    records = (1..30).map do |marker|
      calls = samples.each_index.map { |i| genotypes[(marker + i) % 3] }
      calls[3] = "./." if marker == 7
      "1\t#{marker * 1000}\tm#{marker}\tA\tC\t.\tPASS\t.\tGT\t#{calls.join("\t")}"
    end

    (testpath/"test.vcf").write <<~VCF
      ##fileformat=VCFv4.2
      ##contig=<ID=1,length=1000000>
      ##FORMAT=<ID=GT,Number=1,Type=String,Description="Genotype">
      #CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\t#{samples.join("\t")}
      #{records.join("\n")}
    VCF

    system bin/"beagle", "gt=test.vcf", "out=phased", "nthreads=1"
    assert_path_exists testpath/"phased.vcf.gz"

    output = Utils.safe_popen_read("gunzip", "-c", "phased.vcf.gz")
    calls = output.lines.grep_v(/^#/).map { |line| line.split("\t").drop(9) }
    assert_equal 30, calls.length
    # Every genotype is phased and the missing call has been imputed.
    assert_empty calls.flatten.grep_v(/^[01]\|[01]$/)

    system bin/"bref3", "phased.vcf.gz"
  end
end
