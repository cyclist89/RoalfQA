#!/bin/bash
# ---------------------------------------------------------------
# QA_MOTION.sh - compute motion metrics from 4D Nifti
#
# M. Elliott - 6/2013

# --------------------------
Usage() {
	echo "usage: `basename $0` [-append] [-keep] <4Dinput> <resultfile>"
    exit 1
}
# --------------------------

# --- Perform standard qa_script code ---
source /mnt/stressdevlab/scripts/DTI/QA/qa_preamble.sh

# --- Parse inputs ---
b0_masked_file=$1
result_file=$2
in_dir=`dirname ${b0_masked_file}`
in_root=`basename ${b0_masked_file} .nii.gz`
out_dir=`dirname ${result_file}`

# --- Check for enough time points ---
nreps=`fslval $b0_masked_file dim4`
echo ${nreps}
if [ $nreps -lt 4 ]; then 
    echo "ERROR. Need at least 4 volumes to calculate tsnr metrics."
    echo -e "meanABSrms: -1"   >> $result_file
    echo -e "meanRELrms: -1" >> $result_file
    echo -e "maxABSrms: -1" >> $result_file
    echo -e "maxRELrms: -1" >> $result_file
    exit 1
fi

# --- moco ---
mcflirt -rmsrel -rmsabs -verbose 0 -in $b0_masked_file -refvol 0 -out $out_dir/${in_root}_mc >&/dev/null
gzip "${out_dir}/${in_root}_mc.nii"
meanABSrms=`cat $out_dir/${in_root}_mc_abs_mean.rms`
meanRELrms=`cat $out_dir/${in_root}_mc_rel_mean.rms`
mv $out_dir/${in_root}_mc_abs.rms $out_dir/${in_root}_mc_abs.1D   # strange behavior of 3dTstat - needs file to end in .1D
mv $out_dir/${in_root}_mc_rel.rms $out_dir/${in_root}_mc_rel.1D
maxABSrms=`3dTstat -max -prefix - $out_dir/${in_root}_mc_abs.1D\' 2>/dev/null`  
maxRELrms=`3dTstat -max -prefix - $out_dir/${in_root}_mc_rel.1D\' 2>/dev/null`  

echo -e "meanABSrms: $meanABSrms" >> $result_file
echo -e "meanRELrms: $meanRELrms" >> $result_file
echo -e "maxABSrms: $maxABSrms" >> $result_file
echo -e "maxRELrms: $maxRELrms" >> $result_file