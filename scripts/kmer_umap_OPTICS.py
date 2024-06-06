# Part of this script is based on the implementation of NanoCLUST https://github.com/genomicsITER/NanoCLUST
# Please also acknowledge those authors when using this script

# Integrated k-mer sequence feature approach
import warnings
from numba.core.errors import NumbaDeprecationWarning, NumbaPendingDeprecationWarning
# Suppress numba jit deprecation warning from UMAP (fixed version in conda environment)
warnings.simplefilter('ignore', category=NumbaDeprecationWarning)
warnings.simplefilter('ignore', category=NumbaPendingDeprecationWarning)

# Imported libraries
from sklearn.feature_extraction.text import CountVectorizer
from Bio import SeqIO
import sys
import numpy as np
import umap
import matplotlib.pyplot as plt
import pandas as pd
from sklearn.cluster import OPTICS

# Read sequences from a FASTA file
records = list(SeqIO.parse(sys.argv[1], "fasta"))

sequences = [str(record.seq) for record in records]
ids = [str(record.id) for record in records]

# Create a k-mer vectorizer
kmer_size = 3
vectorizer = CountVectorizer(analyzer='char', ngram_range=(kmer_size, kmer_size), dtype=np.uint8, binary=False, max_features=10000) # CountVectorizer(analyzer='char', ngram_range=(kmer_size, kmer_size))

# Transform sequences into a k-mer feature matrix
X_kmer = vectorizer.fit_transform(sequences) #.toarray()

# UMAP
X_embedded = umap.UMAP(n_neighbors=10, min_dist=0.1, verbose=2, low_memory=False).fit_transform(X_kmer)  #set low_memory=True for systems with lower memory/very large files

# Create DataFrame for UMAP embedding
df_umap = pd.DataFrame(X_embedded, columns=["D1", "D2"])

# OPTICS
optics_model = OPTICS(min_samples=50, xi=0.02, min_cluster_size=0.005,n_jobs=int(sys.argv[2]))  # Adjust parameters as needed
optics_model.fit(X_embedded)
bin_id = optics_model.labels_

# Plot the clusters
plt.figure(figsize=(20, 20))
plt.scatter(X_embedded[:, 0], X_embedded[:, 1], c=bin_id, cmap='Spectral', s=1)
plt.xlabel("UMAP1", fontsize=18)
plt.ylabel("UMAP2", fontsize=18)
plt.gca().set_aspect('equal', 'datalim')
plt.savefig('fig.optics.output.png')

# Create DataFrame for clustering results
clust_df = pd.DataFrame({
    'read': ids,
    'bin_id': bin_id
})
clust_df.to_csv("freqs.txthdbscan.output.tsv", sep="\t", index=False)


