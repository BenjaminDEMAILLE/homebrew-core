class Whatshap < Formula
  include Language::Python::Virtualenv

  desc "Read-based phasing of genomic variants"
  homepage "https://whatshap.readthedocs.io/"
  url "https://files.pythonhosted.org/packages/1c/1a/78c4c6d188bea81d146b7e73fe12cf3e2d3c2b0e69542a2ca806908b6fa3/whatshap-2.8.tar.gz"
  sha256 "073ee7946d563e0125dbce58d9fc86a7a3fae377f27859dacb398309374b2cbe"
  license "MIT"
  head "https://github.com/whatshap/whatshap.git", branch: "main"

  depends_on "cython" => :build
  depends_on "python-setuptools" => :build
  depends_on "cbc"
  depends_on "python@3.14"
  depends_on "scipy"

  resource "biopython" do
    url "https://files.pythonhosted.org/packages/f6/a0/cf657d076ec56a5f9e5c29a560c1f97b8eb6ae6608dc8bc95b4e2437f129/biopython-1.88.tar.gz"
    sha256 "9aaa31c0bda4d059f7b2ee00bfdb5cbb73ade3057aa4b737a7cc0187091d071a"
  end

  resource "networkx" do
    url "https://files.pythonhosted.org/packages/6a/51/63fe664f3908c97be9d2e4f1158eb633317598cfa6e1fc14af5383f17512/networkx-3.6.1.tar.gz"
    sha256 "26b7c357accc0c8cde558ad486283728b65b6a95d85ee1cd66bafab4c8168509"
  end

  resource "packaging" do
    url "https://files.pythonhosted.org/packages/7d/fa/3944b40b07da9ce895c0e6303a5ab7d53da063554f534556b134a54d6093/packaging-26.3.tar.gz"
    sha256 "94edc256424af38762eb31306eed28beb9f0efc50a8837492c9d6fd6004aed79"
  end

  resource "pulp" do
    url "https://files.pythonhosted.org/packages/4e/70/69be07a67621ad804d6cf347965eb4e0d7786a97330d99c31d735aaa6c5a/pulp-3.3.2.tar.gz"
    sha256 "d0904700c207ac11e25e3b1213b70eae1d6fb25faa719d75f3f15054901258c0"
  end

  resource "pyfaidx" do
    url "https://files.pythonhosted.org/packages/19/af/da148aaa8e75c9890a41dbe5516f8006def2b74831e66acf79f81bb7bb5b/pyfaidx-0.9.0.4.tar.gz"
    sha256 "801bdd208b12bff6f4fb2da10a16834158dbb1c6f146e4015c9ff45e509acd65"
  end

  resource "pysam" do
    url "https://files.pythonhosted.org/packages/09/9b/e856ad525ed0847810cca936ee551b8e0a709525fea34e0e0e723173f62d/pysam-0.24.0.tar.gz"
    sha256 "db0f86c15532ef5dad263748324f45d9a639668e3497d8cabce54ef47a1a78d9"
  end

  resource "xopen" do
    url "https://files.pythonhosted.org/packages/77/bb/74a5222fc975fccb9f8bfb62613ca42a5a28008362c598df09806ecd12c1/xopen-2.1.0.tar.gz"
    sha256 "06584821588f813563863b63d5e02568a4328661b7507ea38c432f24c69ea4b7"
  end

  def install
    virtualenv_install_with_resources

    # Remove the pre-built CBC solvers that PuLP vendors for every platform;
    # `whatshap polyphase` picks up the `cbc` formula from PATH instead.
    rm(Dir[libexec/"lib/python*/site-packages/pulp/solverdir/cbc/*/*/{cbc,cbc.exe}"])
  end

  test do
    (testpath/"phased.vcf").write <<~VCF
      ##fileformat=VCFv4.2
      ##contig=<ID=chr1,length=1000>
      ##FORMAT=<ID=GT,Number=1,Type=String,Description="Genotype">
      ##FORMAT=<ID=PS,Number=1,Type=Integer,Description="Phase set">
      #CHROM	POS	ID	REF	ALT	QUAL	FILTER	INFO	FORMAT	sample
      chr1	100	.	A	C	.	PASS	.	GT:PS	0|1:100
      chr1	200	.	G	T	.	PASS	.	GT:PS	1|0:100
      chr1	500	.	C	A	.	PASS	.	GT	0/1
    VCF

    system bin/"whatshap", "stats", "--tsv=stats.tsv", "phased.vcf"
    stats = (testpath/"stats.tsv").read.lines.map(&:split)
    columns = stats[0].zip(stats[1]).to_h
    assert_equal "3", columns["variants"]
    assert_equal "2", columns["phased"]
    assert_equal "1", columns["blocks"]

    unphased = shell_output("#{bin}/whatshap unphase phased.vcf")
    refute_match(/	0\|1/, unphased)

    assert_match version.to_s, shell_output("#{bin}/whatshap --version")
  end
end
