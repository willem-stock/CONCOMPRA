#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script for filtering out the minimap2 output to avoid multiple hits per
sequence. When it finds a sequences with >1 hits, it will print only the
largest alignment. If both alignments have the same length, it will arbritarily
choose one.

Moreover, reads with a block lenght alignment < 500 pb will be also removed
by default. In our test dataset, 25% of the hits in the raw PAF file had a
block length < 500 p.b.

For more info about PAF format please visit: 
    https://github.com/lh3/miniasm/blob/master/PAF.md

@author: Adriel Latorre-Pérez
@company: Darwin Bioprospecting Excellence S.L.
@date: 15/10/2020

edited for CONCOMPRA: introduction of variable block length alignment parameter & Mapping quality threshold
"""

import sys
from argparse import ArgumentParser 

def Arguments():
    """For input file.
    """
    parser = ArgumentParser (description ="Script for filtering out the \
                            minimap2 output to avoid multiple hits per\
                            sequence. When it finds a sequences with >1 hits, \
                            it will print only the largest alignment.")
    parser.add_argument ('-i', '--input', dest='fileRoute',
                           action ='store', required =True ,
                           help='Path to PAF file')
    parser.add_argument('-b', type=float, action ='store', default=500,
                            dest='blockLimit',help='an decimal for the block length')
    parser.add_argument('-m', type=int, action ='store', default=30,
                            dest='MapQthreshold',help='an integer for the mapping qualtiy threshold')    

    try:
        args = parser.parse_args ()
        return args
    except:
        print('Please, include the required arguments.')
        sys.exit()
    # end try
    
def filterPAF(fileRoute, blockLimit,MapQthreshold):
    """
    Takes an input PAF and prints to stdout a filtered PAF with unique hits. 
    Hits with the largest block length will be kept. Also, it will remove any
    hit with a block length < blockLimit.

    Parameters
    ----------
    fileRoute : STRING
        Path to file.
    blockLimit : INT, optional
        Hits with a block length alingment lower than this parameter will be
        removed. The default is 500.

    Returns
    -------
    None.

    """
    file = open (fileRoute)
    hits = {} # to temporally store the hits
    
    # Filter the PAF file and store the output in hits
    for line in file:
        line = line.strip()
        fields = line.split("\t")
        seq = fields[0]
        blockLength = int(fields[10])
        MapQ = int(fields[11])
        
        if blockLength >= blockLimit and MapQ>MapQthreshold:
            if seq not in hits:
                hits[seq] = [blockLength, line]
            else:
                if hits[seq][0] < blockLength:
                    hits[seq] = [blockLength, line]
    
    # Print the output to stdout
    for hit in hits:
        print (hits[hit][1])
    
    file.close()
   
if __name__ == "__main__":
   args = Arguments()
   filterPAF(args.fileRoute, args.blockLimit, args.MapQthreshold)
   
