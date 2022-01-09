import os
from os import listdir
from os.path import isfile, join

def iog_to_txt(input_iog,output_txt):
    # prebuilt: Linux x86_64
    os.system(f"./iog_to_txt {input_iog} > {output_txt}")

if __name__ == '__main__':
    iog_path="/lustre/home/acct-phyww/phyww-inpac2/jc/cls_3pt/Data_demo_232/"
    txt_path="/lustre/home/acct-phyww/phyww-inpac2/jc/cls_3pt/txt_demo_232/"

    file_paths=[os.path.join(path, name) for path, subdirs, files in os.walk(iog_path) for name in files]
    file_names=[name for path, subdirs, files in os.walk(iog_path) for name in files]

    iog_paths = [fi for fi in file_paths if os.path.splitext(fi)[1]=='.iog']
    iog_files = [os.path.splitext(fi)[0] for fi in file_names if os.path.splitext(fi)[1]=='.iog']

    for id in range(len(iog_files)):
        input_iog = iog_paths[id]
        output_txt = txt_path+f'{iog_files[id]}.txt'
        iog_to_txt(input_iog, output_txt)
        




