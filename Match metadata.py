import os
import pandas as pd
import shutil

dir_path = r"analysis_folder" 
map_path = r"mappingfile.xlsx"

os.chdir(dir_path)
os.makedirs("Group_files", exist_ok=True)
os.makedirs("Checked_Files", exist_ok=True)
os.chdir("Checked_Files")
dir_path1= os.getcwd()

#Convert windows address to linux address, for wsl only
def convert_path(path):
    path = path.replace("\\", "/")  # Convert backslash to forward slash
    drive, tail = os.path.splitdrive(path)
    if drive:
        path = "/mnt/" + drive[:-1].lower() + tail  # Convert drive letter
    return path

# match"_1" and" _2" files
def pair_files(files):
    paired_files = {}
    for file in files:
        try:
            # Extract the unique identifier from the filename, assuming the format 'BT<...>_[1/2].'
            parts = file.split('_')
            if len(parts) < 2:
                print(f"Warning: Underscore not found in file {file}")
                continue
            identifier, read_part = parts[-2], parts[-1]
            if not (read_part.startswith("1.") or read_part.startswith("2.")):
                print(f"Warning: File {file} does not end with '_1.' or '_2.'")
                continue
            paired_key = '_'.join(parts[:-1])  # Create a key without the read number
            read_number = read_part.split('.')[0]  # '1' or '2'
            if paired_key not in paired_files:
                paired_files[paired_key] = {}
            if read_number == '1':     
                paired_files[paired_key]['forward'] = convert_path(file)
            elif read_number == '2':
                paired_files[paired_key]['reverse'] = convert_path(file)
        except Exception as e:
            print(f"Error processing file {file}: {e}")
    return paired_files

# Prompt user for directory path


# Get all file paths within the directory
file_list = [os.path.join(dp, f) for dp, dn, filenames in os.walk(dir_path1) for f in filenames]
file_list = [convert_path(file) for file in file_list]

# Pair the files
paired_files = pair_files(file_list)

# Load the sample mapping DataFrame from Excel
mapping_df = pd.read_excel(map_path, usecols=['filename', 'sampleid'])
mapping_dict = mapping_df.set_index('filename')['sampleid'].to_dict()

# Create the DataFrame
df_data = []
for idx, (key, paths) in enumerate(paired_files.items(), start=1):
    if 'forward' in paths and 'reverse' in paths:
        # Search for the filename in the key
        sample_id = 'Unknown'
        for filename in mapping_dict:
            if filename in key:
                sample_id = mapping_dict[filename]
                break

        row = {
            'sample-id': sample_id,
            'forward-absolute-filepath': paths.get('forward', ''),
            'reverse-absolute-filepath': paths.get('reverse', '')
        }
        df_data.append(row)
    else:
        print(f"Warning: Missing pair for {key}")

df = pd.DataFrame(df_data)

output_filename = "paired_file_paths.txt"
output_file_path = os.path.join(dir_path, output_filename)  # Join the output filename with the directory path

# Write the DataFrame to a UTF-8 encoded text file in the specified directory
df.to_csv(output_file_path, sep='\t', index=False, encoding='utf-8')

# Display the DataFrame
print(df)
print(f"The import data file has been written to {output_file_path}")

###Star group file processing###
# Read the whole mapping Excel file
mapping_df = pd.read_excel(map_path, index_col=None)# Ensuring that the first column is not used as an index

# Iterate over the columns starting from the third one
for column in mapping_df.columns[2:]:
    # Create a new DataFrame for each column
    data = []

    # Iterate over the rows of the column
    for index, value in mapping_df[column].items():
        # Check if the value is not "N/A"
        if not pd.isna(value):
           # Add the value of the first column and the current value to the new DataFrame
           data.append({'sampleid': mapping_df.loc[index, "sampleid"], 'Group': value})
    # Save the new DataFrame to a text file named after the column
    new_df = pd.DataFrame(data)
    output_file_path = os.path.join(dir_path, 'Group_files', f'{column}.txt')
    new_df.to_csv(output_file_path, sep='\t', index=False)

print("Group file processing completed.")