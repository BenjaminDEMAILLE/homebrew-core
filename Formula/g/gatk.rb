class Gatk < Formula
  desc "Genome Analysis Toolkit for variant discovery in sequencing data"
  homepage "https://gatk.broadinstitute.org/"
  url "https://github.com/broadinstitute/gatk/releases/download/4.7.0.0/gatk-4.7.0.0.zip"
  sha256 "d093d2693b1626361a413ca59d6d4a0bf968717f280a8fd9ce060b25eb2ed1db"
  license "Apache-2.0"

  livecheck do
    url :stable
    strategy :github_latest
  end

  depends_on "openjdk"

  def install
    libexec.install "gatk-package-#{version}-local.jar"
    # Upstream's launcher is a Python script that also drives spark-submit and gcloud;
    # this reproduces its local jar invocation, including `--java-options`.
    (bin/"gatk").write <<~BASH
      #!/bin/bash
      export JAVA_HOME="${JAVA_HOME:-#{Language::Java.java_home}}"
      java_options=(-Dsamjdk.use_async_io_read_samtools=false
                    -Dsamjdk.use_async_io_write_samtools=true
                    -Dsamjdk.use_async_io_write_tribble=false
                    -Dsamjdk.compression_level=2)
      gatk_args=()
      while (($#)); do
        if [[ "$1" == "--java-options" ]]; then
          if [[ $# -lt 2 ]]; then
            echo "gatk: --java-options requires an argument" >&2
            exit 2
          fi
          read -r -a option <<< "$2"
          java_options+=("${option[@]}")
          shift 2
        else
          gatk_args+=("$1")
          shift
        fi
      done
      exec "${JAVA_HOME}/bin/java" "${java_options[@]}" $JAVA_OPTS \\
        -jar "#{libexec}/gatk-package-#{version}-local.jar" "${gatk_args[@]}"
    BASH
    bash_completion.install "gatk-completion.sh"
  end

  test do
    (testpath/"ref.fasta").write <<~EOS
      >chr1
      GCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGCTAGC
      TTTTGGGGCCCCAAAATTTTGGGGCCCCAAAATTTTGGGGCCCCAAAATT
    EOS
    system bin/"gatk", "--java-options", "-Xmx1g", "CreateSequenceDictionary", "-R", "ref.fasta"
    assert_match "SN:chr1\tLN:100", (testpath/"ref.dict").binread

    (testpath/"in.vcf").write <<~EOS
      ##fileformat=VCFv4.2
      ##contig=<ID=chr1,length=100>
      #CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO
      chr1\t10\t.\tA\tG\t50\t.\t.
      chr1\t20\t.\tC\tT\t20\t.\t.
    EOS
    system bin/"gatk", "VariantFiltration", "-V", "in.vcf", "-O", "out.vcf",
           "--filter-name", "LowQual", "--filter-expression", "QUAL < 30"
    assert_match "LowQual", (testpath/"out.vcf").binread
  end
end
