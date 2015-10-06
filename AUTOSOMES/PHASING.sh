#!/bin/bash

for Inv in In055 In045 In340 In069 In266
	do
		#Get inversion chrm
		INV_CHRM=`cat ./PRECOMPUTED/VCFs_and_BPs/${Inv}/BP.positions | sed 's/-/\t/g' | cut -f1`
		if [[ "$INV_CHRM" =~ X ]]; then
					
			MERGE_SCRIPT="Merge_Xchrm.pl"
			VCFtoBEAGLE_SCRIPT="VCFtoBEAGLE_Xchrm.pl"
			VCFHap_SCRIPT="VCFhap_Xchrm.pl"
		else
			MERGE_SCRIPT="Merge.pl"
			VCFtoBEAGLE_SCRIPT="VCFtoBEAGLE.pl"
			VCFHap_SCRIPT="VCFhap.pl"
			
		fi

		for population in LWK JPT CHB TSI CEU YRI 
			do

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
					for cut_positions in `less cut_positions`
						do
						 	cut -f1-9,${cut_positions} ./PRECOMPUTED/VCFs_and_BPs/${Inv}/ALLPOPSALLREGION.vcf > ./${Inv}/VCF/${population}/${population}.vcf #corta las columnas con la informacion de las 9 primeras columnas del vcf + las especificas de los indivuduos de cada poblacion
						done
					
				rm cutted cutted2 cut_positions ALLPOPSALLREGION.vcf_ind_vcf #delete temporary files

			
				echo Adding BP genotypes for In = ${Inv} and POP = ${population}
				## Este es el paso dondo incorporo los BPs de las inversiones como si fuesen dos SNPs mas a los VCFs de cada poblacion (generados en el paso anterior). La dificultad es incorporar los BPs en el orden que les toca.

					perl AddBPs.pl -BPs_file ./${Inv}/LISTS/${population}/${population}.BP.ALLPOP.list > ./${Inv}/VCF/${population}/${population}.BP.ALLPOP.transposed1.List
					
						## File Format Preparation
						sed 's/ //g' ./${Inv}/VCF/${population}/${population}.BP.ALLPOP.transposed1.List | sed 's/ID/POS/g' > ./${Inv}/VCF/${population}/${population}.BP.ALLPOP.transposed.List
						paste ./PRECOMPUTED/POPs_LIST/template ./${Inv}/VCF/${population}/${population}.BP.ALLPOP.transposed.List | sed 's/\t\t/\t/g' | awk '{temp = $2; $2 = $10; $10 = temp; print}' | sed 's/ /	/g' | awk '{for (i=1; i<=NF; i++) if (i<10 || i>10) printf $i "	"; print""}' > ./${Inv}/VCF/${population}/${population}.BP.ALLPOP.VCF.List
						sed '1,2d' ./${Inv}/VCF/${population}/${population}.BP.ALLPOP.VCF.List > ./${Inv}/VCF/${population}/Bottom # BP2
						sed '3d'   ./${Inv}/VCF/${population}/${population}.BP.ALLPOP.VCF.List | sed '1d' > Top # BP1
						grep CHROM ./${Inv}/VCF/${population}/${population}.BP.ALLPOP.VCF.List > ./${Inv}/VCF/${population}/head # header
						cat ./${Inv}/VCF/${population}/${population}.vcf ./${Inv}/VCF/${population}/Bottom > ./${Inv}/VCF/${population}/${population}.B.vcf
						sed '30r Top' ./${Inv}/VCF/${population}/${population}.B.vcf > ./${Inv}/VCF/${population}/${population}.BP.vcf2
						sed '1,29d'   ./${Inv}/VCF/${population}/${population}.BP.vcf2 > ./${Inv}/VCF/${population}/${population}.BP.vcf3 
						sed '1,1d'    ./${Inv}/VCF/${population}/${population}.BP.vcf3 > ./${Inv}/VCF/${population}/${population}.BP.vcf4 
						sort -k2,2n ./${Inv}/VCF/${population}/${population}.BP.vcf4 > ./${Inv}/VCF/${population}/${population}.BP.vcf5
						cat ./${Inv}/VCF/${population}/head ./${Inv}/VCF/${population}/${population}.BP.vcf5 > ./${Inv}/VCF/${population}/${population}.BP.vcf

					rm ./${Inv}/VCF/${population}/${population}.BP.ALLPOP.transposed1.List ./${Inv}/VCF/${population}/${population}.BP.ALLPOP.transposed.List Top ./${Inv}/VCF/${population}/Bottom ./${Inv}/VCF/${population}/${population}.B.vcf ./${Inv}/VCF/${population}/${population}.BP.ALLPOP.VCF.List ./${Inv}/VCF/${population}/${population}.BP.vcf2 ./${Inv}/VCF/${population}/${population}.BP.vcf3 ./${Inv}/VCF/${population}/head ./${Inv}/VCF/${population}/${population}.BP.vcf4 ./${Inv}/VCF/${population}/${population}.BP.vcf5 #delete temporary files


				echo Creating Beagle Input for In = ${Inv} and POP = ${population}
				## En este paso cambio de formato, de VCF a input del Beagle. 
					
					perl $VCFtoBEAGLE_SCRIPT -vcf ./${Inv}/VCF/${population}/${population}.BP.vcf > ${population}.beagle.temp
					sed 's/ //g' ${population}.beagle.temp | sed '/^$/d' | sed 's/ID/marker/g' | sed 's/REF/alleleA/g' | sed 's/ALT/alleleB/g' | 	sed 's/	1.0000	1.0000	1.0000//g' > ./${Inv}/BEAGLE/INPUT/${population}.beagle.inp
				
				rm ${population}.beagle.temp #delete temporary files


				echo Running Beagle for In = ${Inv} and POP = ${population}
				## Corro dos veces Beagle, una con todos los SNPs y otra con los SNPs de mayor calidad.

					java -Xmx1000m -jar beagle.jar like=./${Inv}/BEAGLE/INPUT/${population}.beagle.inp out=./${Inv}/BEAGLE/OUTPUT/output1 seed=8 &
					wait
					perl exclude.pl -file ./${Inv}/BEAGLE/OUTPUT/output1.${population}.beagle.inp.r2 > ./${Inv}/BEAGLE/OUTPUT/excluded.${population} &
					wait
					java -Xmx1000m -jar beagle.jar like=./${Inv}/BEAGLE/INPUT/${population}.beagle.inp out=./${Inv}/BEAGLE/OUTPUT/output2 seed=8 nsamples=20 niterations=20 excludemarkers=./${Inv}/BEAGLE/OUTPUT/excluded.${population}


				## Dealing with BEAGLE outputs:

				for output in output1 output2
					do	

						echo Switch Error Analysis for ${Inv} - ${population} and ${output}

							gunzip ./${Inv}/BEAGLE/OUTPUT/${output}.${population}.beagle.inp.phased.gz 
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
							for cut_positions in `less cut_positions`
								do
								 	cut -f1-9,${cut_positions} ./${Inv}/VCF/${population}/output3 > ./${Inv}/VCF/${population}/output4 #corta las columnas con la informacion de las 9 primeras columnas del vcf + las especificas de los invertidos
								done
							
							awk '{print $3}' ./${Inv}/VCF/${population}/output4 > ./${Inv}/VCF/${population}/rsoutput4					
							paste ./${Inv}/VCF/${population}/output4 ./${Inv}/VCF/${population}/rsoutput4	> ./${Inv}/VCF/${population}/output5						
				
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

			done
	done

exit 0
