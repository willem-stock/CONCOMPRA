# primer-chop

`primer-chop` classifies cDNA reads as forward (sense) or reverse
(antisense) strands, by analyzing primer sequences, and chops off the
primers.  Each read is expected to have a "head" primer at one end
(the 5'-end of the original RNA), and a "tail" primer at the other
end.

## Requirements

[LAST](https://gitlab.com/mcfrith/last) **version >= 1387** needs to
be installed (i.e. in your PATH).

## Usage

    primer-chop primers.fa reads.fq output-directory

The reads may be in either fasta (`.fa`) or fastq (`.fq`) format, and
they may be gzipped (`.gz`).  You can make it faster by specifying
(say) 8 parallel threads:

    primer-chop -P8 primers.fa reads.fq output-directory

## Output

`primer-chop` will make the `output-directory` (which must not already
exist) and put several files in it:

* `good-fwd.fa`: sequences from forward (sense) reads with both
  primers in the expected positions.

* `good-rev.fa`: sequences from reverse (antisense) reads with both
  primers in the expected positions.

* `no_head-fwd.fa`: sequences from forward (sense) reads with good
  tail primer but no detectable head primer.

* `no_head-rev.fa`: sequences from reverse (antisense) reads with good
  tail primer but no detectable head primer.

* `no_tail-fwd.fa`: likewise.

* `no_tail-rev.fa`: likewise.

* `log.txt`: IDs of reads with no detected primers, or weird primers
  perhaps indicating chimerism.  (Some clearly-chimeric reads could be
  rescued, but `primer-chop` doesn't currently do that.)

* `last-train.txt`: output of
  [last-train](https://gitlab.com/mcfrith/last/-/blob/main/doc/last-train.rst).
  You can probably ignore this, but it may be useful for
  troubleshooting.

In the output sequence files, the detected primers are chopped off.
Also, poly-A tails next to the tail primer are chopped off.  The "rev"
sequences are the opposite strands of the original reads, so all the
output sequences are sense (forward) strands.

Primers are considered "weird" if:

* There is more than 1 head or tail primer.

* The head and tail strands are inconsistent.

* The total length of chopped sequence would be >= the original
  sequence length (e.g. if the primers overlap).

* There are > 100 bases before the head primer, or after the tail
  primer.  (This allows for "adapter" sequences outside the primers.
  So it's not necessary to chop the adapters using another tool such
  as porechop.  In fact, porechop seems to chop parts of the primers,
  harming this analysis!)

## Keeping fastq

By default, the output is fasta format, which is smaller than fastq.
The `-q` option makes the output format the same as the input format:

    primer-chop -q primers.fa reads.fq output-directory

## Keeping the primers

Option `-n` makes it not chop anything off:

    primer-chop -n primers.fa reads.fq output-directory

## Primer fasta files

Two example primer files are included.  You can make a new primer file
by following these rules:

* The head primer should have "head" in its name (case-insensitive).
  Likewise for the tail primer.

* Both sequences should be those that appear in the cDNA's sense
  strand.

* The tail sequence should start with poly-A long enough to cover any
  poly-A tail you'd like to chop.  (300 bases seems plenty.)

* "Low-complexity" sequence (including the poly-A tail) should be
  lowercase, and all other bases uppercase.

## Not sure which primers were used?

Run `primer-chop` with both primer files on a small sample of your
reads.  Hopefully, one primer file will give you much more "good"
reads.

## Aligning the chopped reads to a genome

We can align the chopped reads in [the usual
way](https://github.com/mcfrith/last-rna/blob/master/last-long-reads.md).
First, prepare the genome:

    lastdb -P8 -uNEAR mydb genome.fa

Next we use `last-train` to determine the rates of insertion,
deletion, and substitutions; then align the reads to the genome,
allowing for splicing:

    last-train -P8 -Q0 mydb *-fwd.fq > fwd.par

    lastal -P8 -p fwd.par -d90 -m20 -D10 --splice mydb good-fwd.fq > good-fwd.maf

The "fwd" and "rev" reads may have different substitution rates (due
to strand-asymmetric sequencing error rates), so we do them
separately:

    last-train -P8 -Q0 mydb *-rev.fq > rev.par

    lastal -P8 -p rev.par -d90 -m20 -D10 --splice mydb good-rev.fq > good-rev.maf

If desired, prepare alternative alignment formats:

    maf-convert -j1e6 psl good-*.maf > good.psl
    pslToBed good.psl good.bed

The psl file may be analyzed with
[rna-alignment-stats](https://github.com/mcfrith/last-rna).

### Genome alignment caveats

* The results include low-confidence alignments.  In the maf files,
  each alignment has a "mismap" probability, which is the estimated
  probability that it's aligned to the wrong place.

* There are probably some incorrect alignments to processed
  pseudogenes.  It's hard to avoid these completely.  (There may also
  be correct alignments to processed pseudogenes.)
