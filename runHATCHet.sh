#!/usr/bin/bash
#Shell file to run HATCHet
#File generated 23-Sept-2020

# SLURM Commands
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=12
#SBATCH --time=07-00:00:00
#SBATCH --mem=100g

REF="/mnt/hgfs/OneDrive/Bioinformatics/RefSeq/GRCh38/GRCh38.p12.fa.bgz"

SAM="/path/to/samtools-home/bin/"
BCF="/path/to/bcftools-home/bin/"
# BNPY="/path/to/bnpy-dev/"
BNPY="/mnt/hgfs/OneDrive_UNC/Projects/Programs/BNPY/"

HATCHET_HOME="/mnt/hgfs/OneDrive_UNC/Projects/Programs/HATCHet/"
HATCHET="${HATCHET_HOME}bin/HATCHet.py"
UTILS="${HATCHET_HOME}utils/"
SOLVER="${HATCHET_HOME}build/solve"

XDIR="/mnt/hgfs/Drive_D/Temp/"
NORMAL="/mnt/hgfs/Drive_D/Temp/PolQ_MMC_NovaSeq_517+703_sorted.bam"
# BAMS="/path/to/tumor-sample1.bam /path/to/tumor-sample2.bam"
BAMS="/mnt/hgfs/Drive_D/Temp/PolQ_MMC_NovaSeq_503+706_sorted.bam"
ALLNAMES="P53_Parent PolQ_Parent"
NAMES=""
J=10

set -e
set -o xtrace
PS4='\''[\t]'\'
# export PATH=$PATH:${SAM}
# export PATH=$PATH:${BCF}
#source /path/to/virtualenv-python2.7/bin/activate

BIN=${XDIR}bin/
mkdir -p ${BIN}
BAF=${XDIR}baf/
mkdir -p ${BAF}
BB=${XDIR}bb/
mkdir -p ${BB}
BBC=${XDIR}bbc/
mkdir -p ${BBC}
ANA=${XDIR}analysis/
mkdir -p ${ANA}
RES=${XDIR}results/
mkdir -p ${RES}
EVA=${XDIR}evaluation/
mkdir -p ${EVA}

cd ${XDIR}

# \time -v python3 ${UTILS}binBAM.py -N ${NORMAL} -T ${BAMS} -S ${ALLNAMES} -b 50kb -g ${REF} -j ${J} -q 11 -O ${BIN}normal.bin -o ${BIN}bulk.bin -v &> ${BIN}bins.log
\time -v python3 ${UTILS}deBAF.py  -N ${NORMAL} -T ${BAMS} -S ${ALLNAMES} -r ${REF} -j ${J} -q 11 -Q 11 -U 11 -c 8 -C 300 -O ${BAF}normal.baf -o ${BAF}bulk.baf -v &> ${BAF}bafs.log
\time -v python3 ${UTILS}comBBo.py -c ${BIN}normal.bin -C ${BIN}bulk.bin -B ${BAF}bulk.baf -m MIRROR -e 12 > ${BB}bulk.bb
\time -v python3 ${UTILS}cluBB.py ${BB}bulk.bb -by ${BNPY} -o ${BBC}bulk.seg -O ${BBC}bulk.bbc -e ${RANDOM} -tB 0.04 -tR 0.15 -d 0.1

# cd ${EVA}
# \time -v python3 ${UTILS}BBeval.py ${RES}/best.bbc.ucn
# exit

cd ${ANA}
\time -v python3 ${UTILS}BBot.py -c RD --figsize 6,3 ${BBC}bulk.bbc &
\time -v python3 ${UTILS}BBot.py -c CRD --figsize 6,3 ${BBC}bulk.bbc &
\time -v python3 ${UTILS}BBot.py -c BAF --figsize 6,3 ${BBC}bulk.bbc &
\time -v python3 ${UTILS}BBot.py -c BB ${BBC}bulk.bbc &
\time -v python3 ${UTILS}BBot.py -c CBB ${BBC}bulk.bbc -tS 0.01 &
wait
cd ${RES}
\time -v python3 ${HATCHET} ${SOLVER} -i ${BBC}bulk -n2,8 -p 400 -v 3 -u 0.03 -r ${RANDOM} -j ${J} -eD 6 -eT 12 -g 0.35 -l 0.6 &> >(tee >(grep -v Progress > hatchet.log))

## Increase -l to 0.6 to decrease the sensitivity in high-variance or noisy samples, and decrease it to -l 0.3 in low-variance samples to increase the sensitivity and explore multiple solutions with more clones.
## Increase -u if solutions have clone proportions equal to the minimum threshold -u
## Decrease the number of restarts to 200 or 100 for fast runs, as well as user can decrease the number of clones to -n 2,6 when appropriate or when previous runs suggest fewer clones.
## Increase the single-clone confidence to `-c 0.6` to increase the confidence in the presence of a single tumor clone and further increase this value when interested in a single clone.

cd ${EVA}
\time -v python3 ${UTILS}BBeval.py ${RES}/best.bbc.ucn

