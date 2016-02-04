#!/bin/bash
# Argument = -i inversionlist -p -b

usage()
{
cat << EOF
usage: $0 options

This script phases inversions with Beagle 3.3.2.

OPTIONS:
   -h      Show this message
   -i      List of inversions to phase e.g. "HsInv0045 HsInv0055 HsInv0063"
   -p      Skip all PRECOMPUTED files creation
   -b      Skip BEAGLE binary link creation
   -l      Skip list of 1000G populaton download
   -v      Skip vcf of 1000G download

EXAMPLES:
   1. To phase everything from the scratch
           PHASING.sh -i "HsInv0045 HsInv0072"
   2. To phase a new inversion
           PHASING.sh -i "HsInv1234" -bl
   3. To re-phase an inversion with new genotypes
           PHASING.sh -i "HsInv0072" -blv

EOF
}

INVERSIONS=""
CREATEPREFILES=1
LINKBEAGLE=1
LISTS=1
DOWNLOADVCF=1

while getopts hi:pblv OPTION; do
     case $OPTION in
         h)
             usage
             exit 1
             ;;
         i)
             INVERSIONS=$OPTARG
             ;;
         p)
             CREATEPREFILES=0
             ;;
         b)
             LINKBEAGLE=0
             ;;
         l)
             LISTS=0
             ;;
         v)
             DOWNLOADVCF=0
             ;;
         ?)
             usage
             exit
             ;;
         *)
             echo "Invalid arg"
             usage
             exit
             ;; 
     esac
done

if [[ -z $INVERSIONS ]]; then
    echo -e "\nNeed to specify inversion list e.g. -i \"HsInv0045 HsInv0055 HsInv0063\"\n"
    usage
    exit 1
fi


# Create INPUT #####################################################################################################
INPUTDIR="PRECOMPUTED"
ANNOTFILE="/home/shareddata/Bioinformatics/InversionAnnotation/v3LiftOver/hg19_positions.txt"
GENOFILE="/home/shareddata/Experimental_data/InversionGenotypes/InvGenotypes_v4.4_45invs_complete_20150923.txt"

if [[ $CREATEPREFILES && $LISTS ]]; then
    mkdir -p $INPUTDIR
fi

# POPs_LIST from KGP Ph1 
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
if [[ "$LISTS" == 1 ]]; then

    mkdir -p ${INPUTDIR}/POPs_LIST
    wget ftp://ftp.1000genomes.ebi.ac.uk/vol1/ftp/release/20110521/phase1_integrated_calls.20101123.ALL.panel

    for population in LWK JPT CHB TSI CEU YRI; do
        grep $population phase1_integrated_calls.20101123.ALL.panel | cut -f1 >${INPUTDIR}/POPs_LIST/1000G.UnGenotyped.${population}.List
    done

    rm phase1_integrated_calls.20101123.ALL.panel

    # Also David's template file for BPs
    echo -e "#CHROM  POS     ID      REF     ALT     QUAL    FILTER  INFO    FORMAT  
SUBSTCHR       X       BP1     S       I       100     PASS    AA=.;AC=;AF=;AFR_AF=;AMR_AF=;AN=;ASN_AF=;AVGPOST=;ERATE=;EUR_AF=;LDAF=;RSQ=;SNPSOURCE=;THETA=;VT=SNP    GT:DS:GL        
SUBSTCHR       X       BP2     S       I       100     PASS    AA=.;AC=;AF=;AFR_AF=;AMR_AF=;AN=;ASN_AF=;AVGPOST=;ERATE=;EUR_AF=;LDAF=;RSQ=;SNPSOURCE=;THETA=;VT=SNP    GT:DS:GL" >${INPUTDIR}/POPs_LIST/template
fi
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# VCFs_and_BPs from InvFEST data and KGP Ph1
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
if [[ "$CREATEPREFILES" == 1 ]]; then
    for Inv in ${INVERSIONS}; do
        mkdir -p ${INPUTDIR}/VCFs_and_BPs/${Inv}
        
        # inner BP positions BP1END..BP2START
       	echo "Creating BP.positions file for $Inv"
        BP1=(`cat $ANNOTFILE | grep $Inv | grep "BP1" | cut -f-3`)
        BP2=(`cat $ANNOTFILE | grep $Inv | grep "BP2" | cut -f-3`)
        echo -e "${BP1[0]}-${BP1[2]}-${BP2[1]}" >${INPUTDIR}/VCFs_and_BPs/${Inv}/BP.positions
        
        # VCF download (BP1START-2000000..BP2END+2000000)
        if [[ "$DOWNLOADVCF" == 1 ]]; then
            echo "Downloading 1000GP Ph1 SNPs for $Inv"
	        CHR=`echo ${BP1[0]} | sed "s/chr//"` 
            START=$((${BP1[1]}-2000000))
            END=$((${BP2[2]}+2000000))
            tabix -hf ftp://ftp.1000genomes.ebi.ac.uk/vol1/ftp/release/20110521/ALL.chr${CHR}.phase1_release_v3.20101123.snps_indels_svs.genotypes.vcf.gz ${CHR}:${START}-${END} >${INPUTDIR}/VCFs_and_BPs/${Inv}/ALLPOPSALLREGION.vcf
        fi

        # Individual genotypes
        echo "Creating Genotypes file for $Inv"
        COL=`cat $GENOFILE | head -2 | tail -1 | tr "\t" "\n" | grep -n $Inv | sed "s/:$Inv//"`
        if [[ "$CHR" == "X" ]]; then
            echo "$Inv is in chrX, males have one allele"
            cat $GENOFILE | tail -n+3 | cut -f1,3,5,$COL | awk -v OFS='\t' '{print $2,$1,$3,$4;}' | sed "s/\tFemale\tINV/\tII/" | sed "s/\tFemale\tSTD/\tSS/" | sed "s/\tFemale\tHET/\tSI/" | grep -vP "\tNA$" | grep -vP "\tND$" | sed "s/\tMale\tINV/\tI-/" | sed "s/\tMale\tSTD/\tS-/" >${INPUTDIR}/VCFs_and_BPs/${Inv}/HapMap.Genotyped.List
        else
            cat $GENOFILE | tail -n+3 | cut -f1,3,$COL | awk -v OFS='\t' '{print $2,$1,$3;}' | sed "s/\tINV/\tII/" | sed "s/\tSTD/\tSS/" | sed "s/\tHET/\tSI/" | grep -vP "\tNA$" | grep -vP "\tND$" >${INPUTDIR}/VCFs_and_BPs/${Inv}/HapMap.Genotyped.List
        fi    	    
    done

fi
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
####################################################################################################################



# Link BEAGLE binary ###############################################################################################
if [[ "$LINKBEAGLE" == 1 && ! -f beagle.jar ]]; then
    ln -s /home/dcastellano/shared/Phased.Inversions/beagle.jar beagle.jar
fi
####################################################################################################################



# David's pipeline #################################################################################################
for Inv in ${INVERSIONS}; do
    #Get inversion chrm
    INV_CHRM=`cat ./PRECOMPUTED/VCFs_and_BPs/${Inv}/BP.positions | sed 's/-/\t/g' | cut -f1 | sed "s/chr//"`
    if [[ "$INV_CHRM" =~ X ]]; then
                
        MERGE_SCRIPT="Merge_Xchrm.pl"
        VCFtoBEAGLE_SCRIPT="VCFtoBEAGLE_Xchrm.pl"
        VCFHap_SCRIPT="VCFhap_Xchrm.pl"
    else
        MERGE_SCRIPT="Merge.pl"
        VCFtoBEAGLE_SCRIPT="VCFtoBEAGLE.pl"
        VCFHap_SCRIPT="VCFhap.pl"
        
    fi

    for population in LWK JPT CHB TSI CEU YRI; do

        echo Creating Folders

            mkdir -p ./${Inv}/LISTS/${population}
            mkdir -p ./${Inv}/VCF/${population}
            mkdir -p ./${Inv}/SE 
            mkdir -p ./${Inv}/BEAGLE/OUTPUT
            mkdir -p ./${Inv}/BEAGLE/INPUT
            mkdir -p ./${Inv}/VCFhap/${population}
            mkdir -p ./SE 


        echo Creating LIST for In = ${Inv} and POP = ${population}
        ## Aqui pongo los individuos presentes en ambas listas (la lista de genotipados experimentalmente + lista de individuos del proyecto 1000 G) en formato likelihood para luego introducirlo en el VCF de los SNPs. Para cada poblacion por separado. Recordad que phaseamos todos los individuos de 1000 G, esten o no genotipados experimentalmente, pero al final elimino los individuos para los que se ha imputado la inversion y los individuos con switch errors.
            
            perl $MERGE_SCRIPT -genotyped_list ./PRECOMPUTED/VCFs_and_BPs/${Inv}/HapMap.Genotyped.List -1000G_list ./PRECOMPUTED/POPs_LIST/1000G.UnGenotyped.${population}.List -BPs_file ./PRECOMPUTED/VCFs_and_BPs/${Inv}/BP.positions -Population ${population} -Inv ${Inv}
            # Genera el output que encontrareis en: ./${Inv}/LISTS/${population}/${population}.BP.ALLPOP.list

        echo Spliting VCF for In = ${Inv} and POP = ${population}
        ## Aqui cojo el VCF orginal donde estan todos los individuos de 1000 G y selecciono solo aquellos individuos pertenecientes a una poblacion (hayan sido o no genotipados para las inversiones experimentalmente). En otras palabras hago un VCF para cada poblacion.
        ## Los respectivos outputs estan en: ./${Inv}/VCF/${population}/${population}.vcf

            grep CHROM ./PRECOMPUTED/VCFs_and_BPs/${Inv}/ALLPOPSALLREGION.vcf | sed -e 's/\t\+/\n/g' > ALLPOPSALLREGION.vcf_ind_vcf #hace una lista de todos los individuos del vcf original
            perl SplitVCF.pl -vcf ALLPOPSALLREGION.vcf_ind_vcf -desired_individuals ./PRECOMPUTED/POPs_LIST/1000G.UnGenotyped.${population}.List > cutted #busca el num de columna especifico del vcf original para la lista dada de individuos
            sed -e 's/\s\+//g' cutted > cutted2 # elimina espacios en blanco
            sed 's/,$//' cutted2 > cut_positions # elimina la ultima coma :D
            cut_positions=`less cut_positions` 
            cut -f1-9,${cut_positions} ./PRECOMPUTED/VCFs_and_BPs/${Inv}/ALLPOPSALLREGION.vcf > ./${Inv}/VCF/${population}/${population}.vcf #corta las columnas con la informacion de las 9 primeras columnas del vcf + las especificas de los indivuduos de cada poblacion
            
        rm cutted cutted2 cut_positions ALLPOPSALLREGION.vcf_ind_vcf #delete temporary files

    
        echo Adding BP genotypes for In = ${Inv} and POP = ${population}
        ## Este es el paso dondo incorporo los BPs de las inversiones como si fuesen dos SNPs mas a los VCFs de cada poblacion (generados en el paso anterior). La dificultad es incorporar los BPs en el orden que les toca.
            ## File Format Preparation
            # BP positions
            perl AddBPs.pl -BPs_file ./${Inv}/LISTS/${population}/${population}.BP.ALLPOP.list > ./${Inv}/VCF/${population}/${population}.BP.ALLPOP.transposed1.List
            sed 's/ //g' ./${Inv}/VCF/${population}/${population}.BP.ALLPOP.transposed1.List | sed 's/ID/POS/g' > ./${Inv}/VCF/${population}/${population}.BP.ALLPOP.transposed.List
            paste <(cat ./PRECOMPUTED/POPs_LIST/template | sed "s/SUBSTCHR/${INV_CHRM}/g") ./${Inv}/VCF/${population}/${population}.BP.ALLPOP.transposed.List | sed 's/\t\t/\t/g' | awk '{temp = $2; $2 = $10; $10 = temp; print}' | sed 's/ /    /g' | awk '{for (i=1; i<=NF; i++) if (i<10 || i>10) printf $i "    "; print""}' | tr -s " " | tr " " "\t"> ./${Inv}/VCF/${population}/${population}.BP.ALLPOP.VCF.List # Create complete rows for BPs
            # Merge with POP.vcf (without header)
            grep -v "##" ${Inv}/VCF/${population}/${population}.vcf > ${Inv}/VCF/${population}/${population}.vcf_temp # delete header "##"
            grep -v "#" ${Inv}/VCF/${population}/${population}.BP.ALLPOP.VCF.List >> ${Inv}/VCF/${population}/${population}.vcf_temp ## Add BPs at the end
            sort -k2,2n ${Inv}/VCF/${population}/${population}.vcf_temp > ${Inv}/VCF/${population}/${population}.BP.vcf # sort positions

            rm ./${Inv}/VCF/${population}/${population}.BP.ALLPOP.transposed1.List ./${Inv}/VCF/${population}/${population}.BP.ALLPOP.transposed.List ./${Inv}/VCF/${population}/${population}.BP.ALLPOP.VCF.List ${Inv}/VCF/${population}/${population}.vcf_temp #delete temporary files


        echo Creating Beagle Input for In = ${Inv} and POP = ${population}
        ## En este paso cambio de formato, de VCF a input del Beagle. 
            if [[ "$INV_CHRM" == "X" ]]; then
                perl $VCFtoBEAGLE_SCRIPT -vcf ./${Inv}/VCF/${population}/${population}.BP.vcf -gender ./${Inv}/LISTS/${population}/${population}.BP.ALLPOP.list > ${population}.beagle.temp
			    sed 's/ //g' ${population}.beagle.temp | sed '/^$/d' > ./${Inv}/BEAGLE/INPUT/${population}.beagle.inp

            else
                perl $VCFtoBEAGLE_SCRIPT -vcf ./${Inv}/VCF/${population}/${population}.BP.vcf > ${population}.beagle.temp
                sed 's/ //g' ${population}.beagle.temp | sed '/^$/d' | sed 's/ID/marker/g' | sed 's/REF/alleleA/g' | sed 's/ALT/alleleB/g' | sed 's/\t1.0000\t1.0000\t1.0000//g' > ./${Inv}/BEAGLE/INPUT/${population}.beagle.inp
            fi
        rm ${population}.beagle.temp #delete temporary files


        echo Running Beagle for In = ${Inv} and POP = ${population}
        ## Corro dos veces Beagle, una con todos los SNPs y otra con los SNPs de mayor calidad.

            java -Xmx1000m -jar beagle.jar like=./${Inv}/BEAGLE/INPUT/${population}.beagle.inp out=./${Inv}/BEAGLE/OUTPUT/output1 seed=8 &
            wait
            perl exclude.pl -file ./${Inv}/BEAGLE/OUTPUT/output1.${population}.beagle.inp.r2 > ./${Inv}/BEAGLE/OUTPUT/excluded.${population} &
            wait
            java -Xmx1000m -jar beagle.jar like=./${Inv}/BEAGLE/INPUT/${population}.beagle.inp out=./${Inv}/BEAGLE/OUTPUT/output2 seed=8 nsamples=20 niterations=20 excludemarkers=./${Inv}/BEAGLE/OUTPUT/excluded.${population}


        ## Dealing with BEAGLE outputs:

        for output in output1 output2; do

            echo Switch Error Analysis for ${Inv} - ${population} and ${output}

                gunzip -f ./${Inv}/BEAGLE/OUTPUT/${output}.${population}.beagle.inp.phased.gz 
                grep BP ./${Inv}/BEAGLE/OUTPUT/${output}.${population}.beagle.inp.phased > BP.temp
                grep id ./${Inv}/BEAGLE/OUTPUT/${output}.${population}.beagle.inp.phased > id.temp
                cat id.temp BP.temp > ./${Inv}/SE/${Inv}.${population}.BP.${output}
                perl Transpose.pl -file ./${Inv}/SE/${Inv}.${population}.BP.${output} > ./${Inv}/SE/transposed_${Inv}.${population}.BP.${output}.temp
                sed -e 's/ //g' ./${Inv}/SE/transposed_${Inv}.${population}.BP.${output}.temp > ./${Inv}/SE/transposed_${Inv}.${population}.BP.${output}
                perl SE.pl -file1 ./PRECOMPUTED/VCFs_and_BPs/${Inv}/HapMap.Genotyped.List -file2 ./${Inv}/SE/transposed_${Inv}.${population}.BP.${output} >> SE/Switch_Error_Analysis
            
            rm BP.temp id.temp ./${Inv}/SE/transposed_${Inv}.${population}.BP.${output}.temp ./${Inv}/SE/${Inv}.${population}.BP.${output} #delete temporary files


            echo Generating VCFhap ${Inv} - ${population} and BEAGLE ${output}
                
                cut -f1-9 ./${Inv}/VCF/${population}/${population}.BP.vcf > ./${Inv}/VCF/${population}/rs_info #Estos BPs tienen q estar bien puestos!!
                awk '{print $3,$1,$2,$4,$5,$6,$7,$8,$9}' ./${Inv}/VCF/${population}/rs_info | sed -e 's/\s\+/\t/g' > ./${Inv}/VCF/${population}/rs_info2
                cut -d " " -f 2- ./${Inv}/BEAGLE/OUTPUT/${output}.${population}.beagle.inp.phased | sed -e 's/\s\+/\t/g' | sed 's/id/ID/g' > ./${Inv}/VCF/${population}/output
                awk 'NR==FNR{a[$1]=$0; next;}$1 in a {print $2,$3,$1,$4,$5,$6,$7,$8,$9"\t"a[$1]}' ./${Inv}/VCF/${population}/output ./${Inv}/VCF/${population}/rs_info2 | sed 's/\t\t//g' > ./${Inv}/VCF/${population}/output2
                awk '{for (i=1; i<=NF; i++) if (i<10 || i>10) printf $i "\t"; print"\t"}' ./${Inv}/VCF/${population}/output2 | sed 's/GT:DS:GL/GT/g' | sed 's/\t\t//g' > ./${Inv}/VCF/${population}/output3


            echo Excluding In Silico Genotyped Individuals and Individuals with SE for In = ${Inv} and POP = ${population} and BEAGLE ${output}

                grep CHROM ./${Inv}/VCF/${population}/output3 | sed -e 's/\t\+/\n/g' > complete_list #hace una lista de todos los individuos del vcf original 
                perl SplitVCF2.pl -BPs ./${Inv}/SE/transposed_${Inv}.${population}.BP.${output} -Genotyped ./PRECOMPUTED/VCFs_and_BPs/${Inv}/HapMap.Genotyped.List > cutted #busca el num de columna especifico del vcf original para la lista dada de individuos
                sed -e 's/\s\+//g' cutted > cutted2
                sed 's/,$//' cutted2 > cut_positions
                cut_positions=`less cut_positions` 
                cut -f1-9,${cut_positions} ./${Inv}/VCF/${population}/output3 > ./${Inv}/VCF/${population}/output4 #corta las columnas con la informacion de las 9 primeras columnas del vcf + las especificas de los invertidos
                
                awk '{print $3}' ./${Inv}/VCF/${population}/output4 > ./${Inv}/VCF/${population}/rsoutput4                    
                paste ./${Inv}/VCF/${population}/output4 ./${Inv}/VCF/${population}/rsoutput4    > ./${Inv}/VCF/${population}/output5                        
    
                ## Aqui estan todos los SNPs, sepamos o no el estado ancestral.
                
                perl $VCFHap_SCRIPT -file ./${Inv}/VCF/${population}/output5 | sed '/^$/d' | sed 's/\t\s/\t/g' | sed 's/\t\s/\t/g' > ./${Inv}/VCF/${population}/output6
                grep 'CHROM' ./${Inv}/VCF/${population}/output6 >  BPs
                grep 'BP'    ./${Inv}/VCF/${population}/output6 >> BPs
                perl Transpose.pl -file BPs > trans_BPs
                awk '{print $1}' trans_BPs | head -n 9 > trans2_BPs
                sed '1,9d' trans_BPs | sed 's/\t\s/-/g'  | sed 's/0-0/S/g' | sed 's/1-1/I/g' | sed 's/\s//g' >> trans2_BPs
                perl Transpose.pl -file trans2_BPs > BPs_curated
                sed '1d' ./${Inv}/VCF/${population}/output6 > output7
                cat BPs_curated output7 > output8
                sed 's/ #CHROM/#CHROM/g' output8 | sed 's/\t\s/\t/g' | sed 's/\t1\t\n/\n/g' | sed 's/\tIDf-I\t\n/\n/g' > ./${Inv}/VCFhap/${population}/${Inv}.${population}.phased.${output}.vcf
            
            rm complete_list ./${Inv}/VCF/${population}/output4 ./${Inv}/VCF/${population}/output5 ./${Inv}/VCF/${population}/rsoutput4 ./${Inv}/VCF/${population}/rs_info ./${Inv}/VCF/${population}/rs_info2 ./${Inv}/VCF/${population}/output ./${Inv}/VCF/${population}/output2 ./${Inv}/VCF/${population}/output3 cutted cutted2 cut_positions ./${Inv}/VCF/${population}/output6 BPs trans_BPs trans2_BPs BPs_curated output8 output7
        done
        #Reprint meta information header
        printf "$header\n$(cat ${Inv}/VCFhap/${population}/${Inv}.${population}.phased.output2.vcf)" > ${Inv}/VCFhap/${population}/${Inv}.${population}.phased.output2.vcf
        printf "$header\n$(cat ${Inv}/VCFhap/${population}/${Inv}.${population}.phased.output1.vcf)" > ${Inv}/VCFhap/${population}/${Inv}.${population}.phased.output1.vcf
        printf "$header\n$(cat ${Inv}/VCF/${population}/${population}.BP.vcf)" > ${Inv}/VCF/${population}/${population}.BP.vcf
    done
done
####################################################################################################################

exit 0
