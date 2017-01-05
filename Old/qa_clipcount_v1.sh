#!/bin/bash
# ---------------------------------------------------------------
# QA_CLIPCOUNT.sh - find number of voxels with clipped amplitude (i.e. >= 4095)
#
# M. Elliott - 5/2013
# Edited by K. Sambrook - 1/2017

# --------------------------
Usage() {
	echo "usage: `basename $0` [-append] [-keep] <4Dinput> [<maskfile>] <resultfile>"
    exit 1
}
# --------------------------

# --- Perform standard qa_script code ---
source /mnt/stressdevlab/scripts/DTI/QA/qa_preamble.sh

# --- Parse inputs ---
if [ $# -lt 2 -o $# -gt 3 ]; then Usage; fi
infile=`imglob -extension $1`
indir=`dirname $infile` 
inbase=`basename $infile`
inroot=`remove_ext $inbase`
maskfile=""
if [ $# -gt 2 ]; then
    maskfile=`imglob -extension $2`
    shift
fi
resultfile=$2
outdir=`dirname $resultfile`

# --- start result file ---
if [ $append -eq 0 ]; then 
    echo -e "modulename\t$0"      > $resultfile
    echo -e "version\t$VERSION"  >> $resultfile
    echo -e "inputfile\t$infile" >> $resultfile
fi   
 
# --- Find voxels which exceeded 4095 at any time ---
if [ "X${maskfile}" = "X" ]; then
    fslmaths $infile -mas $maskfile -Tmax -thr 4095 -bin $outdir/${inroot}_clipmask -odt char
fi
count=(`fslstats $outdir/${inroot}_clipmask -V`)
echo -e "clipcount\t${count[0]}" >> $resultfile

exit 0


