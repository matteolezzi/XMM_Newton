#! /bin/csh -f
##################################################################
#  name: X-RAY-PIPELINE.csh
#  author: A.A.Nucita
#  version: 1.0
#  
#  History: CSH script written originally for the D-SPHINX (Dwarf-SPHeroydal galaxies IN X-rays) project 2014 and then adapted
#
#  SUL PC LABASTRO source ./sasini.csh ${outfile} docker 
#
#  last modified: 2018
##################################################################
# Set MATH alias - takes an arithmetic assignment statement
# as argument, e.g., newvar = var1 + var2
# Separate all items and operators in the expression with blanks
alias MATH 'set \!:1 = `echo "\!:3-$" | bc -l`'



echo "___________________________________________________________"
echo "                                                           "
echo "      X-RAY-PIPELINE.csh                                  "
echo "                                                           "
echo "___________________________________________________________"
echo "                                                           "

     if($#argv < 1) then 
        echo "X-RAY-PIPELINE.csh Usage: (source) ./X-RAY-PIPELINE.csh input_file "
	echo " "
	echo "[input_file1] = input file with XMM-Newton observation ID and (J2000) coordinates  (deg) of the source to be studied. Format must be as: "
	echo "XMM-OBSID     RA    DEC"
        exit(1)
     endif
echo "-----------------------------------------------------------"

set pipelinefolder=`pwd`

#################################################################
#  SECTION 1
#   
#  Setting up the pipeline for the observation  OBSID
#
##################################################################

# variables for XSPEC
set XSPECoutfile="auto.xcm"
set FILEDATALL="results.dat"
touch ${XSPECoutfile}
touch ${FILEDATALL}

# Useful for xspec fit
set queryflag="yes"
set numberoffits=1000
set numberoferrors=1000    


# READ INPUT FILE 
         set InputFileName=$1
         set nlines=`wc -l ${InputFileName} | awk '{print $1'}`
	 echo " "
	 echo "Input File was: "${InputFileName}
         echo ""
         echo "Number of entries in file: "${nlines}
         echo ""
         set OBSID=`awk '{print $1}' ${InputFileName}`
         set RA=`awk '{print $2}' ${InputFileName}`
         set DEC=`awk '{print $3}' ${InputFileName}`

	  # Check if the input file is correct and define source default coordinate
          set kkk=1
          while ($kkk <= ${nlines})
	        echo $OBSID[$kkk] $RA[$kkk] $DEC[$kkk]
		set kkk=`expr $kkk + 1`
          end	
         echo ""
         echo "End of reading"
         echo ""

         # CHECK AND EXIT IF WRONG
               echo " "
               echo "Is it correct? (y/n)"
               echo " "
               set ansYN=$<
		   if(${ansYN} != y) then
		     echo "Ok, check and write the correct input file"
		     exit (2)
		   endif   
		   




#		   
# PROCESSING LOOP...
#
# processing kkk observation
set kkk=1
while ($kkk <= ${nlines})
           echo " "
           echo "Processing OBSID: "$OBSID[$kkk]
           echo " "
      
           # DONWLOADING DATA AND PREPARING FOLDERS AND INPUT FILES. IF YES download and prepare, if not prepare only *** OF COURSE IT IS EXPECTED YOU ALREADY DID IT *** 
           echo " "
           echo "Downloading obsid ...? (y/n) "$OBSID[$kkk]  
           echo " "
           set ansYN=$<
           if(${ansYN} == y) then
                 source ./make_AIOCLIENT.csh $OBSID[$kkk] $OBSID[$kkk]
                 # log folder 
                 mkdir $OBSID[$kkk]"_LOG"
           endif      

           # cd to KKK obsid working folder
           cd ${pipelinefolder}'/'$OBSID[$kkk]
           
           # copy input into log folder 
            set outfileis=`ls $OBSID[$kkk]"_input.txt"` 
            if($#outfileis == 0) then
	     echo $OBSID[$kkk]"_input.txt does not exist. Apparently you never run the pipeline for this obsid. Stop and check!"
             exit(0)
            endif 
	
	   # if already run, go on
           set outfile=$OBSID[$kkk]"_input.txt"
           cp ${pipelinefolder}'/'$OBSID[$kkk]/${outfile}  ${pipelinefolder}'/'$OBSID[$kkk]"_LOG"
      
      
     
                 
           # copy sasini here and initialize sas as local 
           echo "Initialize SAS"
           cp ${pipelinefolder}'/scripts/'sasini.csh .

           #source ./sasini.csh ${outfile} local
           source ./sasini.csh ${outfile} docker
           echo "SAS initialized!"
                 
           # set ccf and sum and copy them to log folder 
           set ccffilebck=`ls ccf.cif`
           cp ${ccffilebck}  ${pipelinefolder}'/'$OBSID[$kkk]"_LOG"
           set sumfilebck=`ls *.SAS`
           cp ${sumfilebck} ${pipelinefolder}'/'$OBSID[$kkk]"_LOG"
           
 
     
#################################################################
#  SECTION 2
#   
#  Standard chains for producing cleaned science files
#
##################################################################
           echo " "
           echo 'Starting CHAINs for obsid...?(y/n) '$OBSID[$kkk] 
           echo " "
           set ansYN=$<
           if(${ansYN} == y) then
                 # LOG FILES
                 echo 'Set log files'
                 set moslog=$OBSID[$kkk]'_moschain.txt'
                 set pnlog=$OBSID[$kkk]'_pnchain.txt'
                 set omlog=$OBSID[$kkk]'_omchain.txt'
                 echo ${moslog}
                 echo ${pnlog}
                 echo ${omlog}
                 echo ''
                 echo 'Starting MOS 1/2'
                          # MOS CHAINS
                           emchain >> ${moslog}
                 echo 'end MOS 1/2'
                 echo 'Starting PN '
                          # PN CHAINS
                           epchain >> ${pnlog}
                          #epchain runbackground=N keepintermediate=raw withoutoftime=Y >> ${pnlog}
                         # epproc verbosity=5 >> ${pnlog}
                 echo 'end PN'
                 echo 'Starting OM '
                         # OM CHAINS
                         # omchain >> ${omlog}
                         # omfchain timebinsize=10 >> ${omlog}
                 echo 'end OM'
                 # COPY LOGS in LOG FOLDER 
                 cp ${moslog} ${pipelinefolder}'/'$OBSID[$kkk]"_LOG"
                 cp ${pnlog} ${pipelinefolder}'/'$OBSID[$kkk]"_LOG"
                 cp ${omlog} ${pipelinefolder}'/'$OBSID[$kkk]"_LOG" 
                 echo " "
                 echo "Chains finished."
                 echo " "
           endif
           

#################################################################
# Set names of RAW files
#################################################################
# SE PER ESEMPIO DI MOS 1 CI SONO DUE EVLI ALLORA BISOGNA UNIRLI PRIMA DI PROCEDERE****
# evlistcomb is aimed to combine events files from the same instrument in a
# relatively safe and robust way, and can be used to have just one events file per
# instrument and observation (e.g., combine scheduled and unscheduled exposures);
#
# http://xmm2.esac.esa.int/xmmhelp/EPICpn?id=23765;page=4;user=guest


echo ''
echo "Setting filenames of output RAW fits (*M1*EVLI*, *M2*EVLI*, *PN*EVLI*) for OBSID: "$OBSID[$kkk]
echo ''
ls *M1*EVLI*.FIT
ls *M2*EVLI*.FIT
ls *PN*EVLI*.FIT
#set mos1RAW=`ls *M1*EVLI*.FIT`
#set mos2RAW=`ls *M2*EVLI*.FIT`
#set pnRAW=`ls *PN*EVLI*.FIT`

echo 'MOS1 RAW? '
set mos1RAW=$<
echo 'MOS2 RAW? '
set mos2RAW=$<
echo 'pn RAW? '
set pnRAW=$<

echo ''
echo "Using..."
echo $mos1RAW
echo $mos2RAW
echo $pnRAW


#################################################################
#  SECTION 3
#   
#  Cleaning and image production
#
##################################################################
# Clean...
echo " "
echo 'Cleaning event files for obsid...?(y/n) '$OBSID[$kkk] 
echo " "
set ansYN=$<
if(${ansYN} == y) then

# copy scripts here
cp ${pipelinefolder}'/scripts/'make_clean.csh .
cp ${pipelinefolder}'/scripts/'xmmlightclean.csh  .

echo 'Manual or auto clean...?(MANUAL/AUTO) '$OBSID[$kkk] 
set MANUALAUTO=$<
      source ./make_clean.csh MOS ${mos1RAW} $MANUALAUTO 100 $OBSID[$kkk]"_mos1" RATE
      source ./make_clean.csh MOS ${mos2RAW} $MANUALAUTO 100 $OBSID[$kkk]"_mos2" RATE
      source ./make_clean.csh PN ${pnRAW} $MANUALAUTO 100 $OBSID[$kkk]"_pn" RATE

endif

      
# FROM HERE ON, YOU MUST HAVE CLEANED FILES TO WORK ON. IF NOT AVAILABLE THE SCRIPT STOPS!      

# Cleaned events files 
            set outfileis=`ls $OBSID[$kkk]"_mos1_clean_evt.fits"` 
            if($#outfileis == 0) then
	     echo $OBSID[$kkk]"_mos1_clean_evt.fits does not exist. Apparently you never run the clean procedure for this obsid. Stop and check!"
             exit(0)
            endif 
            set outfileis=`ls $OBSID[$kkk]"_mos2_clean_evt.fits"` 
            if($#outfileis == 0) then
	     echo $OBSID[$kkk]"_mos2_clean_evt.fits does not exist. Apparently you never run the clean procedure for this obsid. Stop and check!"
             exit(0)
            endif 
            set outfileis=`ls $OBSID[$kkk]"_pn_clean_evt.fits"` 
            if($#outfileis == 0) then
	     echo $OBSID[$kkk]"_pn_clean_evt.fits does not exist. Apparently you never run the clean procedure for this obsid. Stop and check!"
             exit(0)
            endif 
            
# settings...
set mos1=$OBSID[$kkk]"_mos1_clean_evt.fits"
set mos2=$OBSID[$kkk]"_mos2_clean_evt.fits"
set pn=$OBSID[$kkk]"_pn_clean_evt.fits"

echo ''
echo "Setting filenames of CLEANED fits (*mos1_clean_evt*, *mos2_clean_evt*, *p_clean_evt*) for OBSID: "$OBSID[$kkk]
echo ''
ls *mos1_clean_evt*
ls *mos2_clean_evt*
ls *pn_clean_evt*

echo 'MOS1? '
set mos1=$<
echo 'MOS2 ? '
set mos2=$<
echo 'pn? '
set pn=$<




# Images...
echo " "
echo 'Images for obsid...?(y/n) '$OBSID[$kkk] 
echo " "
set ansYN=$<
if(${ansYN} == y) then
# Copy scripts here 
cp ${pipelinefolder}'/scripts/'make_image.csh .

# image
     echo 'Image minimum energy (eV):'
     set emin=$<
     echo 'Image maximum energy (eV):'
     set emax=$<
     source ./make_image.csh PN ${pn} ${emin} ${emax} 50 12 $OBSID[$kkk]"_pn_image" 
     source ./make_image.csh MOS ${mos1} ${emin} ${emax} 50 12 $OBSID[$kkk]"_mos1_image" 
     source ./make_image.csh MOS ${mos2} ${emin} ${emax} 50 12 $OBSID[$kkk]"_mos2_image" 

# Write DS9 region files on nominal coordinates
set ds9file=$OBSID[$kkk]"_ds9_nominal.reg"
touch ${ds9file}

cat <<EOF>>${ds9file}
# Region file format: DS9 version 4.1
# Filename: 
global color=green dashlist=8 3 width=1 font="helvetica 10 normal roman" select=1 highlite=1 dash=0 fixed=0 edit=1 move=1 delete=1 include=1 source=1
fk5
circle(${RA},${DEC},40")
EOF
endif


#################################################################
#  SECTION 4
#   
#  Spectra
#
##################################################################
echo " "
echo 'Producing spectra for obsid...?(y/n) '$OBSID[$kkk]  
echo " "
set ansYN=$<
if(${ansYN} == y) then

# Copy scripts here 
cp  ${pipelinefolder}'/scripts/'*.f .
cp  ${pipelinefolder}'/scripts/'*.exe .
cp  ${pipelinefolder}'/scripts/'make_spectrum.csh .
cp  ${pipelinefolder}'/scripts/'rebin_spectra.csh .
cp  ${pipelinefolder}'/scripts/'extract_nh.csh .
cp  ${pipelinefolder}'/scripts/'epic_regions.txt .
cp  ${pipelinefolder}'/scripts/'expression_mos1.txt .
cp  ${pipelinefolder}'/scripts/'answer_expression_mos1.txt .
cp  ${pipelinefolder}'/scripts/'expression_mos2.txt .
cp  ${pipelinefolder}'/scripts/'answer_expression_mos2.txt .
cp  ${pipelinefolder}'/scripts/'expression_pn.txt .
cp  ${pipelinefolder}'/scripts/'answer_expression_pn.txt .

echo ''
echo 'Extracting n_h towards the nominal source coordinates using nhtool...'
source ./extract_nh.csh ${RA} ${DEC}
echo 'nH: '${n_h}
echo ''

# Setting dummies
set xphysical=0
set yphysical=0
set extrsrc=0
set extrbck=0

set mos1_src_xcen=0
set mos1_src_ycen=0
set mos1_src_radius=0
set mos1_bkg_xcen=0
set mos1_bkg_ycen=0
set mos1_bkg_radius=0

set mos2_src_xcen=0
set mos2_src_ycen=0
set mos2_src_radius=0
set mos2_bkg_xcen=0
set mos2_bkg_ycen=0
set mos2_bkg_radius=0

set pn_src_ycen=0
set pn_src_xcen=0
set pn_src_radius=0
set pn_bkg_ycen=0
set pn_bkg_xcen=0
set pn_bkg_radius=0





#################################################################
# APPLYING OTHER EXPRESSION SELECTION?
#################################################################
echo ''
echo "Start Applying other TIME expression selection...? (y/n)"   
 set ansTIMEexpspec=$<
 if(${ansTIMEexpspec} != n) then
echo 'Applying other expression selection...'

# Commento la riga seguente perche ho aggiunto la colonna delle fasei ai file mos1_phase.fits, mos2_phase.fits e pn_phase.fits
# Conseguentemente, posso fare la selezione direttamente in fase
# Senza ricercare i tempi con IDL poi convertitre la lista dei tempi "permessi" con gtibuild
#
# La fase è stata aggiunta con il comando:
# 1) Ho copiato i file corretti per il baricentro in mos1_phase.fits, mos2_*, pn_*
# 2) phasecalc tables=pn_phase.fits:EVENTS frequency=0.00082087248 epoch=2004-05-18T14:51:44.183. Questa operazione deve essere ripetuta per tutte le tabelle del file fits
#    che contengono una colonna TIME
#    Ad esempio: phasecalc tables=phase_barycen_0201290301_mos1_clean_evt.fits:EVENTS frequency=0.00082087248 epoch=2004-05-18T14:51:44.183 

# 3) creo una nuova GTI dalle fasi scelte come: 
#      tabgtigen table=phase_barycen_0201290301_mos1_clean_evt.fits gtiset=gti.ds expression='((PHASE>0.6)&&(PHASE<=0.8))'

# La frequenza corrisponde a 1/periodo identificato in WZSEX. epoch: corrisponde al primo punto (con un bin a 10 secondi) della curva
# di luce tra 0.1 e 10 keV
#
# Lavoro per costruire gli spettri sui file ai quali ho aggiunto le fasi a tutte le tabelle aventi una colonna TIME



phasecalc tables=phase_barycen_0201290301_mos1_clean_evt.fits:EVENTS frequency=0.00082087248 epoch=2004-05-18T14:51:44.183 
phasecalc tables=phase_barycen_0201290301_mos1_clean_evt.fits:EXPOSU01 frequency=0.00082087248 epoch=2004-05-18T14:51:44.183 
phasecalc tables=phase_barycen_0201290301_mos1_clean_evt.fits:EXPOSU02 frequency=0.00082087248 epoch=2004-05-18T14:51:44.183 
phasecalc tables=phase_barycen_0201290301_mos1_clean_evt.fits:EXPOSU03 frequency=0.00082087248 epoch=2004-05-18T14:51:44.183 
phasecalc tables=phase_barycen_0201290301_mos1_clean_evt.fits:EXPOSU04 frequency=0.00082087248 epoch=2004-05-18T14:51:44.183 

phasecalc tables=phase_barycen_0201290301_mos2_clean_evt.fits:EVENTS frequency=0.00082087248 epoch=2004-05-18T14:51:44.183 
phasecalc tables=phase_barycen_0201290301_mos2_clean_evt.fits:EXPOSU01 frequency=0.00082087248 epoch=2004-05-18T14:51:44.183 
phasecalc tables=phase_barycen_0201290301_mos2_clean_evt.fits:EXPOSU02 frequency=0.00082087248 epoch=2004-05-18T14:51:44.183 
phasecalc tables=phase_barycen_0201290301_mos2_clean_evt.fits:EXPOSU03 frequency=0.00082087248 epoch=2004-05-18T14:51:44.183 
phasecalc tables=phase_barycen_0201290301_mos2_clean_evt.fits:EXPOSU04 frequency=0.00082087248 epoch=2004-05-18T14:51:44.183 

phasecalc tables=phase_barycen_0201290301_pn_clean_evt.fits:EVENTS frequency=0.00082087248 epoch=2004-05-18T14:51:44.183 
phasecalc tables=phase_barycen_0201290301_pn_clean_evt.fits:EXPOSU01 frequency=0.00082087248 epoch=2004-05-18T14:51:44.183 
phasecalc tables=phase_barycen_0201290301_pn_clean_evt.fits:HKAUX01 frequency=0.00082087248 epoch=2004-05-18T14:51:44.183 
phasecalc tables=phase_barycen_0201290301_pn_clean_evt.fits:EXPOSU02 frequency=0.00082087248 epoch=2004-05-18T14:51:44.183 
phasecalc tables=phase_barycen_0201290301_pn_clean_evt.fits:HKAUX02 frequency=0.00082087248 epoch=2004-05-18T14:51:44.183 
phasecalc tables=phase_barycen_0201290301_pn_clean_evt.fits:EXPOSU03 frequency=0.00082087248 epoch=2004-05-18T14:51:44.183 
phasecalc tables=phase_barycen_0201290301_pn_clean_evt.fits:HKAUX03 frequency=0.00082087248 epoch=2004-05-18T14:51:44.183 
phasecalc tables=phase_barycen_0201290301_pn_clean_evt.fits:EXPOSU04 frequency=0.00082087248 epoch=2004-05-18T14:51:44.183 
phasecalc tables=phase_barycen_0201290301_pn_clean_evt.fits:HKAUX04 frequency=0.00082087248 epoch=2004-05-18T14:51:44.183 
phasecalc tables=phase_barycen_0201290301_pn_clean_evt.fits:EXPOSU05 frequency=0.00082087248 epoch=2004-05-18T14:51:44.183 
phasecalc tables=phase_barycen_0201290301_pn_clean_evt.fits:HKAUX05 frequency=0.00082087248 epoch=2004-05-18T14:51:44.183 
phasecalc tables=phase_barycen_0201290301_pn_clean_evt.fits:EXPOSU06 frequency=0.00082087248 epoch=2004-05-18T14:51:44.183 
phasecalc tables=phase_barycen_0201290301_pn_clean_evt.fits:HKAUX06 frequency=0.00082087248 epoch=2004-05-18T14:51:44.183 
phasecalc tables=phase_barycen_0201290301_pn_clean_evt.fits:EXPOSU07 frequency=0.00082087248 epoch=2004-05-18T14:51:44.183 
phasecalc tables=phase_barycen_0201290301_pn_clean_evt.fits:HKAUX07 frequency=0.00082087248 epoch=2004-05-18T14:51:44.183 
phasecalc tables=phase_barycen_0201290301_pn_clean_evt.fits:EXPOSU08 frequency=0.00082087248 epoch=2004-05-18T14:51:44.183 
phasecalc tables=phase_barycen_0201290301_pn_clean_evt.fits:HKAUX08 frequency=0.00082087248 epoch=2004-05-18T14:51:44.183 
phasecalc tables=phase_barycen_0201290301_pn_clean_evt.fits:EXPOSU09 frequency=0.00082087248 epoch=2004-05-18T14:51:44.183 
phasecalc tables=phase_barycen_0201290301_pn_clean_evt.fits:HKAUX09 frequency=0.00082087248 epoch=2004-05-18T14:51:44.183 
phasecalc tables=phase_barycen_0201290301_pn_clean_evt.fits:EXPOSU10 frequency=0.00082087248 epoch=2004-05-18T14:51:44.183 
phasecalc tables=phase_barycen_0201290301_pn_clean_evt.fits:HKAUX10 frequency=0.00082087248 epoch=2004-05-18T14:51:44.183 
phasecalc tables=phase_barycen_0201290301_pn_clean_evt.fits:EXPOSU11 frequency=0.00082087248 epoch=2004-05-18T14:51:44.183 
phasecalc tables=phase_barycen_0201290301_pn_clean_evt.fits:HKAUX11 frequency=0.00082087248 epoch=2004-05-18T14:51:44.183 



# GTI MINIMO, MASSIMO, DIP per  MOS1
 tabgtigen table=phase_barycen_0201290301_mos1_clean_evt.fits gtiset=gti_mos1_minimo.ds expression='((PHASE>=0)&&(PHASE<=0.3))||((PHASE>=0.9)&&(PHASE<=1))'
 tabgtigen table=phase_barycen_0201290301_mos1_clean_evt.fits gtiset=gti_mos1_massimo.ds expression='((PHASE>0.3)&&(PHASE<=0.6))||((PHASE>=0.8)&&(PHASE<0.9))'
 tabgtigen table=phase_barycen_0201290301_mos1_clean_evt.fits gtiset=gti_mos1_dip.ds expression='((PHASE>0.65)&&(PHASE<0.75))'
 
# GTI MINIMO, MASSIMO, DIP per  MOS2
 tabgtigen table=phase_barycen_0201290301_mos2_clean_evt.fits gtiset=gti_mos2_minimo.ds expression='((PHASE>=0)&&(PHASE<=0.3))||((PHASE>=0.9)&&(PHASE<=1))'
 tabgtigen table=phase_barycen_0201290301_mos2_clean_evt.fits gtiset=gti_mos2_massimo.ds expression='((PHASE>0.3)&&(PHASE<=0.6))||((PHASE>=0.8)&&(PHASE<0.9))'
 tabgtigen table=phase_barycen_0201290301_mos2_clean_evt.fits gtiset=gti_mos2_dip.ds expression='((PHASE>0.65)&&(PHASE<0.75))'
 
# GTI MINIMO, MASSIMO, DIP per  DIP
 tabgtigen table=phase_barycen_0201290301_pn_clean_evt.fits gtiset=gti_pn_minimo.ds expression='((PHASE>=0)&&(PHASE<=0.3))||((PHASE>=0.9)&&(PHASE<=1))'
 tabgtigen table=phase_barycen_0201290301_pn_clean_evt.fits gtiset=gti_pn_massimo.ds expression='((PHASE>0.3)&&(PHASE<=0.6))||((PHASE>=0.8)&&(PHASE<0.9))'
 tabgtigen table=phase_barycen_0201290301_pn_clean_evt.fits gtiset=gti_pn_dip.ds expression='((PHASE>0.65)&&(PHASE<0.75))'

 
 
echo '...done'

echo 'Now working on TIME selected specta...'${mos1}' '${mos2}' '${pn}
endif








# 
# SPMODE 1 (USING THE NOMINAL COORDINATES AND GIVING IN INPUT ON RUNTIME THE source and bck radii in physical units. Bck is extracted in annuli)
# SPMODE 2 (USING THE EPIC REGION FILE. Bck is extracted in circles)
# SPMODE 3 (USING THE EXPRESSION FILE. More complicated regions are allowed using sas syntax.)
#
echo "Selecting the source region extraction mode...(1,2,3)?" 
set SPMODE=$<


echo 'Spectral count per bin:'
set sbin=$<


# SPMODE = 1
if(${SPMODE} == 1) then
#################################################################
# NOMINAL COORDINATES AND INPUT RADII (REQUIRES IMAGE PRODUCED BEFORE)
#################################################################
echo ''
echo 'Extracting source nominal coordinates from image in physical units...' 
echo ''
eregionanalyse imageset=$OBSID[$kkk]"_pn_image_${emin}"_"${emax}.fits" srcexp="((RA,DEC) IN CIRCLE(${RA},${DEC},0.0111))">tempo.txt
set xphysical=`tail -14 tempo.txt | head -1 | awk '{print $2}'`
set yphysical=`tail -13 tempo.txt | head -1 | awk '{print $2}'`
set maxSNradius=`tail -11 tempo.txt | head -1 | awk '{print $4}'`
echo ''
echo 'Source physical coordinates are: '$xphysical', '$yphysical', '$maxSNradius 
echo ''


echo ''
echo "*** USING THE NOMINAL COORDINATES AND GIVING RADII ON RUNTIME *** "
echo 'The source and bck radii have to be entered in physical units. Bck is extracted in annuli.'
echo ''
echo "Enter the extraction radius for source..." 
set extrsrc=$<
echo "Enter the extraction radius for background" 
set extrbck=$<

# SPECTRA
source ./make_spectrum.csh MOS ${mos1} ${xphysical} ${yphysical} ${extrsrc} ${xphysical} ${yphysical} ${extrbck} 12 annuli ${sbin} mode1 $OBSID[$kkk]"_mos1_" n 

set backm1_src=${backscale_src}
set backm1_bck=${backscale_bkg}

echo '*********************************************************'
echo 'Backscales for source and background...'
echo $backm1_src', '$backm1_bck
echo '*********************************************************'


source ./make_spectrum.csh MOS ${mos2} ${xphysical} ${yphysical} ${extrsrc} ${xphysical} ${yphysical} ${extrbck} 12 annuli ${sbin}  mode1 $OBSID[$kkk]"_mos2_" n 

set backm2_src=${backscale_src}
set backm2_bck=${backscale_bkg}


echo '*********************************************************'
echo 'Backscales for source and background...'
echo $backm2_src', '$backm2_bck
echo '*********************************************************'


source ./make_spectrum.csh PN ${pn} ${xphysical} ${yphysical} ${extrsrc} ${xphysical} ${yphysical} ${extrbck} 4 annuli ${sbin}  mode1 $OBSID[$kkk]"_pn_" n 

set backpn_src=${backscale_src}
set backpn_bck=${backscale_bkg}

echo '*********************************************************'
echo 'Backscales for source and background...'
echo $backpn_src', '$backpn_bck
echo '*********************************************************'
endif # END SPMODE 1



# SPMODE = 2
if(${SPMODE} == 2) then
#################################################################
# READ AGAIN EPIC REGION AND CHANGE IF REQUIRED
#################################################################
echo ''
echo "*** USING THE EPIC EXTRACTION REGION FILE ***"
echo ''
echo 'The epic_region.txt file contains information on the source'
echo 'and bck extraction circular regions. The following scripts need this file!'
echo 'Write the file now (before pressing y) or exit with n.'
echo ''
echo "READING epic regions. Check the file and continue when ready (y/n)"
set ansYNepicregionfile=$<
if(${ansYNepicregionfile} != y) then
       exit(1)
endif
if (! -e "epic_regions.txt") then
    echo "epic_regions.txt missing. I cannot continue."
    exit(1)
endif

# MOS 1
set mos1_src_xcen = `tail -6 epic_regions.txt | head -1 | cut -f2 -d"|"` 
set mos1_src_ycen = `tail -6 epic_regions.txt | head -1 | cut -f3 -d"|"` 
set mos1_src_radius =  `tail -6 epic_regions.txt | head -1 | cut -f4 -d"|"` 
set mos1_bkg_xcen = `tail -5 epic_regions.txt | head -1 |  cut -f2 -d"|"`
set mos1_bkg_ycen = `tail -5 epic_regions.txt | head -1 |  cut -f3 -d"|"` 
set mos1_bkg_radius = `tail -5 epic_regions.txt | head -1 |  cut -f4 -d"|"`
# MOS 2
set mos2_src_xcen = `tail -4 epic_regions.txt | head -1 | cut -f2 -d"|"` 
set mos2_src_ycen = `tail -4 epic_regions.txt | head -1 | cut -f3 -d"|"` 
set mos2_src_radius =  `tail -4 epic_regions.txt | head -1 | cut -f4 -d"|"` 
set mos2_bkg_xcen = `tail -3 epic_regions.txt | head -1 |  cut -f2 -d"|"`
set mos2_bkg_ycen = `tail -3 epic_regions.txt | head -1 |  cut -f3 -d"|"` 
set mos2_bkg_radius = `tail -3 epic_regions.txt | head -1 |  cut -f4 -d"|"`
# pn
set pn_src_xcen = `tail -2 epic_regions.txt | head -1 |  cut -f2 -d"|"` 
set pn_src_ycen = `tail -2 epic_regions.txt | head -1 |  cut -f3 -d"|"` 
set pn_src_radius =  `tail -2 epic_regions.txt | head -1 |  cut -f4 -d"|"` 
set pn_bkg_xcen = `tail -1 epic_regions.txt | head -1 |  cut -f2 -d"|"`
set pn_bkg_ycen = `tail -1 epic_regions.txt | head -1 |  cut -f3 -d"|"` 
set pn_bkg_radius = `tail -1 epic_regions.txt | head -1 |  cut -f4 -d"|"`
# Echo
echo "MOS1 source X,Y,R: "${mos1_src_xcen} ${mos1_src_ycen} ${mos1_src_radius}
echo "MOS1 background X,Y,R: "${mos1_bkg_xcen} ${mos1_bkg_ycen} ${mos1_bkg_radius}
echo "MOS2 source X,Y,R: "${mos2_src_xcen} ${mos2_src_ycen} ${mos2_src_radius}
echo "MOS2 background X,Y,R: "${mos2_bkg_xcen} ${mos2_bkg_ycen} ${mos2_bkg_radius}
echo "PN source X,Y,R: "${pn_src_xcen} ${pn_src_ycen} ${pn_src_radius}
echo "PN background X,Y,R: "${pn_bkg_xcen} ${pn_bkg_ycen} ${pn_bkg_radius}
echo '...done.'
echo ''     
echo "Is it correct? (y/n)"
echo " "
set ansEpicRegionFileYN=$<
if(${ansEpicRegionFileYN} != y) then
   echo "Ok, check and write the correct input file"
   exit (2)
endif   



# SPECTRA
source ./make_spectrum.csh MOS ${mos1} ${mos1_src_xcen} ${mos1_src_ycen} ${mos1_src_radius} ${mos1_bkg_xcen} ${mos1_bkg_ycen} ${mos1_bkg_radius} 12 circles ${sbin} mode1 $OBSID[$kkk]"_mos1_" n NONE 

set backm1_src=${backscale_src}
set backm1_bck=${backscale_bkg}
echo '*********************************************************'
echo 'Backscales for source and background...'
echo $backm1_src', '$backm1_bck
echo '*********************************************************'



source ./make_spectrum.csh MOS ${mos2} ${mos2_src_xcen} ${mos2_src_ycen} ${mos2_src_radius} ${mos2_bkg_xcen} ${mos2_bkg_ycen} ${mos2_bkg_radius} 12 circles ${sbin} mode1 $OBSID[$kkk]"_mos2_" n NONE

set backm2_src=${backscale_src}
set backm2_bck=${backscale_bkg}
echo '*********************************************************'
echo 'Backscales for source and background...'
echo $backm2_src', '$backm2_bck
echo '*********************************************************'

source ./make_spectrum.csh PN ${pn} ${pn_src_xcen} ${pn_src_ycen} ${pn_src_radius} ${pn_bkg_xcen} ${pn_bkg_ycen} ${pn_bkg_radius} 4 circles ${sbin} mode1 $OBSID[$kkk]"_pn_" n NONE

set backpn_src=${backscale_src}
set backpn_bck=${backscale_bkg}
echo '*********************************************************'
echo 'Backscales for source and background...'
echo $backpn_src', '$backpn_bck
echo '*********************************************************'
endif # endo SPMODE 2






# SPMODE = 3
if(${SPMODE} == 3) then
#################################################################
# READ EXPRESSION FILE
#################################################################
echo ''
echo "*** USING EXPRESSION FILE ***"
echo ''
echo 'The expression file allows one to use SAS syntax'
echo 'The following scripts need this file!'
echo 'Write the file now (before pressing y) or exit with n.'
if (! -e "expression_mos1.txt") then
    echo "expression_mos1.txt missing. I cannot continue."
    exit(1)
endif
if (! -e "expression_mos2.txt") then
    echo "expression_mos2.txt missing. I cannot continue."
    exit(1)
endif
if (! -e "expression_pn.txt") then
    echo "expression_pn.txt missing. I cannot continue."
    exit(1)
endif

echo "READING expression file. Check the file and continue when ready (y/n)"
more expression_mos1.txt
more expression_mos2.txt
more expression_pn.txt
set ansYNexpressionfile=$<
if(${ansYNexpressionfile} != y) then
       exit(1)
endif


# SPECTRA
source ./make_spectrum.csh MOS ${mos1} ${mos1_src_xcen} ${mos1_src_ycen} ${mos1_src_radius} ${mos1_bkg_xcen} ${mos1_bkg_ycen} ${mos1_bkg_radius} 12 expression ${sbin} mode1 $OBSID[$kkk]"_mos1_" n < answer_expression_mos1.txt

set backm1_src=${backscale_src}
set backm1_bck=${backscale_bkg}
echo '*********************************************************'
echo 'Backscales for source and background...'
echo $backm1_src', '$backm1_bck
echo '*********************************************************'




source ./make_spectrum.csh MOS ${mos2} ${mos2_src_xcen} ${mos2_src_ycen} ${mos2_src_radius} ${mos2_bkg_xcen} ${mos2_bkg_ycen} ${mos2_bkg_radius} 12 expression ${sbin} mode1 $OBSID[$kkk]"_mos2_" n < answer_expression_mos2.txt

set backm2_src=${backscale_src}
set backm2_bck=${backscale_bkg}
echo '*********************************************************'
echo 'Backscales for source and background...'
echo $backm2_src', '$backm2_bck
echo '*********************************************************'


source ./make_spectrum.csh PN ${pn} ${pn_src_xcen} ${pn_src_ycen} ${pn_src_radius} ${pn_bkg_xcen} ${pn_bkg_ycen} ${pn_bkg_radius} 4 expression ${sbin} mode1 $OBSID[$kkk]"_pn_" n < answer_expression_pn.txt

set backpn_src=${backscale_src}
set backpn_bck=${backscale_bkg}

echo '*********************************************************'
echo 'Backscales for source and background...'
echo $backpn_src', '$backpn_bck
echo '*********************************************************'


endif



echo "Spectra done."
endif
echo ""







#################################################################
#  SECTION 5
#   
#  Light curves...
#
##################################################################
echo " "
echo 'Producing light curve for selected object in obsid...?(y/n) '$OBSID[$kkk]  
echo " "
set ansYN=$<
if(${ansYN} == y) then

# Copy scripts here 
cp  ${pipelinefolder}'/scripts/'make_light_curve.csh .
cp  ${pipelinefolder}'/scripts/'make_BaryCenCorrection.csh .
cp  ${pipelinefolder}'/scripts/'make_find_times.csh .
cp  ${pipelinefolder}'/scripts/'make_epiclccorr.csh .


########################################################################
# EVENT FILES MUST BE BARYCENTER CORRECTED BEFORE PRODUCING LIGHT CURVES
########################################################################
   echo ''
   echo 'Be aware: if you are interested in very short time periods, such as they appear in pulsars or cataclysmic variables, '
   echo 'you have to perform a barycentric correction. This means that the arrival time of a photon is shifted as is it would have'
   echo 'been detected at the barycentre of the solar system (the centre of mass) instead at the position of the satellite. '
   echo 'In this way, the data are comparable. The SAS task barycen performs this correction. As barycen overwrites the TIME column entries,'
   echo 'it is advisable first to copy the original event list and keep it as a backup.'
   echo ''
   
echo " "
echo 'Correcting for the barycenter...?(y/n) '$OBSID[$kkk]  
echo " "
set ansBarycenCorrYN=$<
if(${ansBarycenCorrYN} == y) then

# Backup
echo "Copying event files:" 
     cp ${mos1} "barycen_"${mos1}
     cp ${mos2} "barycen_"${mos2}
     cp ${pn} "barycen_"${pn}
echo "...done"

   echo "Writing txt file for barycencorrection script...: "${outfile} 
   set outfile="list_event_files.txt"
   rm -f ${outfile}
   touch  ${outfile}
   set endfile='END'	
  
cat <<${endfile} >> ${outfile} 
barycen_${mos1}
barycen_${mos2}
barycen_${pn}
${endfile}
echo "...done"
echo "Applying correction:"
source ./make_BaryCenCorrection.csh ${outfile}
echo "From now on, working on:" 
         set mos1="barycen_"${mos1}
         set mos2="barycen_"${mos2}
         set pn="barycen_"${pn}
         echo ${mos1}
         echo ${mos2}
         echo ${pn}
echo "...done"
endif


########################################################################
# PRODUCING LIGHT CURVES
########################################################################

# Setting dummies
set xphysical=0
set yphysical=0
set extrsrc=0
set extrbck=0

set mos1_src_xcen=0
set mos1_src_ycen=0
set mos1_src_radius=0
set mos1_bkg_xcen=0
set mos1_bkg_ycen=0
set mos1_bkg_radius=0

set mos2_src_xcen=0
set mos2_src_ycen=0
set mos2_src_radius=0
set mos2_bkg_xcen=0
set mos2_bkg_ycen=0
set mos2_bkg_radius=0

set pn_src_ycen=0
set pn_src_xcen=0
set pn_src_radius=0
set pn_bkg_ycen=0
set pn_bkg_xcen=0
set pn_bkg_radius=0


########################################################
# ENERGY MIN MAX
########################################################
     echo 'Light curve minimum energy (eV):'
     set emin=$<
     echo 'Light curve maximum energy (eV):'
     set emax=$<
########################################################
# BIN
########################################################
     echo 'Light curve bin (seconds):'
     set bin=$<
########################################################
# PATTERN
########################################################
     echo 'Pixel curve pattern:'
     set pattern=$<

#########################################################
# SPMODE 1 (USING THE NOMINAL COORDINATES AND GIVING IN INPUT ON RUNTIME THE source and bck radii in physical units. Bck is extracted in annuli)
# SPMODE 2 (USING THE EPIC REGION FILE. Bck is extracted in circles)
# SPMODE 3 (USING THE EXPRESSION FILE. More complicated regions are allowed using sas syntax.)
#########################################################
echo "Selecting the source region extraction mode...(1,2,3)?" 
set SPMODE=$<

# SPMODE = 1
if(${SPMODE} == 1) then
#################################################################
# NOMINAL COORDINATES AND INPUT RADII (REQUIRES IMAGE PRODUCED BEFORE)
#################################################################
echo ''
echo 'Extracting source nominal coordinates from image in physical units...' 
echo ''
source ./make_image.csh PN ${pn} ${emin} ${emax} 50 ${pattern} $OBSID[$kkk]"_pn_image" 
eregionanalyse imageset=$OBSID[$kkk]"_pn_image_${emin}"_"${emax}.fits" srcexp="((RA,DEC) IN CIRCLE(${RA},${DEC},0.0111))">tempo.txt
set xphysical=`tail -14 tempo.txt | head -1 | awk '{print $2}'`
set yphysical=`tail -13 tempo.txt | head -1 | awk '{print $2}'`
echo ''
echo 'Source physical coordinates are: '$xphysical', '$yphysical
echo ''


echo ''
echo "*** USING THE NOMINAL COORDINATES AND GIVING RADII ON RUNTIME *** "
echo 'The source and bck radii have to be entered in physical units. Bck is extracted in annuli.'
echo ''
echo "Enter the extraction radius for source..." 
set extrsrc=$<
echo "Enter the extraction radius for background" 
set extrbck=$<
     
 
     # Producing not syncronized light curves 
     # mos1  
     source ./make_light_curve.csh MOS ${mos1} ${xphysical} ${yphysical} ${extrsrc} ${xphysical} ${yphysical} ${extrbck} ${bin} ${emin} ${emax} ${pattern} annuli n 
     mv mos_source_lc.fits mos1_source_lc.fits
     mv mos_bck_lc.fits mos1_bck_lc.fits
     
     # mos2  
     source ./make_light_curve.csh MOS ${mos2} ${xphysical} ${yphysical} ${extrsrc} ${xphysical} ${yphysical} ${extrbck} ${bin} ${emin} ${emax} ${pattern} annuli n 
     mv mos_source_lc.fits mos2_source_lc.fits
     mv mos_bck_lc.fits mos2_bck_lc.fits
  
  
     # pn  
     source ./make_light_curve.csh PN ${pn} ${xphysical} ${yphysical} ${extrsrc} ${xphysical} ${yphysical} ${extrbck} ${bin} ${emin} ${emax} ${pattern} annuli n 
    
     # WRITE RESULTS IN LIST FILE
     ls *_source_lc.fits > list_lc_not_sync.txt

     source ./make_find_times.csh list_lc_not_sync.txt
     set tmin=`tail -2 absolute_times.txt | head -1 | awk '{print $1}'`
     set tmax=`tail -1 absolute_times.txt | head -1 | awk '{print $1}'`


     # Producing syncronized light curves 
     # mos1  
     source ./make_light_curve.csh MOS ${mos1} ${xphysical} ${yphysical} ${extrsrc} ${xphysical} ${yphysical} ${extrbck} ${bin} ${emin} ${emax} ${pattern} annuli n ${tmin} ${tmax}
     mv mos_source_lc.fits mos1_source_lc_sync.fits
     mv mos_bck_lc.fits mos1_bck_lc_sync.fits
   
     
     # mos2  
     source ./make_light_curve.csh MOS ${mos2} ${xphysical} ${yphysical} ${extrsrc} ${xphysical} ${yphysical} ${extrbck} ${bin} ${emin} ${emax} ${pattern} annuli n ${tmin} ${tmax}
     mv mos_source_lc.fits mos2_source_lc_sync.fits
     mv mos_bck_lc.fits mos2_bck_lc_sync.fits
     # pn  
     source ./make_light_curve.csh PN ${pn} ${xphysical} ${yphysical} ${extrsrc} ${xphysical} ${yphysical} ${extrbck} ${bin} ${emin} ${emax} ${pattern} annuli n ${tmin} ${tmax}
     mv pn_source_lc.fits pn_source_lc_sync.fits
     mv pn_bck_lc.fits pn_bck_lc_sync.fits
   
     
endif     
     
     
# SPMODE = 2
if(${SPMODE} == 2) then
#################################################################
# READ AGAIN EPIC REGION AND CHANGE IF REQUIRED
#################################################################
echo ''
echo "*** USING THE EPIC EXTRACTION REGION FILE ***"
echo ''
echo 'The epic_region.txt file contains information on the source'
echo 'and bck extraction circular regions. The following scripts need this file!'
echo 'Write the file now (before pressing y) or exit with n.'
echo ''
echo "READING epic regions. Check the file and continue when ready (y/n)"
set ansYNepicregionfile=$<
if(${ansYNepicregionfile} != y) then
       exit(1)
endif
if (! -e "epic_regions.txt") then
    echo "epic_regions.txt missing. I cannot continue."
    exit(1)
endif

# MOS 1
set mos1_src_xcen = `tail -6 epic_regions.txt | head -1 | cut -f2 -d"|"` 
set mos1_src_ycen = `tail -6 epic_regions.txt | head -1 | cut -f3 -d"|"` 
set mos1_src_radius =  `tail -6 epic_regions.txt | head -1 | cut -f4 -d"|"` 
set mos1_bkg_xcen = `tail -5 epic_regions.txt | head -1 |  cut -f2 -d"|"`
set mos1_bkg_ycen = `tail -5 epic_regions.txt | head -1 |  cut -f3 -d"|"` 
set mos1_bkg_radius = `tail -5 epic_regions.txt | head -1 |  cut -f4 -d"|"`
# MOS 2
set mos2_src_xcen = `tail -4 epic_regions.txt | head -1 | cut -f2 -d"|"` 
set mos2_src_ycen = `tail -4 epic_regions.txt | head -1 | cut -f3 -d"|"` 
set mos2_src_radius =  `tail -4 epic_regions.txt | head -1 | cut -f4 -d"|"` 
set mos2_bkg_xcen = `tail -3 epic_regions.txt | head -1 |  cut -f2 -d"|"`
set mos2_bkg_ycen = `tail -3 epic_regions.txt | head -1 |  cut -f3 -d"|"` 
set mos2_bkg_radius = `tail -3 epic_regions.txt | head -1 |  cut -f4 -d"|"`
# pn
set pn_src_xcen = `tail -2 epic_regions.txt | head -1 |  cut -f2 -d"|"` 
set pn_src_ycen = `tail -2 epic_regions.txt | head -1 |  cut -f3 -d"|"` 
set pn_src_radius =  `tail -2 epic_regions.txt | head -1 |  cut -f4 -d"|"` 
set pn_bkg_xcen = `tail -1 epic_regions.txt | head -1 |  cut -f2 -d"|"`
set pn_bkg_ycen = `tail -1 epic_regions.txt | head -1 |  cut -f3 -d"|"` 
set pn_bkg_radius = `tail -1 epic_regions.txt | head -1 |  cut -f4 -d"|"`
# Echo
echo "MOS1 source X,Y,R: "${mos1_src_xcen} ${mos1_src_ycen} ${mos1_src_radius}
echo "MOS1 background X,Y,R: "${mos1_bkg_xcen} ${mos1_bkg_ycen} ${mos1_bkg_radius}
echo "MOS2 source X,Y,R: "${mos2_src_xcen} ${mos2_src_ycen} ${mos2_src_radius}
echo "MOS2 background X,Y,R: "${mos2_bkg_xcen} ${mos2_bkg_ycen} ${mos2_bkg_radius}
echo "PN source X,Y,R: "${pn_src_xcen} ${pn_src_ycen} ${pn_src_radius}
echo "PN background X,Y,R: "${pn_bkg_xcen} ${pn_bkg_ycen} ${pn_bkg_radius}
echo '...done.'
echo ''     

     # Producing not syncronized light curves 
     # mos1  
     source ./make_light_curve.csh MOS ${mos1} ${mos1_src_xcen} ${mos1_src_ycen} ${mos1_src_radius} ${mos1_bkg_xcen} ${mos1_bkg_ycen} ${mos1_bkg_radius} ${bin} ${emin} ${emax} ${pattern} circles n 
     mv mos_source_lc.fits mos1_source_lc.fits
     mv mos_bck_lc.fits mos1_bck_lc.fits
   
     
     # mos2  
     source ./make_light_curve.csh MOS ${mos2} ${mos2_src_xcen} ${mos2_src_ycen} ${mos2_src_radius} ${mos2_bkg_xcen} ${mos2_bkg_ycen} ${mos2_bkg_radius} ${bin} ${emin} ${emax} ${pattern} circles  n 
     mv mos_source_lc.fits mos2_source_lc.fits
     mv mos_bck_lc.fits mos2_bck_lc.fits
  
     # pn  
     source ./make_light_curve.csh PN ${pn} ${pn_src_xcen} ${pn_src_ycen} ${pn_src_radius} ${pn_bkg_xcen} ${pn_bkg_ycen} ${pn_bkg_radius} ${bin} ${emin} ${emax} ${pattern} circles n 


     # WRITE RESULTS IN LIST FILE
     ls *_source_lc.fits > list_lc_not_sync.txt

     source ./make_find_times.csh list_lc_not_sync.txt
     set tmin=`tail -2 absolute_times.txt | head -1 | awk '{print $1}'`
     set tmax=`tail -1 absolute_times.txt | head -1 | awk '{print $1}'`
     
   
  
     #set tmin=5.64168690958644E+08
     
     #set tmax=5.64205020958644E+08

     # SYNC
     # mos1  
     source ./make_light_curve.csh MOS ${mos1} ${mos1_src_xcen} ${mos1_src_ycen} ${mos1_src_radius} ${mos1_bkg_xcen} ${mos1_bkg_ycen} ${mos1_bkg_radius} ${bin} ${emin} ${emax} ${pattern} circles n  ${tmin} ${tmax}
     mv mos_source_lc.fits mos1_source_lc_sync.fits
     mv mos_bck_lc.fits mos1_bck_lc_sync.fits
   
     # mos2  
     source ./make_light_curve.csh MOS  ${mos2} ${mos2_src_xcen} ${mos2_src_ycen} ${mos2_src_radius} ${mos2_bkg_xcen} ${mos2_bkg_ycen} ${mos2_bkg_radius} ${bin} ${emin} ${emax} ${pattern} circles n ${tmin} ${tmax}
     mv mos_source_lc.fits mos2_source_lc_sync.fits
     mv mos_bck_lc.fits mos2_bck_lc_sync.fits
   
   
     # pn  
     source ./make_light_curve.csh PN  ${pn} ${pn_src_xcen} ${pn_src_ycen} ${pn_src_radius} ${pn_bkg_xcen} ${pn_bkg_ycen} ${pn_bkg_radius} ${bin} ${emin} ${emax} ${pattern} circles n  ${tmin} ${tmax}
     mv pn_source_lc.fits pn_source_lc_sync.fits
     mv pn_bck_lc.fits pn_bck_lc_sync.fits
endif     




# SPMODE = 3
if(${SPMODE} == 3) then
#################################################################
# READ EXPRESSION FILE
#################################################################
echo ''
echo "*** USING EXPRESSION FILE ***"
echo ''
echo 'The expression file allows to use SAS syntax'
echo 'The following scripts need this file!'
echo 'Write the file now (before pressing y) or exit with n.'

echo "READING expression file. Check the file and continue when ready (y/n)"
set ansYNexpressionfile=$<
if(${ansYNexpressionfile} != y) then
       exit(1)
endif
if (! -e "expression_mos1.txt") then
    echo "expression_mos1.txt missing. I cannot continue."
    exit(1)
endif
if (! -e "expression_mos2.txt") then
    echo "expression_mos2.txt missing. I cannot continue."
    exit(1)
endif
if (! -e "expression_pn.txt") then
    echo "expression_pn.txt missing. I cannot continue."
    exit(1)
endif

    # Producing not syncronized light curves 
     # mos1  
     source ./make_light_curve.csh MOS ${mos1} ${xphysical} ${yphysical} ${extrsrc} ${xphysical} ${yphysical} ${extrbck} ${bin} ${emin} ${emax} ${pattern} annuli n 
     mv mos_source_lc.fits mos1_source_lc.fits
     mv mos_bck_lc.fits mos1_bck_lc.fits
  
     # mos2  
     source ./make_light_curve.csh MOS ${mos2} ${xphysical} ${yphysical} ${extrsrc} ${xphysical} ${yphysical} ${extrbck} ${bin} ${emin} ${emax} ${pattern} annuli n 
     mv mos_source_lc.fits mos2_source_lc.fits
     mv mos_bck_lc.fits mos2_bck_lc.fits
  
     # pn  
     source ./make_light_curve.csh PN ${pn} ${xphysical} ${yphysical} ${extrsrc} ${xphysical} ${yphysical} ${extrbck} ${bin} ${emin} ${emax} ${pattern} annuli n 

     # WRITE RESULTS IN LIST FILE
     ls *_source_lc.fits > list_lc_not_sync.txt

     source ./make_find_times.csh list_lc_not_sync.txt
     set tmin=`tail -2 absolute_times.txt | head -1 | awk '{print $1}'`
     set tmax=`tail -1 absolute_times.txt | head -1 | awk '{print $1}'`


     # Producing syncronized light curves 
     # mos1  
     source ./make_light_curve.csh MOS ${mos1} ${xphysical} ${yphysical} ${extrsrc} ${xphysical} ${yphysical} ${extrbck} ${bin} ${emin} ${emax} ${pattern} annuli n ${tmin} ${tmax} < answer_expression_mos1.txt
     mv mos_source_lc.fits mos1_source_lc_sync.fits
     mv mos_bck_lc.fits mos1_bck_lc_sync.fits
  
  
     # mos2  
     source ./make_light_curve.csh MOS ${mos2} ${xphysical} ${yphysical} ${extrsrc} ${xphysical} ${yphysical} ${extrbck} ${bin} ${emin} ${emax} ${pattern} annuli n ${tmin} ${tmax} < answer_expression_mos2.txt
     mv mos_source_lc.fits mos2_source_lc_sync.fits
     mv mos_bck_lc.fits mos2_bck_lc_sync.fits
  
     # pn  
     source ./make_light_curve.csh PN ${pn} ${xphysical} ${yphysical} ${extrsrc} ${xphysical} ${yphysical} ${extrbck} ${bin} ${emin} ${emax} ${pattern} annuli n ${tmin} ${tmax}  < answer_expression_pn.txt
     mv pn_source_lc.fits pn_source_lc_sync.fits
     mv pn_bck_lc.fits pn_bck_lc_sync.fits
     
endif

####################################################################
# Correcting light curves
####################################################################
echo ''
echo 'Correcting light curves...'
echo ''

source ./make_epiclccorr.csh ${mos1} mos1_source_lc_sync.fits mos1_bck_lc_sync.fits
mv epiclccorr_lc.fits mos1_lccorr_${bin}.fits 

source ./make_epiclccorr.csh ${mos2} mos2_source_lc_sync.fits mos2_bck_lc_sync.fits
mv epiclccorr_lc.fits mos2_lccorr_${bin}.fits

source ./make_epiclccorr.csh ${pn} pn_source_lc_sync.fits pn_bck_lc_sync.fits 
mv epiclccorr_lc.fits pn_lccorr_${bin}.fits
echo ''
echo 'done!'
echo ''

####################################################################
# Writing log file to be used by read_xmm_epilccorr.pro 
####################################################################
set loglcfile=$OBSID[$kkk]_loglccorr_${bin}.txt
touch ${loglcfile}

cat <<EOF>>${loglcfile}
mos1_lccorr_${bin}.fits 1
mos2_lccorr_${bin}.fits 1
pn_lccorr_${bin}.fits 1
EOF




endif







# Start next observation 
echo "Exiting '$OBSID[$kkk]' folder."
cd  ${pipelinefolder}
echo " "
set kkk=`expr $kkk + 1`

#		   
# END PROCESSING LOOP...
#
end	

# that's all folks
exit(0)



































                   
echo ''
echo 'Updating XSPEC file...'
echo ''


cat <<EOF>>${pipelinefolder}'/'${XSPECoutfile}
###########################################################
#
#  Analysis of the source $OBSID[$kkk]
#  (J2000) Coordinates: ${RA}, ${DEC}
#  Physical coordinates: ${xphysical}, ${yphysical}
# 
#  Data in ${pipelinefolder}/$OBSID[$kkk]/odf
#
###########################################################
cd ${pipelinefolder}/$OBSID[$kkk]
data 1:1 $OBSID[$kkk]_pn_spectrum_r.pi
data 1:2 $OBSID[$kkk]_mos1_spectrum_r.pi
data 1:3 $OBSID[$kkk]_mos2_spectrum_r.pi
setplot energy
cpd /xw
ignore bad
ignore 1:**-0.2
ignore 2:**-0.2
ignore 3:**-0.2
ignore 1:12.0-**
ignore 2:12.0-**
ignore 3:12.0-**
statistic chi
method leven 1000 0.01
abund angr
xsect bcmc
cosmo 70 0 0.73
xset delta -1

#################################################################################
# POWER LAW WITH ABSORPTION
#################################################################################
  model  phabs*(po)
  ${n_h}      0.001          0          0     100000      1e+06
  1           0.01         -3         -2          9         10
  1           0.01          0          0      1e+24      1e+24
#################################################################################
renorm
fit 1000
query ${queryflag}
error stopat ${numberoferrors},, maximum 10 2.70 1
tclout error 1
set tcl_var [string trim \$xspec_tclout]
regsub -all { +} \$tcl_var { } tcl_list
set tcl_slist [split \$tcl_list]
set nhm [lindex \$tcl_slist 0]
set nhp [lindex \$tcl_slist 1]
set errorflag_nh [lindex \$tcl_slist 2]
tclout param 1
set tcl_var [string trim \$xspec_tclout]
regsub -all { +} \$tcl_var { } tcl_list
set tcl_slist [split \$tcl_list]
set nh [lindex \$tcl_slist 0]
error stopat ${numberoferrors},, maximum 10 2.70 2
tclout error 2
set tcl_var [string trim \$xspec_tclout]
regsub -all { +} \$tcl_var { } tcl_list
set tcl_slist [split \$tcl_list]
set gammam [lindex \$tcl_slist 0]
set gammap [lindex \$tcl_slist 1]
set errorflag_gamma [lindex \$tcl_slist 2]
tclout param 2
set tcl_var [string trim \$xspec_tclout]
regsub -all { +} \$tcl_var { } tcl_list
set tcl_slist [split \$tcl_list]
set gamma [lindex \$tcl_slist 0]
flux 0.3 10.0 error 1000 90
tclout flux 1 
set tcl_var [string trim \$xspec_tclout]
regsub -all { +} \$tcl_var { } tcl_list
set tcl_slist [split \$tcl_list]
set fluxmodel  [lindex \$tcl_slist 0]
set fluxmodell  [lindex \$tcl_slist 1]
set fluxmodelu  [lindex \$tcl_slist 2]
delcomp 1
flux 0.2 10.0 
tclout flux 1 
set tcl_var [string trim \$xspec_tclout]
regsub -all { +} \$tcl_var { } tcl_list
set tcl_slist [split \$tcl_list]
set fluxmodeldel  [lindex \$tcl_slist 0]
exec echo  $OBSID[$kkk] \$nh \$nhm \$nhp \$gamma \$gammam \$gammap \$fluxmodel \$fluxmodell \$fluxmodelu \$fluxmodeldel >> ${pipelinefolder}/${FILEDATALL}
cd ${pipelinefolder} 
EOF

