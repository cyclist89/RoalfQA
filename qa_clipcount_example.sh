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
dti_file=$1
mask_file=$2
result_file=$3
in_dir=`dirname ${dti_file}`
in_root=`basename ${dti_file} .nii.gz`
out_dir=`dirname ${result_file}`

# --- Find voxels which exceeded 4095 at any time ---
fslmaths $dti_file -mas $mask_file -Tmax -thr 4095 -bin $out_dir/${in_root}_clipmask -odt char
gzip "${out_dir}/${in_root}_clipmask.nii"

count=(`fslstats $out_dir/${in_root}_clipmask -V`)
echo -e "clipcount: ${count[0]}" >> $result_file

exit 0


