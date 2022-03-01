# ISC3_HIT_review
STATA code to support analysis and synthesis of data from the ISC3 HIT scoping review.

***************************************

copyright 2022 Jinying Chen, iDAPT Cancer Control Center & UMass Chan Medical School

Licensed under the MIT License (the "License");
you may not use this file except in compliance with the License.

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
 
***************************************

To run the code, please put the accompanied ado file table1v3.ado in your personal ado directory like C:\ado\personal
 
1. Setting input data directory

 replace [[input dir]] in the definition of the global macro datadir in the file analyze_HIT_scoping_review_data.do
 (around line 43) by the directory that holds the input files (in xlsx format)

2. Updating input data files

  replace the file and worksheet names for lines starting with "import excel" in each program 

3. Program running order

(1) table_1_2

(2) gen_data_for_table3

(3) gen_data_for_table6

(4) other programs

