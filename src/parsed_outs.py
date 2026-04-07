import pandas as pd
import argparse as ap
import os
    

def parse_hisat(dict_res:dict, met_path:str, flag:str) -> pd.DataFrame:
    """
    Fuction that parse the hisat log files and the met tables
    Args:
        -dict_res: a dictionary with the results of the hisat log file
        -met_path: the path to the hisat met file
        -flag: a string that indicate if the log file is for paired or unpaired reads
    Returns:     
        -dataframe with the parsed results
    
    """
    hi_met_df = pd.read_csv(met_path, sep="\t")
    hi_dict ={}
    # extract the overall aligned
    hi_dict["Total_aligned"]=float(dict_res["Overall alignment rate"].split("%")[0].strip()) / 100
    match flag:
        case "PR":
            # extract all the sequences:
            all_seqs = int(dict_res["Total pairs"]) + int(
                    dict_res["Total unpaired reads"]
                )
            # now we store sequences that were not aligned
            hi_dict["Non_aligned"]=(
                    int(dict_res["Aligned concordantly or discordantly 0 time"].split(" ")[1])
                    + int(dict_res["Aligned 0 time"].split(" ")[1])
                )/ all_seqs
            # now extract the reads unique aligned
            hi_dict["Unique_aligned"]=(
                    int(dict_res["Aligned concordantly 1 time"].split(" ")[1])
                    + int(dict_res["Aligned 1 time"].split(" ")[1])
                )/ all_seqs
            # The reads multimaped
            hi_dict["Multimaped"]=(
                    int(dict_res["Aligned discordantly 1 time"].split(" ")[1])
                    + int(dict_res["Aligned >1 times"].split(" ")[1])
                )/ all_seqs
            # finally the time it taked
            hi_dict["Time(min)"]=((int(hi_met_df["Time"].iloc[0]) / 1e6) / 60)
        case "UN":
            # extract all the sequences:
            all_seqs = int(dict_res["Total reads"])
            # if it can parsed like the above structure it may be a un parired aligenment
            hi_dict["Non_aligned"]=(int(dict_res["Aligned 0 time"].split(" ")[1])) / all_seqs
            # now extract the reads unique aligned
            hi_dict["Unique_aligned"]=(int(dict_res["Aligned 1 time"].split(" ")[1])) / all_seqs
            # The reads multimaped
            hi_dict["Multimaped"]=(int(dict_res["Aligned >1 times"].split(" ")[1])) / all_seqs
            # finally the time it taked
            hi_dict["Time(min)"]=(int(hi_met_df["Time"].iloc[0]) / 1e6) / 60
    #add the total of seqs
    hi_dict["Total_reads"]= all_seqs
    # finally we add the result to the hisat_df
    return pd.DataFrame.from_dict([hi_dict])


def parse_star(dict_res:dict) -> pd.DataFrame:
    """
    Function that parse the star log files 
    Args:
        -dict_res: a dictionary with the results of the star log file
    Returns:     
        -dataframe with the parsed results
    """
    str_dict = {} 
    # extract all the sequences:
    all_seqs = int(dict_res["Number of input reads "])
    # extract the overall aligned
    str_dict["Total_aligned"]=(
            int(dict_res["Uniquely mapped reads number "])
            + int(dict_res["Number of reads mapped to multiple loci "])
            + int(dict_res["Number of reads mapped to too many loci "])
        )/ all_seqs

    # now we store sequences that were not aligned
    str_dict["Non_aligned"]=(
                int(dict_res["Number of reads unmapped: too short "])
                + int(dict_res["Number of reads unmapped: too many mismatches "])
                + int(dict_res["Number of reads unmapped: other "])
            )/ all_seqs
    # now extract the reads unique aligned
    str_dict["Unique_aligned"]=int(dict_res["Uniquely mapped reads number "]) / all_seqs

    # The reads multimaped
    str_dict["Multimaped"]=(
                int(dict_res["Number of reads mapped to multiple loci "])
                + int(dict_res["Number of reads mapped to too many loci "])
        )/ all_seqs
    
    # finally the time it taked
    start_list = dict_res["Started mapping on "].split(" ")[2].split(":")
    finish_list = dict_res["Finished on "].split(" ")[2].split(":")
    start_time = (
        int(start_list[0]) * 3600 + int(start_list[1]) * 60 + int(start_list[2])
    )
    finish_time = (
        int(finish_list[0]) * 3600 + int(finish_list[1]) * 60 + int(finish_list[2])
    )
    str_dict["Time(min)"]=(finish_time - start_time) / 60
    #add the total of seqs 
    str_dict["Total_reads"]=all_seqs
    # finally we add the result to the star_df
    return pd.DataFrame.from_dict([str_dict])



def parser(): 
    """
    function that parse the arguments for the script
     -s or --SRR: the SRR number of the sample to be parsed
     -p or --path: the path to the folder where the alignment results are stored
     Returns:
        -the arguments parsed
    """
    parser = ap.ArgumentParser(description="Parse the alignment results")
    parser.add_argument(
        "-s",
        "--SRR",
        type=str,
        help="the SRR number of the sample to be parsed",
        required=True,
    )
    parser.add_argument(
        "-p",
        "--path",
        type=str,
        help="the path to the folder where the alignment results are stored",
        required=True,
    )
    parser.add_argument(
        "-o",
        "--out", 
        type=str,
        help="the path to the folder where the parsed results will be stored",
        required=False,
        default=None
    )
    return parser.parse_args()



def main():
    # get the arguments
    args = parser()
    SRR = args.SRR
    path = args.path
    save_path = args.out
    # get the paths for the hisat and star results
    hisat_PR = os.path.join(path, SRR + "_PR.txt")
    star_PR = os.path.join(path, SRR + "_strPRLog.final.out")
    hisat_UN = os.path.join(path, SRR + "_UN.txt")
    star_UN = os.path.join(path, SRR + "_strUNLog.final.out")

    # make a dictionary with the paths provieded
    path_dic = {
        "hisatPR": hisat_PR,
        "starPR": star_PR,
        "hisatUN": hisat_UN,
        "starUN": star_UN,
    }


    #dataframes
    columns=["SRR_id","Total_aligned", "Non_aligned", "Unique_aligned", "Multimaped", "Time(min)", "Total_reads", "Type", "aligner"]
    parsed_df = pd.DataFrame(pd.DataFrame(columns=columns))

    for align_res in path_dic.keys():
        try:  
            with open(path_dic[align_res], "r") as read_f:
                raw_file=read_f.read().split("\n")
        except Exception as e:
            parsed_df=pd.concat([parsed_df, pd.DataFrame(columns=columns, data=[[SRR]+[None]*8])])
            continue

        #obtain the tyope of the read 
        type_read=align_res[len(align_res)-2::]
        #parsed in order of the aligner 
        if "hisat" in align_res:
            dict_res = dict([line.strip().split(":") for line in raw_file if ":" in line])
            met_path=path_dic[align_res].replace(".txt", "_met.txt")
            temp_df = parse_hisat(dict_res,met_path, type_read)
            temp_df["aligner"]=["hisat"]
        else:
            temp_list = [line.strip().split("|") for line in raw_file if "|" in line]
            # clean the list
            dict_res = dict([[lis[0], lis[1].strip()] for lis in temp_list if len(lis) == 2])  
            temp_df = parse_star(dict_res)
            temp_df["aligner"]=["star"]

        #add the identfier columns 
        temp_df["Type"]=[type_read]
        temp_df["SRR_id"]=[SRR]
        # add the temp_df to the parsed_df
        parsed_df=pd.concat([parsed_df,temp_df])

    # finally we can save the dataframes
    if not save_path:
        save_path = os.path.join(path, "parsed_results")
    #verify if the folder exists if not create it
    os.makedirs(save_path,exist_ok=True)
    # save the dataframes
    parsed_df.to_csv(os.path.join(save_path, SRR + "_parsed.csv"), index=False)

if __name__ == "__main__":
    main()