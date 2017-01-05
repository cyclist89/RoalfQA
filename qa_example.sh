#!/bin/bash
# ---------------------------------------------------------------
# QA_DTI.sh - do QA on DTI 4D Nifti
#   returns tab delimited QA metrics file
#
# NOTE: This is intended for DTI data with only one b>0 value.
#       (i.e. not good for multi-shell or DWI)
#
# M. Elliott - 5/2013

# --------------------------
Usage() {
	echo "usage: `basename $0` [-append] [-keep] <4Dinput> <bvals> <bvecs> [<maskfile>] <resultfile>"
    exit 1
}
# --------------------------

# --- Perform standard qa_script code ---
source /mnt/stressdevlab/scripts/DTI/QA/qa_preamble.sh

# --- Parse inputs ---
dti_file=$1
bval_file=$2
bvec_file=$3
mask_file=$4
result_file=$5
in_dir=`dirname ${dti_file}`
in_root=`basename ${dti_file} .nii.gz`
bgrads_file=${in_dir}/${in_root}.bgrads
out_dir=`dirname ${result_file}`

#Make directory for QA files
mkdir ${out_dir}/QA_files

# Check for bgrads file (combined bvals and bvecs)
if [[ ! -f  ${bgrads_file} ]]; then
    echo "Making bgrads file"
    python /mnt/stressdevlab/scripts/DTI/MakeBGrads.py ${bval_file} ${bvec_file}
fi

# Separate b=0 and b!=0 volumes
b0_file="${in_dir}/${in_root}_B0.nii.gz"
bx_file="${in_dir}/${in_root}_NOB0.nii.gz"
if [[ ! -f ${bx_file} ]]; then
    python /mnt/stressdevlab/scripts/DTI/SelectByBVal.py ${dti_file} 5
    sleep 4

    gzip `dirname ${b0_file}`/`basename ${b0_file} .nii.gz`.nii
	gzip `dirname ${bx_file}`/`basename ${bx_file} .nii.gz`.nii
fi


# Get count of b0 and bx volumes
b0count=`fslval ${b0_file} dim4`
bxcount=`fslval ${bx_file} dim4`
echo "Found $b0count b=0 and $bxcount b>0 volumes."

#Mask b0 and bx files
b0_masked_file="${in_dir}/${in_root}_B0_mask.nii.gz"
bx_masked_file="${in_dir}/${in_root}_NOB0_mask.nii.gz"
fslmaths ${b0_file} -mas ${mask_file} ${b0_masked_file}
fslmaths ${bx_file} -mas ${mask_file} ${bx_masked_file}

gzip "${in_dir}/${in_root}_B0_mask.nii"
gzip "${in_dir}/${in_root}_NOB0_mask.nii"

# --- Start writing QA result file ---
echo -e "modulename: $0" > $result_file
echo -e "time: `date`" >> $result_file
echo -e "machine: `hostname`" >> $result_file
echo -e "inputfile: $dti_file" >> $result_file

# --- tSNR of b!=0 volumes ---
echo "Computing tsnr metrics on b>0 volumes..."
bash /mnt/stressdevlab/scripts/DTI/RoalfQA/qa_tsnr_example.sh ${bx_masked_file} ${mask_file} ${result_file}

# --- motion estimates from b0 volumes ---
echo "Estimating motion from b0 volumes..."
echo "b0 masked file: ${b0_masked_file}"
bash /mnt/stressdevlab/scripts/DTI/RoalfQA/qa_motion_example.sh ${b0_masked_file} ${result_file}

# --- find clipped voxels ---
echo "Counting clipped voxels..."
bash /mnt/stressdevlab/scripts/DTI/RoalfQA/qa_clipcount_example.sh ${dti_file} ${mask_file} ${result_file}

# Clean up
mv ${in_dir}/${in_root}*mask*.nii.gz ${out_dir}/QA_files/
mv ${in_dir}/*.1D ${out_dir}/QA_files/
mv ${in_dir}/*.rms ${out_dir}/QA_files/
mv ${in_dir}/*.mat ${out_dir}/QA_files/