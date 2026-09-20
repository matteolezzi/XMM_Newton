# XMM_Newton
X-Ray Timing Analysis of IGR J18088–2741 with XMM-Newton
# X-Ray Timing Analysis of IGR J18088–2741 with XMM-Newton

## Overview

This project focuses on the processing and temporal analysis of X-ray observations of the cataclysmic variable candidate **IGR J18088–2741**, using data collected by the XMM-Newton satellite.

The main objective is to generate background-corrected light curves, investigate the temporal variability of the source, and estimate its dominant periodicity using Fourier analysis and phase folding.

The analysis is based on observations acquired by the three XMM-Newton EPIC detectors: MOS1, MOS2, and PN.

## Scientific Objectives

* Process and calibrate X-ray observational data.
* Generate X-ray images and light curves in different energy bands.
* Correct the observational timestamps and synchronize data from different detectors.
* Investigate the temporal variability of the source.
* Estimate the dominant period using Fourier analysis.
* Verify the periodic behavior through phase folding and sinusoidal fitting.
* Compare the derived period with values reported in the scientific literature.

## Data and Observation

| Parameter              | Value           |
| ---------------------- | --------------- |
| Source                 | IGR J18088–2741 |
| Observation ID (OBSID) | 0781710401      |
| Right Ascension (RA)   | 272.165708°     |
| Declination (DEC)      | −27.692157°     |
| Satellite              | XMM-Newton      |
| Instruments            | MOS1, MOS2, PN  |

The observational data were retrieved from the XMM-Newton Science Archive (XSA).

## Methodology

### 1. Data Reduction and Calibration

The observational data were processed using the XMM-Newton Science Analysis System (SAS).

A C-Shell pipeline (`X-RAY-PIPELINE.csh`) was used to organize the processing workflow, including:

* Reading and checking the observation parameters.
* Applying instrumental calibration.
* Generating calibrated event files for MOS1, MOS2, and PN.
* Checking the quality of the observations and investigating possible solar-flare contamination.
* Producing X-ray images and preparing the data for temporal analysis.

### 2. Light-Curve Extraction

Light curves were generated for the source and background regions using a temporal bin size of 5 seconds.

Three energy bands were considered:

| Energy band | Range           |
| ----------- | --------------- |
| Soft        | 200–2,000 eV    |
| Hard        | 2,000–10,000 eV |
| Total       | 200–10,000 eV   |

The analysis included barycentric time correction and synchronization of the temporal intervals covered by the three detectors.

Background subtraction was subsequently performed to obtain corrected light curves suitable for temporal analysis.

### 3. Periodicity Analysis

The temporal analysis was performed using Python (`main.py`).

The workflow included:

1. Selecting scientifically valid light-curve measurements.
2. Applying Fourier analysis to investigate the frequency content of the signal.
3. Identifying the dominant peak in the power spectrum and deriving the corresponding period.
4. Folding the light curves at the estimated period to examine the phase-dependent variability.
5. Performing a sinusoidal fit to the folded PN light curve using ROOT and the `GenFit` macro.

## Results

The dominant periods obtained from the three detectors were:

| Detector | Estimated period |
| -------- | ---------------: |
| MOS1     |         876.51 s |
| MOS2     |         876.80 s |
| PN       |         873.79 s |

The three estimates are in close agreement.

The folded light curves exhibit a qualitatively sinusoidal pattern. The estimated periods are also consistent with the approximate spin-period range discussed in the scientific literature for this source.

However, the statistical analysis did not allow the periodicity to be conclusively confirmed. The results should therefore be interpreted as a candidate periodic signal rather than a definitive statistical detection.

## Technologies and Tools

* **Python** – temporal data analysis and periodicity investigation.
* **C-Shell** – scripting and automation of the X-ray data-processing workflow.
* **XMM-Newton SAS** – calibration, reduction, and scientific processing of observational data.
* **ROOT / GenFit** – sinusoidal fitting of the folded light curve.
* **DS9** – visualization and selection of source and background extraction regions.
* **FITS** – astronomical data format used in the analysis.

## Skills Demonstrated

* Scientific data processing and quality control.
* Automation of multi-step processing workflows.
* Time-series analysis and frequency-domain methods.
* Data visualization and interpretation.
* Model fitting and comparison with observational results.
* Use of scientific software and command-line scripting.


## References

Tomsick, J. A. et al. (2016).

*Chandra Observations of Eight Sources Discovered by INTEGRAL.*

The Astrophysical Journal, 816, 38.

## Project Context

This project was developed as part of an astrophysics research experience involving the analysis of X-ray observations of a variable astronomical source.

It demonstrates the application of scientific programming, automated data processing, and temporal analysis techniques to real observational data.
