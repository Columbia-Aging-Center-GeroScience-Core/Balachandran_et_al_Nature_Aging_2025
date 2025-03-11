# Epigenetic Clock Data Generation

## DNA methylation preprocessing
DNAm was processed at the Geroscience Computational Core in the Robert N. Butler Columbia Aging Center. Preprocessing and normalization of DNA methylation data were conducted in R (v 4.4.1) on n=4018 samples, starting from IDATs. Samples were randomly assigned to five roughly equally sized subsets and the resulting RGsets were saved individually. Replicate samples were saved to the same subset. Samples with the following criteria were removed: samples methylated or unmethylated signal intensity <10.5; samples with >5% of probes with fewer than 5 beads; samples with bisulfite conversion efficiency <80%, samples with an average detection p-value ≥0.05; samples with irregular clustering of SNP-based probes (minfi v1.5.0)(Fortin, Triche, and Hansen 2017). Additionally, 17 metrics implemented in the ewastools package (v 1.7.2)(Heiss and Just 2018) were applied. A total of n=3483 samples passed sample quality control. Prior to clock calculation, normalization was performed using the preprocessNoob function in the minfi package (v1.50.0) on all samples that passed sample QC. 

## Clock Generation

### GrimAge
PCGrimAge was calculated using methods described in Higgins-Chen et al. 2022 (Nature Aging) on Noob normalized beta values, after sample QC but prior to probe QC.C R code used for the calculation of PCGrimAge can be found at: https://github.com/MorganLevineLab/PC-Clocks

### DunedinPACE
DunedinPACE was calculated using methods described in Belsky et al. 2022 (eLife) on Noob normalized beta values, after sample QC but prior to probe QC.C An R package for the calculation of DunedinPACE: https://github.com/danbelsky/DunedinPACE
