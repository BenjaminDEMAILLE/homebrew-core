class Taxonkit < Formula
  desc "NCBI taxonomy toolkit"
  homepage "https://bioinf.shenwei.me/taxonkit/"
  url "https://github.com/shenwei356/taxonkit/archive/refs/tags/v0.20.0.tar.gz"
  sha256 "eb5a6641264f84997eaa22df7c9cad735c100b434dfd62c2560aba78164f34f6"
  license "MIT"
  head "https://github.com/shenwei356/taxonkit.git", branch: "master"

  depends_on "go" => :build

  def install
    system "go", "build", *std_go_args(ldflags: "-s -w"), "./taxonkit"
  end

  test do
    # A cut-down NCBI taxonomy dump: root, Bacteria, Proteobacteria, E. coli.
    (testpath/"nodes.dmp").write <<~EOS
      1\t|\t1\t|\tno rank\t|
      2\t|\t1\t|\tsuperkingdom\t|
      1224\t|\t2\t|\tphylum\t|
      562\t|\t1224\t|\tspecies\t|
    EOS
    (testpath/"names.dmp").write <<~EOS
      1\t|\troot\t|\t\t|\tscientific name\t|
      2\t|\tBacteria\t|\t\t|\tscientific name\t|
      1224\t|\tProteobacteria\t|\t\t|\tscientific name\t|
      562\t|\tEscherichia coli\t|\t\t|\tscientific name\t|
    EOS

    lineage = pipe_output("#{bin}/taxonkit lineage --data-dir #{testpath} 2>/dev/null", "562\n")
    assert_equal "562\tBacteria;Proteobacteria;Escherichia coli", lineage.strip

    name = pipe_output("#{bin}/taxonkit name2taxid --data-dir #{testpath} 2>/dev/null",
                       "Escherichia coli\n")
    assert_match "562", name
  end
end
