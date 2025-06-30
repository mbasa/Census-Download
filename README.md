# E-Stat Census Download 

<img width="1307" alt="Screenshot 2025-06-18 at 0 31 54" src="https://github.com/user-attachments/assets/d7597cba-ea5a-4529-83f7-0c5cc6bfc642" />

### To Download

* run `bash download.sh`

The download.sh will create a zip and txt directories and populate the zip directory with data 
downloaded from the E-Stat site. The script will then uncompress the files into the txt directory
and modify the text files in order to facilitate database import. 

### To Import into PostgreSQL/PostGIS
* create a database with PostGIS extension installed.
* edit import.sh and modify the DB_NAME variable to the created database name
* run `bash import.sh`

The import.sh script will create a mesh4 table and import the text data into that table. Afterwards,
a mesh polygon will be generated and saved in the geometry column of the table based on the
***mesh id*** of the record. Finally, indices will be created on the table. 
