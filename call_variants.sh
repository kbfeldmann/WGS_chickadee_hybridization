#!/bin/bash

# MODIFIED FROM ERIK R FUNK
if [ $# -lt 1 ]
  then
    echo "Call variants using bcftools mpileup.
    [-i] Path to directory of sorted bam files
    [-r] Reference genome
    OPTIONAL ARGUMENTS
    [-g] Regions file to limit the variant call
    [-f] Logical to filter - if yes, type T. Filters pass only high quality snps
    [-o] Output prefix"

  else
    while getopts i:r:g:f:o: option
    do
    case "${option}"
    in
    i) bamdir=${OPTARG};;
    r) ref=${OPTARG};;
    g) regions=${OPTARG};;
    f) filter=${OPTARG};;
    o) out=${OPTARG};;
    esac
    done

    bamdir="${bamdir:-sorted_bam_files/}"
    regions="${regions:-FALSE}"
    filter="${filter:-F}"
    out="${out:-output}"

    date >> $out.log
    echo "making a pileup file for" $out >> $out.log
    # Check if a regions file is provouted then call mpileup
    if [ $regions == FALSE ]
      then
        bcftools mpileup -Ou -f $ref --ignore-RG -a AD,ADF,DP,SP,INFO/AD,INFO/ADF \
        "$bamdir"*.bam | bcftools call -mv > "$out"_raw_variants.vcf
      else
        bcftools mpileup -Ou -f $ref --ignore-RG --regions-file $regions \
        -a AD,ADF,DP,SP,INFO/AD,INFO/ADF \
        "$bamdir"*.bam | bcftools call -mv > "$out"_raw_variants.vcf
    fi

    # Check if filtering is required then either filter or pass
    if [ $filter == T ]
      then
        echo "filtering low quality snps (<100) for" $out >> $out.log
        awk '$1~/^#/ || $6 > 100 {print $0}' > \
        "$out"_filtered_variants.vcf "$out"_raw_variants.vcf
        echo "checking the length of column 4 and 5 to make sure
        they are snp type variants for " $out >> $out.log
        awk '$1~/^#/ || length($4)==1 && length($5)==1 {print $0}'> \
        "$out"_filtered_snps.vcf "$out"_filtered_variants.vcf
      else
        echo "Not filtering" $out >> $out.log
    fi
fi

# Call snps in samtools
# Erik's original script from which the above was modified
#ref="/data2/rosyfinches/HouseFinch/final.assembly.homo.fa"
#bamdir="/data2/rosyfinches/sorted_bam_files/"
#regions="/data5/meadowlarks/scaffolds1-2000.txt"
#out="rosyfinches" # This will be used as a prefix for the output file

#echo "making a pileup file for" $out >> $out.log
#can also add the -R flag joined with a scaffold list to subset and parralel
#bcftools mpileup -Ou -f $ref--ignore-RG --regions-file $regions -a AD,ADF,DP,SP,INFO/AD,INFO/ADF \
#"$bamdir"*.bam | bcftools call -mv > "$out"_raw_variants.vcf
#echo "removing all lines with two comment marks" >> $out.log
#grep -v "##" "$out"_snps_indels.vcf > "$out"_snps_indels_short.vcf
#echo "filtering low quality snps (<100)" >> $out.log
#awk '$1~/^#/ || $6 > 100 {print $0}' > \
#"$out"_snps_indels_filtered.vcf "$out"_snps_indels_short.vcf
#echo "add the header and check length of column 4 and 5 to make sure
#they are snp type variants" >> $out.log
#awk '$1~/^#/ || length($4)==1 && length($5)==1 {print $0}'> \
#"$out"_snps_filtered.vcf "$out"_snps_indels_filtered.vcf