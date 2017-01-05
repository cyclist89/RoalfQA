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
if [ $# -lt 4 -o $# -gt 5 ]; then Usage; fi
infile=`imglob -extension $1`
indir=`dirname $infile`
inbase=`basename $infile`
inroot=`remove_ext $inbase`
bvalfile=$2
bvecfile=$3
maskfile=""
if [ $# -gt 4 ]; then
    maskfile=`imglob -extension $4`
    shift
fi
resultfile=$4
outdir=`dirname $resultfile`

# --- start result file ---
if [ $append -eq 0 ]; then 
    echo -e "modulename\t$0"      > $resultfile
    echo -e "version\t$VERSION"  >> $resultfile
    echo -e "inputfile\t$infile" >> $resultfile
fi

# --- Separate b=0 and b!=0 volumes ---
bvals=(`cat $bvalfile`)
nvals=${#bvals[@]}
b0count=0
bxcount=0
rm -f $outdir/${inroot}_b0tmp* $outdir/${inroot}_bXtmp*
echo "Splitting $nvals volumes into b=0 and b!=0 subsets..."
for (( i=0; i<$nvals; i++ )) ; do
    echo -n "."
    if [[ "${bvals[$i]}" == "0" ]]; then 
        #fslroi $infile $outdir/${inroot}_b0tmp_$i $i 1                          # this is too slow, use AFNI instead
        3dcalc -prefix $outdir/${inroot}_b0tmp$i.nii -a${i} $infile -expr 'a' 2>/dev/null
        let b0count=$b0count+1
    else
        #fslroi $infile $outdir/${inroot}_bXtmp_$i $i 1    
        3dcalc -prefix $outdir/${inroot}_bXtmp$i.nii -a${i} $infile -expr 'a' 2>/dev/null
        let bxcount=$bxcount+1
    fi
done
echo "."
if [[ "${b0count}" == "0" ]]; then echo "ERROR. Found no b=0 volumes!"; exit 1; fi
if [[ "${bxcount}" == "0" ]]; then echo "ERROR. Found no b>0 volumes!"; exit 1; fi
echo "Found $b0count b=0 and $bxcount b>0 volumes."
rm -f $outdir/${inroot}_b0.nii $outdir/${inroot}_bX.nii
3dTcat -prefix $outdir/${inroot}_b0.nii $outdir/${inroot}_b0tmp* 2>/dev/null
3dTcat -prefix $outdir/${inroot}_bX.nii $outdir/${inroot}_bXtmp* 2>/dev/null
rm -f $outdir/${inroot}_b0tmp* $outdir/${inroot}_bXtmp*

# mask from b=0 volumes
if [ "X${maskfile}" = "X" ]; then
    echo "Automasking..." 
    maskfile=${outdir}/${inroot}_qamask.nii
    rm -f $maskfile
    3dAutomask -prefix $maskfile $outdir/${inroot}_b0.nii  2>/dev/null
fi

# --- find clipped voxels ---
echo "Counting clipped voxels..."
/mnt/stressdevlab/scripts/DTI/QA/qa_clipcount_v1.sh -append $keepswitch $infile $maskfile $resultfile

# --- tSNR of b!=0 volumes ---
echo "Computing tsnr metrics on b>0 volumes..."
/mnt/stressdevlab/scripts/DTI/QA/qa_tsnr_v1.sh -append $keepswitch $outdir/${inroot}_bX $maskfile $resultfile


# --- clean up ---
if [ $keep -eq 1 ]; then 
    imrm $outdir/${inroot}_b0 $outdir/${inroot}_bX 
fi
exit 0
