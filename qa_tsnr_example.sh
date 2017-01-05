#!/bin/bash
# ---------------------------------------------------------------
# QA_TSNR.sh - compute tSNR metrics from 4D Nifti
#
# M. Elliott - 5/2013

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


# --- Check for enough time points ---
nreps=`fslval $dti_file dim4`
if [ $nreps -lt 10 ]; then 
    echo "ERROR. Need at least 10 volumes to calculate tsnr metrics."
    if [ $append -eq 1 ]; then 
        echo -e "tsnr: -1"   >> $result_file
        echo -e "gmean: -1" >> $result_file
        echo -e "drift: -1" >> $result_file
        echo -e "outmax: -1" >> $result_file
        echo -e "outmean: -1" >> $result_file
        echo -e "outcount: -1" >> $result_file
        echo -e "outlist: -1" >> $result_file    
    fi
    exit 1
fi

# --- tsnr metrics ---
fslmaths $dti_file -Tmean ${out_dir}/${in_root}_mean.nii -odt float
gzip "${out_dir}/${in_root}_mean.nii"

#fslmaths $dti_file -Tstd  ${out_dir}/${in_root}_std  -odt float
imrm ${out_dir}/${in_root}_std
3dTstat -stdev -prefix ${out_dir}/${in_root}_std.nii.gz $dti_file 2>/dev/null      # this version of stdev removes slope first! 

fslmaths ${out_dir}/${in_root}_mean -mas $mask_file -div ${out_dir}/${in_root}_std  ${out_dir}/${in_root}_tsnr -odt float
gzip "${out_dir}/${in_root}_tsnr.nii"
tsnr=`fslstats ${out_dir}/${in_root}_tsnr -k $mask_file -m`         # average tSNR
gmean=`fslstats ${out_dir}/${in_root}_mean -k $mask_file -m`        # global signal mean

#gsig=`fslstats -t $dti_file -k $mask_file -m`                     # global signal 
#drift=`3dTstat -slope -prefix - "1D: $gsig"\' 2>/dev/null`     # drift of global signal
fslstats -t $dti_file -k $mask_file -m > ${out_dir}/${in_root}_gsig.1D     # strange bug in 3dTstat - crashes reading from stdin - so use .1D file           
drift=`3dTstat -slope -prefix - ${out_dir}/${in_root}_gsig.1D\' 2>/dev/null`  # drift of global signal

#outlist=`3dToutcount -mask $mask_file $dti_file 2>/dev/null`   # AFNI temporal outlier metric
#outmean=`3dTstat -mean -prefix - "1D: $outlist"\' 2>/dev/null` 
3dToutcount -mask $mask_file $dti_file > ${out_dir}/${in_root}_outlist.1D 2>/dev/null
outmean=`3dTstat -mean -prefix - ${out_dir}/${in_root}_outlist.1D\' 2>/dev/null`

#outmax=`3dTstat -max -prefix - "1D: $outlist"\' 2>/dev/null`  
#outsupra=`1deval -a "1D: $outlist" -expr "ispositive(a-1000)"`   # boolean for outlist > 1000
#outcount=`3dTstat -sum -prefix - "1D: $outsupra"\' 2>/dev/null`  # count number above thresh
#outlist_with_commas=`1deval -1D -a "1D: $outlist" -expr "a"`     # transposes and separates vals with commas

outmax=`3dTstat -max -prefix - ${out_dir}/${in_root}_outlist.1D\' 2>/dev/null`  
outsupra=`1deval -a ${out_dir}/${in_root}_outlist.1D -expr "ispositive(a-1000)"`   # boolean for outlist > 1000
outcount=`3dTstat -sum -prefix - "1D: $outsupra"\' 2>/dev/null`  # count number above thresh
outlist_with_commas=`1deval -1D -a ${out_dir}/${in_root}_outlist.1D -expr "a"`     # transposes and separates vals with commas

outlist2=(`echo $outlist_with_commas | tr ":" "\n"`)             # separate from the "1D:" at beginning of string
outlist3=${outlist2[1]}

echo -e "tsnr: ${tsnr}"   >> $result_file
echo -e "gmean: ${gmean}" >> $result_file
echo -e "drift: ${drift}" >> $result_file
echo -e "outmax: ${outmax}" >> $result_file
echo -e "outmean: ${outmean}" >> $result_file
echo -e "outcount: ${outcount}" >> $result_file
echo -e "outlist: ${outlist3}" >> $result_file

if [ $keep -eq 1 ]; then 
    imrm ${out_dir}/${in_root}_tsnr ${out_dir}/${in_root}_mean ${out_dir}/${in_root}_std
    rm -f ${out_dir}/${in_root}_gsig.1D
fi

exit 0

